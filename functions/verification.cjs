'use strict';
const { randomInt, randomUUID, createHmac, timingSafeEqual } = require('node:crypto');

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;
class VerificationError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
const fail = (code, message) => { throw new VerificationError(code, message); };
const digest = (secret, ...parts) => createHmac('sha256', secret).update(JSON.stringify(parts)).digest('hex');
function matches(left, right) {
  return typeof left === 'string' && left.length === right.length &&
    timingSafeEqual(Buffer.from(left), Buffer.from(right));
}
function windowCount(record, key, now, duration) {
  const start = record?.[`${key}Start`] ?? now;
  return now - start >= duration ? { start: now, count: 0 } : { start, count: record?.[key] ?? 0 };
}

// Only the Admin SDK can read/write these documents. Codes are never returned to clients.
function createVerificationService({ db, auth, mail, secret, now = Date.now,
  generateCode = () => String(randomInt(0, 100_000)).padStart(5, '0') }) {
  async function account(uid) {
    if (!uid) fail('unauthenticated', 'Inicia sesión para confirmar tu correo.');
    const user = await auth.getUser(uid);
    if (user.disabled || !user.email) fail('permission-denied', 'Esta cuenta no puede confirmar su correo.');
    return user;
  }
  async function send(uid, ip) {
    const user = await account(uid);
    if (user.emailVerified) return { verified: true };
    const time = now();
    const code = generateCode();
    const id = randomUUID();
    const reference = db.doc(`emailVerificationPrivate/${uid}`);
    const ipReference = db.doc(`emailVerificationLimits/${digest(secret, 'ip', ip || 'unknown')}`);
    const globalReference = db.doc('emailVerificationLimits/global');
    await db.runTransaction(async tx => {
      const [snapshot, ipSnapshot, globalSnapshot] = await Promise.all([
        tx.get(reference), tx.get(ipReference), tx.get(globalReference),
      ]);
      const prior = snapshot.data() || {};
      const hour = windowCount(prior, 'sentHour', time, HOUR);
      const day = windowCount(prior, 'sentDay', time, DAY);
      const attempts = windowCount(prior, 'attemptsHour', time, HOUR);
      const ipHour = windowCount(ipSnapshot.data(), 'sentHour', time, HOUR);
      const globalDay = windowCount(globalSnapshot.data(), 'sentDay', time, DAY);
      if ((prior.sentAt != null && time - prior.sentAt < MINUTE) || hour.count >= 5 ||
          day.count >= 10 || attempts.count >= 10 || ipHour.count >= 20 || globalDay.count >= 100) {
        fail('resource-exhausted', 'Se alcanzó el límite de envíos o intentos. Espera antes de reintentar.');
      }
      tx.set(reference, { email: user.email, challengeId: id,
        hash: digest(secret, uid, user.email, id, code), sentAt: time,
        expiresAt: time + 10 * MINUTE, status: 'sending', attempts: 0,
        attemptsHour: attempts.count, attemptsHourStart: attempts.start,
        sentHour: hour.count + 1, sentHourStart: hour.start,
        sentDay: day.count + 1, sentDayStart: day.start });
      tx.set(ipReference, { sentHour: ipHour.count + 1, sentHourStart: ipHour.start });
      tx.set(globalReference, { sentDay: globalDay.count + 1, sentDayStart: globalDay.start });
    });
    try {
      await mail({ to: user.email, code });
    } catch (_) {
      // No SMTP errors, credentials, recipients or plaintext codes in logs/responses.
      await db.runTransaction(async tx => {
        const snapshot = await tx.get(reference);
        if (snapshot.data()?.challengeId === id) tx.set(reference, { status: 'failed' }, { merge: true });
      });
      fail('unavailable', 'No fue posible enviar el código. Espera un minuto e inténtalo de nuevo.');
    }
    await db.runTransaction(async tx => {
      const snapshot = await tx.get(reference);
      if (snapshot.data()?.challengeId === id && snapshot.data()?.status === 'sending') {
        tx.set(reference, { status: 'sent' }, { merge: true });
      }
    });
    return { verified: false, expiresInSeconds: 600, resendAfterSeconds: 60 };
  }

  async function verify(uid, code) {
    const user = await account(uid);
    if (typeof code !== 'string' || !/^\d{5}$/.test(code)) {
      fail('invalid-argument', 'Escribe los 5 dígitos del código.');
    }
    if (user.emailVerified) return { verified: true };
    const time = now();
    const reference = db.doc(`emailVerificationPrivate/${uid}`);
    const accepted = await db.runTransaction(async tx => {
      const snapshot = await tx.get(reference);
      const data = snapshot.data();
      if (!data || data.email !== user.email || data.expiresAt <= time ||
          !['sent', 'verified-pending'].includes(data.status)) {
        fail('failed-precondition', 'El código venció o no está disponible. Solicita otro.');
      }
      const hour = windowCount(data, 'attemptsHour', time, HOUR);
      const valid = matches(data.hash, digest(secret, uid, user.email, data.challengeId, code));
      // A transient Admin Auth failure must not consume the proof already accepted.
      if (data.status === 'verified-pending' && valid) {
        return { valid: true, challengeId: data.challengeId };
      }
      if (data.attempts >= 5 || hour.count >= 10) {
        fail('resource-exhausted', 'Demasiados intentos. Espera antes de solicitar otro código.');
      }
      tx.set(reference, { attempts: data.attempts + 1,
        attemptsHour: hour.count + 1, attemptsHourStart: hour.start,
        ...(valid ? { status: 'verified-pending' } : {}) }, { merge: true });
      // Return errors AFTER commit so wrong attempts are not rolled back.
      return { valid, challengeId: data.challengeId };
    });
    if (!accepted.valid) fail('invalid-argument', 'El código no es correcto. Revisa tu correo.');
    const latest = await account(uid);
    if (latest.email !== user.email) fail('failed-precondition', 'Tu correo cambió. Solicita otro código.');
    // Bind the verified flag to the exact address whose ownership was proven.
    await auth.updateUser(uid, { email: user.email, emailVerified: true });
    await db.runTransaction(async tx => {
      const snapshot = await tx.get(reference);
      if (snapshot.data()?.challengeId === accepted.challengeId) {
        tx.set(reference, { status: 'consumed', hash: null }, { merge: true });
      }
    });
    return { verified: true };
  }
  return { send, verify };
}
module.exports = { createVerificationService, VerificationError };
