# Contraseñas y nombres de mascotas — beta.4

Seguimiento: [issue #9](https://github.com/Eileeno56/pet/issues/9). Plazo solicitado: 27/10/2026, 10:40 America/Mexico_City. La publicación se registra con su hora real en ENTREGAS.md; no se declara cumplimiento del plazo si se publicó después.

## Cambios

El registro acepta de 8 a 128 caracteres y exige mayúscula, minúscula, número y símbolo. El cliente rechaza además algunos patrones comunes y repeticiones simples. Firebase aplica el rango y la composición a los registros nuevos; se conserva el acceso con contraseñas de cuentas anteriores. Sigue siendo obligatorio confirmar el correo mediante el enlace de Firebase; se mantiene Spark.

El círculo rojo «Poco seguro» indica que no se cumplen los requisitos. El amarillo «Seguro» indica una contraseña válida. El verde «Muy seguro» requiere además al menos 12 caracteres y 8 caracteres distintos. Son categorías orientativas; no garantizan que una contraseña sea invulnerable. El texto y la etiqueta accesible permiten entender el indicador sin depender del color.

Crear o renombrar una mascota reserva su nombre mediante una transacción Firestore dentro del mismo espacio de cuidado. `Max`, `MAX` y ` Max ` representan el mismo nombre. Otro espacio puede usarlo. Los acentos se conservan. Al borrar o renombrar se libera la reserva. Las reglas impiden omitir o apropiarse de la reserva; dos creaciones simultáneas del mismo nombre no pueden aprobarse ambas. Guardar requiere conexión.

La migración conserva las mascotas anteriores, fotos, horarios e historial. Se detectó un grupo duplicado anterior: no se renombra ni elimina información personal automáticamente. Sus registros se conservan y no se puede añadir otro con ese nombre; al editar uno hay que elegir un nombre distinto. Esta limitación histórica se informa en la entrega.

Las versiones antiguas deben actualizarse al APK beta.4 para crear, renombrar o borrar mascotas con las reglas nuevas.

## Prueba manual

1. En registro, escribir menos de 8 caracteres o una contraseña sin alguna de las cuatro categorías: debe verse rojo y no permitir crear la cuenta.
2. Usar una contraseña única de 8–11 caracteres con las cuatro categorías: amarillo. Usar al menos 12 caracteres con 8 distintos: verde. No reutilizar los ejemplos de pruebas como contraseña real.
3. Registrar un correo controlado, confirmar el enlace recibido y entrar. Antes de confirmar, los datos deben permanecer bloqueados.
4. Crear una mascota; intentar crear otra con el mismo nombre cambiando mayúsculas o espacios externos: debe rechazarse. Intentar renombrar otra con ese nombre: también debe rechazarse.
5. Editar una mascota sin cambiar su nombre único: debe guardar. Renombrarla y comprobar que el nombre anterior queda disponible. Borrarla y comprobar que el nombre queda disponible.
6. En un espacio compartido, intentar simultáneamente desde dos dispositivos el mismo nombre: solo debe guardarse uno. En otro espacio independiente se permite repetirlo.

La validación técnica no sustituye la revalidación de los tres testers.

## Despliegue

Después de las pruebas de reglas, ejecutar `scripts/migrate-pet-names.ps1` para revisar los conteos; con `-Apply`, crear las reservas y añadir `nameKey` usando precondiciones de versión, sin reemplazar los demás campos. Requiere la sesión propietaria de Firebase CLI y nunca imprime credenciales ni nombres. No ejecutarlo sobre versiones futuras sin revisar el estado concurrente. Desplegar después las reglas con `firebase.deploy.json` y verificar la política de Firebase Authentication. No se activa facturación.
