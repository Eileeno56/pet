'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { createVerificationService } = require('../verification.cjs');

test('Firestore transaction serializes parallel sends and persists simultaneous wrong attempts', async () => {
  // Refuse to execute against production; this test uses fake mail and fake Auth only.
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Run inside Firestore emulator');
  const app = initializeApp({ projectId: 'demo-petreminder-tests' }, 'otp-integration');
  const db = getFirestore(app);
  const uid = `otp-integration-${Date.now()}`;
  const messages = [];
  const user = { email: 'test@example.com', emailVerified: false };
  const service = createVerificationService({ db,
    auth: { getUser: async () => user, updateUser: async (_, change) => Object.assign(user, change) },
    mail: async message => messages.push(message), secret: 'integration-only-test-secret',
    generateCode: () => '01234' });
  try {
    const sends = await Promise.allSettled(Array.from({ length: 4 }, () => service.send(uid, 'test-ip')));
    assert.equal(sends.filter(result => result.status === 'fulfilled').length, 1);
    assert.equal(messages.length, 1);
    await Promise.allSettled(Array.from({ length: 5 }, () => service.verify(uid, '99999')));
    const data = (await db.doc(`emailVerificationPrivate/${uid}`).get()).data();
    assert.equal(data.attempts, 5);
    await assert.rejects(service.verify(uid, '01234'), error => error.code === 'resource-exhausted');
    assert.equal(user.emailVerified, false);
  } finally {
    await db.doc(`emailVerificationPrivate/${uid}`).delete();
    await db.terminate(); await deleteApp(app);
  }
});
