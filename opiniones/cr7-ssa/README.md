> Copia de referencia del reporte de Abraham sobre beta.2. Original: https://github.com/Eileeno56/app_pet/blob/0608c10/opiniones/cr7-ssa/README.md
> Recibido en esta revisión el 27/10/2026; no representa revalidación de beta.3.

Opiniones de Abraham
- Usuario de GitHub: @cr7-ssa
- Participación: Tester.
- Fecha límite: 25 de octubre de 2026, 23:59 (hora de Ciudad de México, America/Mexico_City).
- Versión a evaluar: PetReminder 1.0.0-beta.1+2 para Android.

Reporte de opiniones
Estado: Completado

- Fecha de la prueba o revisión: 26 de octubre de 2026
- Dispositivo y versión de Android: POCO X6 Pro 5G / Android 14 (Xiaomi HyperOS)
- Versión de la aplicación: PetReminder 1.0.0-beta.2
- Funciones revisadas:
  * Inicio de sesión y autenticación (Registro con correo y contraseña, inicio de sesión mediante Google OAuth).
  * Gestión y filtrado de historial de comidas/alimentación por fechas y estados (Pendiente, Realizada).
  * Módulo "Cuidado en familia" (Envío de invitaciones a familiares por correo electrónico).
  * Configuración de notificaciones, recordatorios y alarmas del sistema.
- Pasos realizados:
  1. Navegación inicial por el panel de inicio y consulta de las comidas de la mascota "Firulais".
  2. Consulta de métricas y estadísticas en el apartado de Perfil.
  3. Prueba de filtros en el "Historial" seleccionando un rango de fechas en el calendario desplegable.
  4. Envío de invitación por correo en la sección de "Cuidado en familia".
  5. Configuración de permisos de notificaciones y alarmas exactas en el sistema Android, ejecutando la prueba de sonido/notificación.
  6. Cierre de sesión y prueba de registro manual con correo y contraseña extensa.
  7. Prueba de autenticación rápida y vinculación con cuenta de Google.
- Resultado esperado:
  * El filtro de fechas del historial debe actualizar en tiempo real los registros mostrados al seleccionar un periodo en el calendario.
  * El registro e inicio de sesión deben responder de manera fluida y con mensajes de error descriptivos.
  * La invitación por correo debe procesarse y agregarse a la lista de "Invitaciones enviadas".
  * Las notificaciones y alarmas de prueba deben sonar y mostrar la alerta correctamente.
- Resultado obtenido:
  * La vinculación e inicio de sesión con Google funciona de forma limpia e inmediata.
  * El envío de invitación a familiares se agrega correctamente a las invitaciones pendientes.
  * Las notificaciones y alarmas funcionan de manera adecuada al otorgar los permisos del sistema.
  * En la prueba de registro manual, se requiere una contraseña con una longitud mínima muy alta (15 caracteres).
  * Al intentar aplicar el filtro de rango de fechas en el Historial, el número de registros y la lista no parecen filtrarse/actualizarse de forma consistente tras seleccionar las fechas.
- Errores encontrados:
  1. **Filtro de fechas en Historial:** Al seleccionar un periodo específico mediante el calendario ("Elegir fechas"), el sistema no actualiza ni filtra correctamente los registros mostrados en la lista.
  2. **Validación de inicio de sesión manual:** Si se falla al ingresar la contraseña, el mensaje de error "No fue posible iniciar sesión. Revisa tus datos e inténtalo de nuevo" es genérico y no especifica el problema.
- Opinión sobre facilidad de uso y diseño:
  * La interfaz es visualmente atractiva, amigable y muy limpia gracias a la paleta de colores y el patrón de fondo con patas/corazones.
  * La navegación entre pestañas (Inicio, Historial, Perfil) es intuitiva y la configuración de notificaciones guía bien al usuario hacia los ajustes de Android.
- Sugerencias de mejora:
  * Flexibilizar el requisito de contraseña en el registro manual (reducir el mínimo de 15 caracteres o permitir combinaciones alfanuméricas estándar de 8-10 caracteres) para no frustrar al usuario.
  * Revisar la lógica del selector de fechas en el Historial para asegurar que la consulta a la base de datos local/remota responda al rango seleccionado.
  * Agregar un mensaje modal de confirmación antes de cerrar la sesión para evitar salidas accidentales.
- Resultado general: Satisfactorio
