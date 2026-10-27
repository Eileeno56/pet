# Revisión para la evaluación docente

Estado comprobado el 27/10/2026, America/Mexico_City. Seguimiento: [issue #5](https://github.com/Eileeno56/pet/issues/5).

| Requisito | Evidencia | Estado |
| --- | --- | --- |
| Cinco o más commits | [Historial real](https://github.com/Eileeno56/pet/commits/main), 11 commits antes de esta revisión | Cumplido |
| Varias ramas | `main`, `fix/profile-pets-admin` y `codex/tester-feedback-beta2` publicadas; conservan trabajo real | Publicadas |
| Pull requests | Esta guía se incorpora mediante PR; las correcciones anteriores se integraron directamente en main, sin PR histórico | Flujo de PR iniciado en esta entrega |
| Tags | `v1.0.0-beta.1` y `v1.0.0-beta.2` | Publicados |
| Releases | [Versiones del código](https://github.com/Eileeno56/pet/releases) y [distribución Android](https://github.com/Eileeno56/app_pet/releases) | Consultar cada versión y sus archivos |
| Tres reportes de testers | [Carpetas de opiniones](../opiniones/README.md): Iker y Juan José entregaron; Abraham pendiente | Incompleto |
| Correcciones | [Observación y cambio](MEJORAS_BETA2.md), [pruebas y publicación](ENTREGAS.md), [issue #4](https://github.com/Eileeno56/pet/issues/4) | Validación técnica aprobada de beta.2; revalidación humana pendiente |
| Correo confirmado | Beta.2 comprueba credenciales; el enlace de Firebase y bloqueo obligatorio se preparan para beta.3, conservando Spark | Activación pendiente en issue #5 |
| Contraseñas | Registro: 15–128 caracteres y rechazo de ciertos patrones; acceso de cuentas antiguas conservado. Política de longitud activada en Firebase el 27/10/2026; prueba REST de contraseña de seis caracteres rechazada | Servidor y cliente verificados para registros nuevos |

## Revalidación que deben entregar los testers

Cada participante debe probar el APK nuevo, indicar versión/dispositivo/fecha, repetir los casos observados y adjuntar el resultado real. No basta con que exista su carpeta o con que las pruebas automáticas pasen. Las copias de reportes de beta.1 conservan su contenido, incluso el encabezado antiguo de estado pendiente; se enlazan a los originales para comprobar su procedencia.

| Participante | Reporte beta.1 | Revalidación beta.2 o posterior |
| --- | --- | --- |
| Iker / IKLEN10 | Recibido con observaciones | Pendiente del tester |
| Juan José / juanse-create | Recibido con observaciones | Pendiente del tester |
| Abraham / cr7-ssa | Pendiente | Pendiente del tester |

No se inventan opiniones, aprobaciones, fechas anteriores ni pull requests retroactivos. La entrega del 26/10/2026 corresponde a beta.2; la confirmación obligatoria de correo es una entrega nueva; la propietaria eligió enlace de Firebase para mantener Spark.
