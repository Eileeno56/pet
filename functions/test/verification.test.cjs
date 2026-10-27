'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createVerificationService } = require('../verification.cjs');

function setup() {
  const records = new Map();
  let time = 1_800_000_000_000;
  let code = '01234';
  const users = new Map([
    ['u', { email: 'owner@example.com', emailVerified: false }],
    ['v', { email: 'other@example.com', emailVerified: false }],
  ]);
  let failMail = false;
  let failNextUpdate = false;
  const sent = [];
  const db = { doc: path => path, runTransaction: async action => {
    const writes = [];
    const result = await action({ get: async path => ({ data: () => records.get(path) }),
      set: (path, value, opts) => writes.push([path, opts?.merge ? { ...records.get(path), ...value } : value]) });
    writes.forEach(([path, value]) => records.set(path, value));
    return result;
  } };
  const service = createVerificationService({ db,
    auth: { getUser: async uid => users.get(uid), updateUser: async (uid, change) => {
      if (failNextUpdate) { failNextUpdate = false; throw Error('Temporary Admin Auth failure'); }
      return Object.assign(users.get(uid), change);
    } },
    mail: async message => { if (failMail) throw Error('SMTP secret error'); sent.push(message); },
    secret: 'test-only-private-secret-0123456789', now: () => time, generateCode: () => code });
  return { ...service, records, users, sent, tick: ms => time += ms,
    code: value => code = value, failMail: () => failMail = true,
    failNextUpdate: () => failNextUpdate = true };
}
const rejects = (promise, code) => assert.rejects(promise, error => error.code === code);

test('sends only to authenticated account; code with leading zero is hashed and not returned', async () => {
  const s = setup();
  await rejects(s.send(null, 'ip'), 'unauthenticated');
  const result = await s.send('u', 'ip');
  assert.equal(s.sent[0].to, 'owner@example.com');
  assert.equal(s.sent[0].code, '01234');
  assert.equal(JSON.stringify(result).includes('01234'), false);
  assert.equal(JSON.stringify([...s.records]).includes('01234'), false);
  await s.verify('u', '01234');
  assert.equal(s.users.get('u').emailVerified, true);
  assert.equal(s.records.get('emailVerificationPrivate/u').hash, null);
});
test('wrong guesses persist even when caller receives error; locks after five', async () => {
  const s = setup(); await s.send('u', 'ip');
  for (let n = 0; n < 5; n++) await rejects(s.verify('u', '99999'), 'invalid-argument');
  assert.equal(s.records.get('emailVerificationPrivate/u').attempts, 5);
  await rejects(s.verify('u', '01234'), 'resource-exhausted');
  assert.equal(s.users.get('u').emailVerified, false);
});
test('expired and malformed codes cannot verify a mailbox', async () => {
  const s = setup(); await s.send('u', 'ip');
  await rejects(s.verify('u', '1234'), 'invalid-argument');
  await rejects(s.verify('u', '12x34'), 'invalid-argument');
  s.tick(600_000);
  await rejects(s.verify('u', '01234'), 'failed-precondition');
});
test('resend invalidates the previous code and requires sixty seconds', async () => {
  const s = setup(); await s.send('u', 'ip');
  await rejects(s.send('u', 'ip'), 'resource-exhausted');
  s.tick(60_000); s.code('56789'); await s.send('u', 'ip');
  await rejects(s.verify('u', '01234'), 'invalid-argument');
  await s.verify('u', '56789');
  assert.equal(s.users.get('u').emailVerified, true);
});
test('code is bound to UID and the authoritative email', async () => {
  const s = setup(); await s.send('u', 'ip');
  await rejects(s.verify('v', '01234'), 'failed-precondition');
  s.users.get('u').email = 'changed@example.com';
  await rejects(s.verify('u', '01234'), 'failed-precondition');
});
test('failed SMTP never enables a code or exposes provider errors', async () => {
  const s = setup(); s.failMail();
  await assert.rejects(s.send('u', 'ip'), error => error.code === 'unavailable' && !error.message.includes('secret'));
  await rejects(s.verify('u', '01234'), 'failed-precondition');
});
test('resending cannot reset hourly wrong-guess budget', async () => {
  const s = setup();
  for (let batch = 0; batch < 2; batch++) {
    await s.send('u', 'ip');
    for (let n = 0; n < 5; n++) await rejects(s.verify('u', '99999'), 'invalid-argument');
    s.tick(60_000);
  }
  await rejects(s.send('u', 'ip'), 'resource-exhausted');
  s.tick(3_600_000); await s.send('u', 'ip');
});
test('rate limits bound sends per account, IP and service', async () => {
  const s = setup();
  for (let n = 0; n < 5; n++) { await s.send('u', 'ip'); s.tick(60_000); }
  await rejects(s.send('u', 'ip'), 'resource-exhausted');
  s.records.set('emailVerificationLimits/global', { sentDay: 100, sentDayStart: 1_800_000_000_000 });
  await rejects(s.send('v', 'another-ip'), 'resource-exhausted');
});
test('disabled account cannot send or verify; verified account sends no extra email', async () => {
  const s = setup(); s.users.get('u').disabled = true;
  await rejects(s.send('u', 'ip'), 'permission-denied');
  await rejects(s.verify('u', '01234'), 'permission-denied');
  s.users.get('v').emailVerified = true;
  assert.deepEqual(await s.send('v', 'ip'), { verified: true });
  assert.equal(s.sent.length, 0);
});
test('IP quota spans different authenticated accounts and account daily quota persists', async () => {
  const s = setup();
  for (let n = 0; n < 20; n++) {
    const uid = `ip-user-${n}`;
    s.users.set(uid, { email: `${uid}@example.com`, emailVerified: false });
    await s.send(uid, 'shared-ip');
  }
  await rejects(s.send('u', 'shared-ip'), 'resource-exhausted');
  const daily = setup();
  for (let n = 0; n < 10; n++) { await daily.send('u', 'ip'); daily.tick(3_600_000); }
  await rejects(daily.send('u', 'ip'), 'resource-exhausted');
});
test('a correct final attempt can retry a transient Auth failure without losing accepted proof', async () => {
  const s = setup(); await s.send('u', 'ip');
  for (let n = 0; n < 4; n++) await rejects(s.verify('u', '99999'), 'invalid-argument');
  s.failNextUpdate();
  await assert.rejects(s.verify('u', '01234'));
  assert.equal(s.records.get('emailVerificationPrivate/u').attempts, 5);
  assert.equal(s.users.get('u').emailVerified, false);
  await s.verify('u', '01234');
  assert.equal(s.users.get('u').emailVerified, true);
});
