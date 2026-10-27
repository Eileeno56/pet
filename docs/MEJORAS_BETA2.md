# PetReminder 1.0.0-beta.2+3 — mejoras de la evaluación

Entrega solicitada para el **26 de octubre de 2026, 21:00, America/Mexico_City**.
Seguimiento: https://github.com/Eileeno56/pet/issues/4.

## Cambios y relación con los reportes

| Observación | Cambio en esta beta |
| --- | --- |
| Juan José TC-008: el acceso con correo no registrado queda cargando | Tiempo máximo para autenticación, permisos y consulta de cuenta; error genérico, fin de la carga y posibilidad de reintentar. La verificación de sesión ofrece recuperación después de 20 segundos. |
| Iker y Juan José: contraseñas nuevas demasiado simples | Registro con 15–128 caracteres, frases de contraseña y rechazo de algunos patrones comunes. No se exige una combinación arbitraria de símbolos. Las cuentas anteriores pueden seguir entrando. La validación del cliente no sustituye la política de Firebase Authentication. |
| Iker: nombres de usuario y mascota aceptan números/símbolos | Validación de letras y espacios, incluidos acentos, en registro, edición de perfil y mascotas, repositorios y reglas de Firestore. Los nombres antiguos no impiden editar otros datos. La descripción conserva puntuación y números porque es texto libre. |
| Juan José TC-012: edad durante la captura | Mensajes al escribir y comprobación cruzada de años/meses; límites por especie conservados y verificados en Firestore. |
| Capturas de la usuaria: texto descentrado | Encabezado de acceso, título y mensajes vacíos centrados; formularios desplazables, ancho máximo y tamaños adaptables. |
| Fondo solicitado | Se usa la cuarta imagen proporcionada (corazones y patitas), con baja opacidad. Formularios y contenido principal sobre superficies claras y texto oscuro. Aparece también en las pantallas del módulo administrativo integrado. |
| Juan José TC-015: horarios más completos | Nombre, tipo de alimento, descripción y selección de días de la semana. Lectura compatible con horarios antiguos, que siguen siendo diarios. Avisos semanales cinco minutos antes y a la hora de la comida; se cancelan los avisos antiguos al sincronizar. |
| Juan José TC-018: no encontraba registro manual | Acceso explícito en el detalle de cada mascota y en Alimento. Cantidad consumida y alimento; sin necesidad de crear un horario. |
| Juan José TC-019/020: historial y estadísticas | Filtros de mascota, estado y rango de fechas; fecha, hora de confirmación, cantidad y origen manual. Porcentaje de comidas programadas realizadas en los últimos siete días; las comidas manuales se cuentan por separado. |
| Iker: control diario del alimento | Plan con alimento, peso, cantidad diaria indicada y comidas por día. Divide esa cantidad por comida y compara los gramos consumidos con la meta. La app no prescribe una dieta ni calcula una porción clínica solo por especie/edad/peso; se registra la cantidad indicada para esa mascota. |
| Iker: historial médico | Ficha con consultas, vacunas, desparasitación, tratamientos y otros cuidados. Título, fecha, notas y próxima fecha; permite editar y eliminar registros. La próxima fecha es informativa, no genera otra alarma. |
| Iker: cuidado con familiares | Invitación dentro de la app por correo, aceptación con correo verificado, selección del espacio y revocación por el propietario. Los cuidadores pueden gestionar las mascotas, horarios, alimento, comidas y ficha médica del espacio autorizado. No acceden al perfil privado ni a la administración de la cuenta. |
| Juan José TC-022: mensajes de conectividad | Indicaciones al mostrar datos de caché o cambios pendientes y tiempos de espera en operaciones. Los mensajes de fallos de escritura indican consultar antes de reintentar porque Firebase puede sincronizar una escritura pendiente al volver la conexión. |
| Juan José TC-025: sonido y avisos | Canal nuevo con sonido y vibración, acceso a ajustes Android y aviso de prueba en Perfil. El teléfono controla No molestar, volumen, ahorro de batería y la precisión permitida. |

## Cómo probar la actualización

1. Instalar el nuevo APK desde la Release beta. No sustituye ni modifica el APK de beta.1.
2. Entrar con una cuenta de prueba; un correo incorrecto debe terminar con un mensaje, sin revelar si existe.
3. Registrar una cuenta nueva con una frase de al menos 15 caracteres. Probar nombres con números y edades fuera del límite.
4. Agregar un horario con nombre y días concretos. Comprobar que el día no seleccionado no aparece como comida pendiente de hoy ni emite un aviso.
5. Abrir una mascota → Alimento y ficha médica. Configurar la cantidad diaria indicada, registrar una comida y comprobar los gramos de hoy.
6. Crear y editar un registro médico. Consultar Historial y probar los filtros.
7. Abrir Perfil → Cuidado en familia. Crear una invitación por el correo exacto de otra cuenta de prueba. La otra persona verifica su correo, abre la misma sección y acepta. No se envía un correo automático de invitación: se muestra dentro de la app.
8. Ambos seleccionan el mismo espacio para consultar las mismas mascotas y programar los avisos locales en sus teléfonos. La sincronización de cambios de otro cuidador requiere abrir la app con conexión. No hay notificaciones remotas push de cambios mientras está cerrada ni sincronización de las fotos privadas de otro teléfono.
9. Revocar el acceso; la otra cuenta debe perder acceso al espacio compartido. Cada teléfono conserva su propio control de permisos de Android.
10. Abrir Perfil → Notificaciones y sonido para enviar un aviso de prueba y revisar los ajustes.

## Validación de entrega

Se registrarán en el issue la revisión de código, los resultados de análisis/pruebas,
el despliegue de reglas, la compilación e instalación, el SHA-256, el commit remoto
y la fecha real de publicación. No se atribuye a los testers una aprobación nueva
hasta que vuelvan a evaluar este APK. La aprobación técnica de la entrega requiere
completar las comprobaciones y verificar que se publicó antes del plazo.


[Ver el nuevo acceso en el APK Android](imagenes/beta2-login.png).

Estado real de publicación y activación: [registro de entregas](ENTREGAS.md).
