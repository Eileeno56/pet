'use strict';
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');
const nodemailer = require('nodemailer');
const { createVerificationService, VerificationError } = require('./verification.cjs');
initializeApp();
const smtpPassword = defineSecret('GMAIL_APP_PASSWORD');
const hashKey = defineSecret('EMAIL_CODE_HASH_KEY');
const sender = defineString('VERIFICATION_SENDER', { default: 'eileen.nopal20@gmail.com' });
const options = { region: 'us-central1', maxInstances: 2, concurrency: 10,
  memory: '256MiB', timeoutSeconds: 30, secrets: [smtpPassword, hashKey] };
function service() {
  const smtp = nodemailer.createTransport({ host: 'smtp.gmail.com', port: 465, secure: true,
    connectionTimeout: 8000, greetingTimeout: 8000, socketTimeout: 10000,
    auth: { user: sender.value(), pass: smtpPassword.value().replace(/\s+/g, '') } });
  return createVerificationService({ db: getFirestore(), auth: getAuth(), secret: hashKey.value(),
    mail: async ({ to, code }) => {
      const result = await smtp.sendMail({ from: `PetReminder <${sender.value()}>`, to,
        subject: 'Confirma tu correo en PetReminder',
        text: `Tu código de confirmación de PetReminder es: ${code}\n\nVence en 10 minutos y solo puede utilizarse una vez. No compartas este código. Si no lo solicitaste, ignora este mensaje.` });
      if (!result.accepted?.includes(to)) throw new Error('Delivery rejected');
    } });
}
async function handle(operation) {
  try { return await operation(); }
  catch (error) {
    if (error instanceof VerificationError) throw new HttpsError(error.code, error.message);
    throw new HttpsError('unavailable', 'No fue posible completar la confirmación. Inténtalo de nuevo.');
  }
}
exports.sendEmailCode = onCall(options, request =>
  handle(() => service().send(request.auth?.uid, request.rawRequest.ip)));
exports.verifyEmailCode = onCall(options, request =>
  handle(() => service().verify(request.auth?.uid, request.data?.code)));
