# Confirmación de correo con código

Solicitud del 27/10/2026. Plazo: **27/10/2026 08:00 America/Mexico_City (14:00 UTC)**. Seguimiento: [issue #5](https://github.com/Eileeno56/pet/issues/5).

## Estado

Implementación en preparación; no se presenta como servicio activo hasta desplegar y verificar el envío real. El APK público beta.2 no incluye este flujo. El servidor nuevo necesita Blaze y las credenciales de envío autorizadas por la propietaria. No se guarda una contraseña de Gmail en Git ni en el APK.

## Funcionamiento

1. La cuenta se crea en Firebase Authentication con una contraseña nueva de 15–128 caracteres. El mínimo y máximo también están activados en el servidor de Firebase; una prueba REST real con seis caracteres fue rechazada con `PASSWORD_DOES_NOT_MEET_REQUIREMENTS` el 27/10/2026. Las cuentas antiguas conservan sus contraseñas; no se forzó un cambio masivo al iniciar sesión. Hasta confirmar su correo no puede abrir las pantallas de mascotas, historial, perfil ni administración en la versión nueva.
2. «Enviar código» llama al servidor autenticado. El destinatario se obtiene de Firebase Auth, nunca de un correo arbitrario enviado por el cliente.
3. El servidor genera cinco dígitos con un generador criptográfico, incluidos ceros iniciales, y envía el código desde la cuenta Gmail configurada.
4. El código vence en 10 minutos. Se permiten cinco intentos por código y diez por hora por cuenta. Un reenvío requiere 60 segundos, invalida el anterior y no reinicia el límite horario de intentos.
5. Solo el servidor guarda el HMAC del código. Las colecciones privadas y los límites no tienen permisos para clientes. El código no se devuelve en la API ni se registra en logs.
6. Si coincide, el servidor confirma en Auth la dirección exacta que se probó. La app renueva los claims y recarga al usuario antes de abrir las suscripciones a datos.

Las reglas también requieren `email_verified` para operar con mascotas y cuidados, incluidos los accesos administrativos. El documento mínimo de cuenta puede crearse y leerse por su dueño antes de la confirmación; los datos de mascotas y cuidados permanecen bloqueados. Las cuentas anteriores sin correo verificado deben confirmarlo al instalar la nueva versión. Google solo permite pasar si Firebase informa que el correo ya está verificado.

Confirmar un código prueba que la persona puede recibir mensajes en esa dirección; no certifica su nombre real ni impide usar un buzón temporal. No se afirma poder identificar cualquier dato personal inventado.

## Configuración por la propietaria

1. Activar Blaze en `petreminder-user-2026`, revisando el uso y la facturación de Google Cloud. Esta activación no la realiza el código del proyecto.
2. En la cuenta Gmail remitente activar la verificación en dos pasos y crear una contraseña de aplicación. La contraseña habitual no se utiliza.
3. Ejecutar `powershell -NoProfile -ExecutionPolicy Bypass -File tools/configure-email-secrets.ps1` desde este repositorio. Introducir la contraseña de aplicación solo en el campo oculto de la CLI. El script guarda `GMAIL_APP_PASSWORD` y genera `EMAIL_CODE_HASH_KEY` directamente para Secret Manager. Volver a ejecutarlo rota la clave y deja inválidos los códigos anteriores.
4. Instalar dependencias con `npm ci --prefix functions`, ejecutar `npm --prefix functions run check` y `npm --prefix functions test`.
5. Desplegar primero el servidor: `firebase deploy --config firebase.deploy.json --project petreminder-user-2026 --only functions:email-verification`. No desplegar reglas que bloqueen cuentas antes de comprobar que el envío y el APK nuevo funcionan.
6. Probar con una cuenta de la propietaria: recepción real, código incorrecto, código correcto, actualización de claims y acceso. Desplegar las reglas verificadas con `--only firestore:rules` y publicar el APK nuevo. Mantener el issue abierto si falla o falta cualquier paso.

Los límites iniciales del servidor son cinco envíos/hora y diez/día por cuenta, veinte/hora por IP y cien/día globales; máximo dos instancias y tiempo de ejecución de 30 segundos. Reducen abuso, pero no son un tope de facturación. Firebase Authentication sigue controlando las credenciales y sus límites propios.

## Pruebas y entrega

La suite Node cubre destinatario vinculado a la cuenta, hash sin código expuesto, caducidad, reenvío, errores SMTP, intentos persistentes y límites. Las pruebas Flutter cubren bloqueo de rutas, validación de cinco dígitos, reenvío y renovación de tokens. El emulador de reglas comprueba denegación de acceso a cuentas sin verificar y a las colecciones privadas.

Registrar en el issue el resultado real de cada prueba, despliegue, commit, APK, checksum y fecha. La revalidación de los tres testers debe recibirse de ellos; no se sustituye con pruebas automáticas.
