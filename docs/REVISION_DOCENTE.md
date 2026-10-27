# Revisión para la evaluación docente

Estado comprobado el 27/10/2026, America/Mexico_City. Seguimiento: [issue #5](https://github.com/Eileeno56/pet/issues/5).

| Requisito | Evidencia | Estado |
| --- | --- | --- |
| Cinco o más commits | [Historial real](https://github.com/Eileeno56/pet/commits/main), 11 commits antes de esta revisión | Cumplido |
| Varias ramas | Seis ramas publicadas; función y nombre de cada una en [RAMAS.md](RAMAS.md) | Publicadas |
| Pull requests | Esta guía se incorpora mediante PR; las correcciones anteriores se integraron directamente en main, sin PR histórico | PR #6, #7 y #10 integrados con CI aprobada |
| Tags | `v1.0.0-beta.1`, `v1.0.0-beta.2`, `v1.0.0-beta.3` y `v1.0.0-beta.4` | Publicados |
| Releases | [Versiones del código](https://github.com/Eileeno56/pet/releases) y [distribución Android](https://github.com/Eileeno56/app_pet/releases) | Consultar cada versión y sus archivos |
| Tres reportes de testers | [Carpetas de opiniones](../opiniones/README.md): Iker y Juan José entregaron beta.1; Abraham entregó beta.2 | Tres reportes recibidos |
| Correcciones | [Observación y cambio](MEJORAS_BETA2.md), [pruebas y publicación](ENTREGAS.md), [issue #4](https://github.com/Eileeno56/pet/issues/4) | Validación técnica aprobada de beta.2; revalidación humana pendiente |
| Correo confirmado | Beta.2 comprueba credenciales; beta.3 exige el enlace de Firebase y bloquea datos hasta confirmar, conservando Spark | Publicado y probado en issue #5; HTTP 403 sin claim verificado y 200 con sesión renovada |
| Contraseñas | Registro beta.4: 8–128 caracteres con mayúscula, minúscula, número y símbolo; acceso de cuentas antiguas conservado. Firebase rechazó siete contraseñas que incumplían la política y aceptó ocho caracteres con composición. Detalles en issue #9 | Servidor y cliente verificados para registros nuevos |

## Revalidación que deben entregar los testers

Cada participante debe probar el APK nuevo, indicar versión/dispositivo/fecha, repetir los casos observados y adjuntar el resultado real. No basta con que exista su carpeta o con que las pruebas automáticas pasen. Las copias de reportes de beta.1 conservan su contenido, incluso el encabezado antiguo de estado pendiente; se enlazan a los originales para comprobar su procedencia.

| Participante | Reporte recibido | Revalidación beta.2 o posterior |
| --- | --- | --- |
| Iker / IKLEN10 | Recibido con observaciones | Pendiente del tester |
| Juan José / juanse-create | Recibido con observaciones | Pendiente del tester |
| Abraham / cr7-ssa | Reporte recibido sobre beta.2 | Beta.3 pendiente; observaciones nuevas de historial y cierre de sesión por revisar |

No se inventan opiniones, aprobaciones, fechas anteriores ni pull requests retroactivos. La entrega del 26/10/2026 corresponde a beta.2; la confirmación obligatoria de correo es una entrega nueva; la propietaria eligió enlace de Firebase para mantener Spark.

Guía de las ramas actuales: [RAMAS.md](RAMAS.md). La última actualización se sigue en el [issue #9](https://github.com/Eileeno56/pet/issues/9); consultar la publicación y pendientes en ENTREGAS.md.
