# Confirmación de correo con Firebase

Plazo: **27/10/2026 08:00 America/Mexico_City (14:00 UTC)**. Seguimiento: [issue #5](https://github.com/Eileeno56/pet/issues/5).

**Publicada el 27/10/2026 a las 07:52:47 America/Mexico_City**, con APK y checksum en [Release beta.3](https://github.com/Eileeno56/pet/releases/tag/v1.0.0-beta.3). Recepción real, confirmación y acceso verificados; ver [evidencias](ENTREGAS.md).

## Decisión y costo

La propietaria eligió el enlace de verificación de Firebase Authentication para conservar Spark, sin activar Blaze. La alternativa anterior de cinco dígitos con Cloud Functions fue retirada antes de desplegarse. No se necesita un servidor propio, SMTP, contraseña de aplicación de Gmail ni secretos de envío.

Firebase permite correos de verificación en Spark dentro de sus [límites oficiales](https://firebase.google.com/docs/auth/limits). El envío de verificación de dirección es distinto del inicio de sesión sin contraseña por enlace; la app mantiene correo/contraseña o Google.

## Flujo de la app

1. Registrarse con nombre válido, correo y contraseña nueva de 8–128 caracteres con mayúscula, minúscula, número y símbolo (beta.4). Las contraseñas antiguas conservan acceso; las cuentas que todavía no verificaron el correo también deben confirmarlo.
2. La app muestra «Confirma tu correo» y bloquea Inicio, Historial, Perfil, cuidados y administración. El documento mínimo de cuenta puede crearse/leerse por su dueño, pero no se permiten datos de mascotas o cuidados.
3. Pulsar «Enviar enlace de confirmación». Firebase lo envía al correo de la cuenta autenticada, sin aceptar un destinatario arbitrario de un formulario. El mensaje usa la configuración del proyecto Firebase, no la contraseña personal de Gmail. Revisar spam.
4. Abrir el enlace del mensaje y regresar a la app. Pulsar «Ya confirmé mi correo». La app también comprueba al volver al primer plano; renueva los claims y recarga al usuario antes de abrir sus datos.
5. Si no se confirmó, se mantiene bloqueada. Se puede reenviar después de 60 segundos, con límites adicionales de Firebase, o salir para usar otra dirección. Los enlaces caducados o ya utilizados se gestionan en la página de Firebase; solicitar uno nuevo si es necesario.

Google puede informar que un correo ya fue verificado: en ese caso no se exige otra confirmación. No se marca un correo como confirmado desde el cliente ni se añaden excepciones por nombre/dominio.

Confirmar el enlace demuestra que se puede recibir mensajes en esa dirección. No prueba el nombre real ni impide buzones temporales; no se afirma identificar cualquier dato personal inventado.

## Seguridad y comprobación

Las reglas requieren `email_verified` para usar mascotas, horarios, registros médicos, alimento y cuidado familiar, incluyendo accesos administrativos. La política de longitud de contraseñas nuevas está activada en Firebase: una prueba REST real con seis caracteres fue rechazada con `PASSWORD_DOES_NOT_MEET_REQUIREMENTS` el 27/10/2026.

Pruebas Flutter: rutas protegidas y suscripciones bloqueadas, envío al usuario autenticado, espera de reenvío, error si el correo sigue pendiente y renovación de claims. Las pruebas de reglas verifican denegación a cuentas sin correo confirmado y acceso normal a las verificadas.

La prueba de recepción real debe realizarse con un correo controlado por la propietaria: recibir mensaje, pulsar enlace y confirmar que Firebase devuelve `emailVerified: true`. Las fechas, pruebas, CI, commit, build, firma y hash del APK se registran en [ENTREGAS.md](ENTREGAS.md) y en el issue. No atribuir a los testers aprobación de una versión que aún no revisaron.

## Despliegue

Usar `firebase deploy --config firebase.deploy.json --project petreminder-user-2026 --only firestore:rules` después de probar el flujo y preparar el APK. No se despliegan funciones ni se habilita facturación. Publicar el APK y comprobarlo, registrar fechas reales y mantener el seguimiento abierto si falta recepción real, pruebas o revisión de testers.
