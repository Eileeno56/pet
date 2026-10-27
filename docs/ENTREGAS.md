# Registro de entregas

## Actualización beta.3 — 27 de octubre de 2026

Plazo: **27/10/2026 08:00 America/Mexico_City (14:00 UTC)**. [Seguimiento #5](https://github.com/Eileeno56/pet/issues/5).

| Elemento | Evidencia | Estado |
| --- | --- | --- |
| Código y tag | Main `7ea71427cb606e354f4f5de7360b8e7281b81514`; tag `v1.0.0-beta.3`; [PR #7](https://github.com/Eileeno56/pet/pull/7) integrado | Publicados |
| Ramas y revisión docente | Ramas de trabajo reales publicadas; [PR #6](https://github.com/Eileeno56/pet/pull/6) integrado; reportes de referencia en opiniones/ | Publicados en pet |
| Pruebas | 51 pruebas Flutter y análisis sin incidencias; CI ejecuta también 2 pruebas admin y 8 de política beta | Aprobadas |
| CI del código | [40513111436](https://github.com/Eileeno56/pet/actions/runs/40513111436), head funcional `f9383badbcbf28729ba6ffb340ec9cca7ec9c02e` | Success |
| Contraseñas nuevas | Política Firebase 15–128; prueba REST con seis caracteres rechazada | Verificada; cuentas antiguas conservan acceso |
| Correo real | Firebase aceptó envío; propietaria recibió y pulsó enlace; consulta Auth con emailVerified=true a las 07:35:13; claim renovado email_verified=true | Confirmado sin SMTP propio |
| Reglas | Compiladas y desplegadas en petreminder-user-2026; pruebas de reglas en emulador aprobadas | Desplegadas |
| Prueba real de acceso | 07:52:18: token previo sin verificación HTTP 403; token renovado verificado HTTP 200 sobre la misma mascota temporal | Aprobada |
| Limpieza | Documentos y cuenta temporal de Auth eliminados; tokens locales protegidos eliminados | Completada |
| Plan | Spark; billingEnabled=false comprobado; Cloud Functions/SMTP retirados antes de desplegarse | Sin activar Blaze |
| APK | 1.0.0-beta.3, versionCode 4, API 24–36; build release universal correcto; 63,941,801 bytes | Compilado |
| Firma | SHA-256 certificado d523fbae118f34d7b9c46064635c37d0354d21d55792e8f76836fe936b3cf57e, compatible con beta.2 | Verificada |
| SHA-256 APK | b8433fefc3b358994ca9d7117c4f8c759264dce4620fa71df3846e4685abf804 | Digest remoto comprobado |
| Publicación | [Release beta.3 en pet](https://github.com/Eileeno56/pet/releases/tag/v1.0.0-beta.3), 27/10/2026 07:52:47 UTC−06:00 (13:52:47 UTC); API pública y descarga HTTP 200 | Entregada antes de las 08:00 |
| Evaluación humana | Iker y Juan José reportaron beta.1; falta Abraham y la revalidación de las versiones corregidas | Seguimiento abierto |

**Entrega técnica publicada a tiempo y pruebas aprobadas.** El issue/hito general permanece abierto por los reportes y revalidaciones humanas pendientes; no se atribuye aprobación a los testers. No se configuró una automatización.

La beta.3 se validó con tests Flutter, build, metadatos/firma del APK y una prueba real de correo/Auth/Firestore. No se afirma una nueva instalación ni una prueba completa en teléfonos físicos de beta.3; la evidencia de instalación de beta.2 se conserva abajo. Los certificados de confianza del sistema se usaron para resolver la descarga de dependencias, manteniendo TLS.

## Actualización beta.2 — 26 de octubre de 2026

**Plazo comprometido: 26/10/2026, 21:00, America/Mexico_City (UTC−06:00).**
Seguimiento: [issue #4](https://github.com/Eileeno56/pet/issues/4).

| Elemento | Evidencia real | Estado |
| --- | --- | --- |
| Código de las mejoras | Commit `dbc85b25059bff14edbcf2dcd93c6e3117a05ba4`, 26/10/2026 17:54:02 UTC−06:00; main remoto verificado | Publicado antes del plazo |
| Versión y tag | `1.0.0-beta.2+3`; tag de código `v1.0.0-beta.2` publicado | Completado |
| Análisis y pruebas locales | Análisis app/admin sin incidencias; 45 pruebas app, 2 admin, 8 política; 8 pruebas de mejoras repetidas tras el último ajuste de contraseñas | Aprobadas |
| CI del código | [Ejecución 40422869858](https://github.com/Eileeno56/pet/actions/runs/40422869858), concluida correctamente | Aprobada |
| Reglas Firestore | Pruebas en proyecto demo: acceso familiar, correo verificado, revocación, aislamiento de cuentas, plan, ficha médica e historial | Aprobadas en emulador |
| APK definitivo | 63,876,265 bytes; SHA-256 `756768e556b610011cb71883111b4edd5d29c8dd4ff616ce75b76a0f7461d3da`; digest del archivo subido a GitHub verificado | Publicado; digest verificado |
| Instalación y actualización | Instalación de beta.1 y después beta.2 con `adb install -r`, ambas con resultado `Success`; Android reconoce versionCode 3 y versionName 1.0.0-beta.2 | Comprobada en Android 16 |
| Firma | Certificado SHA-256 `d523fbae118f34d7b9c46064635c37d0354d21d55792e8f76836fe936b3cf57e`, igual al APK beta.1 distribuido | Actualización compatible |
| Revisión visual del APK | [Captura del acceso](imagenes/beta2-login.png), texto centrado y fondo de patitas legible; sin errores fatales de Flutter/AndroidRuntime de la app en el registro capturado | Comprobada |
| Despliegue real de Firestore | `firebase deploy --project petreminder-user-2026 --only firestore:rules`: compilación, carga y liberación correctas el 26/10/2026; sesión renovada y certificados del sistema utilizados | Desplegado |
| Publicación pública del instalador | [Release beta.2](https://github.com/Eileeno56/app_pet/releases/tag/v1.0.0-beta.2), 26/10/2026 18:15:26 UTC−06:00 (27/10/2026 00:15:26 UTC); API pública sin autenticación, APK HTTP 200 y digest comprobados | Publicado antes del plazo |
| Cierre y aprobación de la entrega | Código, pruebas, despliegue y APK público verificados antes de las 21:00 | **Completada y aprobada técnicamente** |

El emulador presentó avisos de lentitud de Pixel Launcher y System UI durante el
arranque; después se comprobó la pantalla de la app. La instalación y la prueba
visual no certifican por sí solas todos los flujos en teléfonos reales. Los reportes
de Iker y Juan José corresponden a beta.1; no se les atribuye una aprobación de beta.2.

Documentación de distribución publicada en el commit `309f4d4d10ca8a3d8a577baf0a50b84a67b40133`, verificado en main remoto; su tag `v1.0.0-beta.2` apunta al mismo commit.

No se configuró una automatización. El cierre del issue y del hito se realiza manualmente después de comprobar la publicación. La aprobación técnica no sustituye la segunda evaluación de los testers.

## Registro histórico de beta.1


Zona horaria: `America/Mexico_City` (UTC−06:00 en estas fechas).
Fecha de preparación y validación del código de soporte beta: **20/10/2026**.
Fecha límite de feedback solicitada: **20/10/2026 a las 23:59:00**.
Inicio del bloqueo: **21/10/2026 a las 00:00:00**.

No se recibieron fechas históricas de entrega de funcionalidades. No se
atribuyen fechas anteriores ni se acredita retroalimentación no recibida.

| Elemento | Fecha prevista | Fecha real verificable | Estado |
| --- | --- | --- | --- |
| Código recibido y configuración de versionado beta | 20/10/2026 | 20/10/2026 18:58:57 UTC-06:00, push verificado | Entregado a tiempo en Eieen56/pet |
| Guía, formulario y política de cierre beta | 20/10/2026 | 20/10/2026 18:58:57 UTC-06:00, archivos publicados | Entregados a tiempo; validación de política local aprobada |
| Publicación del código en GitHub | 20/10/2026 | 20/10/2026 18:58:57 UTC-06:00, commit 1a7301a verificado en main | Entregado a tiempo |
| Correcciones de perfil, mascotas y módulo admin | 20/10/2026 | 20/10/2026, código y pruebas locales | Entregadas a tiempo en GitHub; 32 pruebas de app y 2 de admin aprobadas |
| Reglas de Firestore corregidas | 20/10/2026 | 20/10/2026, emulador y despliegue real | Desplegadas correctamente |
| Compilación Android | 20/10/2026 | 20/10/2026, build release e instalación del APK verificadas | Entregada a tiempo |
| Instalador / Release / SHA-256 | 20/10/2026, distribución en Eieen56/app_pet | 20/10/2026 20:20:11 UTC-06:00, Release pública verificada | Entregados a tiempo |
| Reporte Tester 1 | 20/10/2026 23:59:00 | No recibido | Pendiente; cuenta por confirmar |
| Reporte Tester 2 | 20/10/2026 23:59:00 | No recibido | Pendiente; cuenta por confirmar |
| Reporte Tester 3 | 20/10/2026 23:59:00 | No recibido | Pendiente; cuenta por confirmar |
| Bloqueo de los tres reportes | Desde 21/10/2026 00:00:00 | Sin ejecución real verificada | Configurado para los issues #1, #2 y #3; ejecución real después del corte pendiente |

Solo marcar «Entregado a tiempo» con un commit publicado verificable antes
de la fecha comprometida. Para feedback, usar el reporte real y su fecha; el
código preparado no acredita que los testers hayan probado la aplicación.

## Diagnóstico y evidencias

- La carpeta recibida no tenía `.git`, historial, ramas ni tags.
- El remoto público consultado no tenía refs; no se reemplazó historial previo.
- Aplicación Android Flutter con Riverpod, GoRouter, Firebase Auth/Firestore,
  fotografías privadas locales y recordatorios diarios.
- Las pruebas Flutter cubren validadores, modelos, sesiones, widgets de acceso
  y perfil, y resolución de zonas horarias.
- En la auditoría inicial faltaba `../petreminder_admin`. Posteriormente se
  incorporó `petreminder_admin/` dentro de este repositorio y se corrigió la
  ruta en `pubspec.yaml`; la resolución de dependencias ya funciona.
- `flutter test --concurrency=1`: 32 pruebas aprobadas en la app. Las dos
  pruebas del módulo admin también aprobaron. Cubren sesiones, carga del
  nombre, rutas administrativas, borrados, huérfanos, catálogos y validación.
- Emulador Firestore con proyecto demo: reglas aprobadas, incluyendo límites
  por especie, meses y protección contra registros de padres inexistentes.
- `firebase deploy --project petreminder-user-2026 --only firestore:rules`:
  compilación de reglas y despliegue completados correctamente el 20/10/2026.
- `node --test .github/scripts/lock-beta.test.cjs`: 8 pruebas aprobadas,
  0 fallos. Cubren corte temporal, simulación, selección, idempotencia,
  ejecución tardía y errores de API. No se bloquearon issues reales.
- El APK preexistente en `build/` no se distribuye ni se considera verificado.
- No había `.github` ni documentación de Releases en la carpeta original.
- Se conserva la arquitectura, reglas Firebase y fuentes; se excluyen carpetas
  generadas, configuración local, credenciales y binarios. No se añade licencia.
- Se conserva el lockfile y se declara la fuente de iconos requerida por la app.
  No se ha realizado una auditoría de vulnerabilidades de todas las dependencias.

## Validación y pendientes

- CI remota del código de ejecución `f6d98fb`: aprobada (32 app, 2 admin, 8 política beta).
- Build release, manifiesto, firma y SHA-256 verificados; Android mínimo API 24.
- Instalación del mismo APK y pantalla «Bienvenido» verificadas en emulador
  Android 16, zona GMT, sin excepciones fatales de la app. El emulador mostró
  avisos de lentitud del sistema y Google Play services por recursos del equipo;
  esta comprobación no certifica todos los flujos en teléfonos reales.
- Actions habilitado y simulación manual aprobada sin bloquear reportes.
- Pendiente: confirmar las cuentas de tres testers y recibir sus reportes reales.
- Pendiente: verificar el bloqueo programado después del corte; no se acredita
  una ejecución futura ni se marcan los reportes como recibidos.

Reportes preparados: https://github.com/Eieen56/pet/issues/1,
https://github.com/Eieen56/pet/issues/2 y https://github.com/Eieen56/pet/issues/3.
No hay testers asignados ni reportes acreditados como completados.

CI remota del código `f6d98fb`: aprobada en
https://github.com/Eieen56/pet/actions/runs/39530072343.
Simulación manual de cierre: aprobada en
https://github.com/Eieen56/pet/actions/runs/39524641369; workflow habilitado.

## Instalador entregado

[Release pública](https://github.com/Eieen56/app_pet/releases/tag/v1.0.0-beta.1) · [APK](https://github.com/Eieen56/app_pet/releases/download/v1.0.0-beta.1/PetReminder-1.0.0-beta.1.apk).
Publicado: **20/10/2026 20:20:11 UTC-06:00**. Código de ejecución: `f6d98fb73cf0c0bb91524465dd9c28e3d77732de`.
Los commits posteriores de esta entrega actualizan documentación y evidencias.

SHA-256: `bbd691d9c7e8ddf7437a4382e6d413ee362e7cba0720c0b02cececdb30890828`. Tamaño: 59,484,631 bytes.
Firma de depuración beta, diferente del APK recibido originalmente; consultar
la guía antes de desinstalar para conservar fotografías locales.
