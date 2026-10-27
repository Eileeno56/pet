> Copia de referencia del reporte beta.1. Original: https://github.com/Eileeno56/app_pet/blob/main/opiniones/juanse-create/README.md
> No representa revalidación de la actualización.

# Opiniones de Juan José

- **Usuario de GitHub:** [@juanse-create](https://github.com/juanse-create)
- **Participación:** Tester.
- **Fecha límite:** 25 de octubre de 2026, 23:59 (hora de Ciudad de México, America/Mexico_City).
- **Versión a evaluar:** PetReminder 1.0.0-beta.1+2 para Android.

## Cómo subir tus opiniones

1. Acepta la invitación de colaboración del repositorio, si está pendiente.
2. Entra en tu carpeta y abre este README.md en GitHub.
3. Pulsa el lápiz para editarlo y completa el reporte de abajo. También puedes añadir archivos Markdown o evidencias en esta misma carpeta.
4. Guarda con «Commit changes». Si GitHub solicita una rama, abre un pull request para integrar tus opiniones.
5. Entrega tus comentarios antes de la fecha límite. Edita únicamente tu reporte y conserva las opiniones de las otras personas.

La fecha es un plazo de entrega; no bloquea automáticamente las ediciones del repositorio.
No publiques contraseñas, credenciales ni datos personales. Oculta esa información en las capturas.

## Reporte de opiniones

**Estado:** Pendiente de completar por Juan José.

- **Fecha de la prueba o revisión:**
- **Dispositivo y versión de Android:**
- **Versión de la aplicación:**
- **Funciones revisadas:**
- **Pasos realizados:**
- **Resultado esperado:**
- **Resultado obtenido:**
- **Errores encontrados:**
- **Opinión sobre facilidad de uso y diseño:**
- **Sugerencias de mejora:**
- **Resultado general:** Satisfactorio / Con errores / No pude instalar o ejecutar.
- **Evidencias:** Enlaces o nombres de archivos dentro de esta carpeta.



### Sugerencia — Mejorar la seguridad de las contraseñas

**Caso:** TC-005 — Registro de usuario

**Resultado:** El registro funciona correctamente y permite acceder a la pantalla principal.

**Observación:** Durante el registro se identificó una validación de seis caracteres para la contraseña, sin otros requisitos visibles de seguridad.

**Sugerencias:**
- Permitir contraseñas largas, idealmente de al menos 15 caracteres.
- Evitar contraseñas demasiado comunes o fáciles de adivinar.
- Mostrar claramente los requisitos de contraseña.
- Permitir el uso de frases de contraseña, símbolos, números y mayúsculas sin imponer combinaciones innecesarias.


### Bug — Carga indefinida al iniciar sesión con un correo no registrado

**Caso de prueba:** TC-008  
**Módulo:** Autenticación  

**Pasos para reproducir:**
1. Abrir PetReminder.
2. Acceder a la pantalla de inicio de sesión.
3. Introducir un correo electrónico que no esté registrado.
4. Escribir una contraseña de prueba.
5. Presionar «Iniciar sesión».

**Resultado esperado:** La aplicación debe rechazar el acceso y mostrar un mensaje indicando que no fue posible iniciar sesión.

**Resultado obtenido:** La aplicación permanece cargando indefinidamente y no muestra una respuesta clara.

**Sugerencias:**
- Manejar los errores de autenticación correctamente.
- Detener el indicador de carga cuando falle el inicio de sesión.
- Mostrar un mensaje comprensible al usuario.
- Implementar un tiempo de espera para evitar cargas indefinidas.



### Mejora — Agregar más opciones a los horarios de alimentación

**Caso de prueba:** TC-015  
**Módulo:** Horarios  

**Observación:** Al agregar un horario para una mascota, la aplicación únicamente permite seleccionar la hora. No existen campos visibles para indicar el nombre, tipo de alimentación o frecuencia.

**Sugerencia:** Incorporar opciones para configurar:
- Nombre del horario: desayuno, comida o cena.
- Tipo de actividad: alimentación u otro recordatorio, si corresponde al alcance de la aplicación.
- Frecuencia: diariamente o días específicos.
- Descripción opcional del horario.

Incidencia funcional prioritaria
BUG-001 — Inicio de sesión con correo no registrado (TC-008)
- Prioridad sugerida: Media.
- Precondición: Estar en la pantalla de inicio de sesión.
- Pasos para reproducir:
  1. Introducir una dirección de correo que no esté registrada.
  2. Escribir una contraseña cualquiera.
  3. Pulsar el botón para iniciar sesión.
- Resultado esperado: La aplicación debe finalizar la solicitud y mostrar un mensaje comprensible, sin revelar innecesariamente si existe una cuenta.
- Resultado real: Se mantiene el indicador de carga indefinidamente y no se informa al usuario.
- Impacto: El usuario no sabe si debe esperar, corregir los datos o reintentar.
- Recomendación: Controlar errores y tiempos de espera de autenticación, detener el indicador de carga y mostrar una respuesta genérica como «No fue posible iniciar sesión. Revisa tus datos e inténtalo de nuevo».
4. Observaciones y sugerencias
1. Contraseñas (TC-005): Evaluar una política de contraseñas más robusta, por ejemplo, longitud suficiente y detección de contraseñas comunes, sin depender únicamente de exigir símbolos o mayúsculas.
2. Validación de edad (TC-012): Limitar o validar el rango durante la escritura y no solo al guardar; se observó un máximo de 30 años.
3. Horarios (TC-015): Considerar etiquetas, tipo de comida y frecuencia si forman parte del alcance del proyecto; actualmente se observó un selector de hora.
4. Historial (TC-019): Mejorar la información disponible con fecha, estado realizado/pendiente y filtros cuando sea pertinente.
5. Estadísticas (TC-020): Añadir porcentajes o visualizaciones sencillas como mejora opcional; los contadores actuales resultaron coherentes.
6. Sin conexión (TC-022): Informar claramente cuando una acción requiera Internet. La aplicación recuperó su funcionamiento al regresar la conectividad.
7. Notificaciones (TC-025): Revisar sonido, importancia del canal y preferencias del dispositivo. La ausencia de sonido o encendido de pantalla no demuestra por sí sola un defecto de la app.
8. Interfaz (TC-030): Mejorar claridad visual y facilidad de descubrimiento de funciones, manteniendo la navegación estable que se observó.
Pendiente de verificar (TC-018): Ubicación o disponibilidad del registro manual de comidas. No se clasifica como error confirmado.
5. Opinión general del tester
PetReminder ofrece una base funcional para administrar mascotas y sus horarios de alimentación. Durante las pruebas, el registro, la edición y eliminación de mascotas, la gestión de recordatorios y la conservación de datos funcionaron satisfactoriamente. También fue posible recibir notificaciones a la hora prevista y reprogramarlas sin duplicaciones en el escenario evaluado.

El principal problema encontrado está en el inicio de sesión con un correo no registrado, porque la pantalla permanece cargando sin explicación. Considero importante corregirlo antes de una versión estable. Además, sería útil mejorar los mensajes de conectividad, ampliar la información del historial y hacer más clara la interfaz de algunas funciones.

En general, la aplicación es funcional en los escenarios probados, con un defecto de autenticación pendiente y varias oportunidades de mejora en experiencia de usuario.
