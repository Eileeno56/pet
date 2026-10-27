# PetReminder User

Aplicación Flutter para Android orientada a organizar la alimentación de mascotas.

[Revisión de requisitos docentes](docs/REVISION_DOCENTE.md) · [Opiniones de testers](opiniones/README.md)

La app exige [confirmar el correo mediante un enlace de Firebase](docs/CONFIRMACION_CORREO.md), sin activar facturación.

## Estado de esta entrega

Código actualizado: **1.0.0-beta.4+5**. Registro desde 8 caracteres con mayúscula, minúscula, número y símbolo; indicador de seguridad; nombres de mascotas únicos por espacio de cuidado.
[Guía de cambios y pruebas beta.4](docs/MEJORAS_BETA4.md) · [Ramas y su función](docs/RAMAS.md).
Seguimiento: [issue #9](https://github.com/Eileeno56/pet/issues/9). El plazo solicitado fue el 27/10/2026 a las 10:40 America/Mexico_City; la publicación se registra con su fecha real en [ENTREGAS.md](docs/ENTREGAS.md). No se declara una entrega dentro de plazo.
La beta.3 anterior permanece disponible en [releases](https://github.com/Eileeno56/pet/releases/tag/v1.0.0-beta.3). El APK beta.4 aparecerá en su release tras verificar la compilación y publicación.

[Distribución Android](https://github.com/Eileeno56/pet/releases).
Este repositorio contiene el código, tags, releases e instalador Android. `Eileeno56/app_pet` conserva el historial de distribución y los reportes originales.
La nueva beta requiere una segunda evaluación de los testers; no se declara estable.

Repositorio: https://github.com/Eileeno56/pet.
Consultar [pruebas beta](docs/PRUEBAS_BETA.md), [entregas](docs/ENTREGAS.md)
y [cambios](CHANGELOG.md).

### Requisitos

- Flutter 3.44.6 / Dart 3.12.2 utilizados para compilar y validar esta beta.
- Android 7.0 (API 24) o superior; APK universal para ARM y x86_64.
- Android SDK y JDK 17; el proyecto utiliza Gradle 9.1 y Android Gradle Plugin 9.0.1.
- El módulo `petreminder_admin/` está incluido como dependencia local dentro
  de este repositorio. Sus pantallas también se abren dentro de la app Android.
- Generar para un proyecto Firebase propio la configuración Android y Dart
  con FlutterFire (`flutterfire configure --platforms=android`), manteniendo
  `com.petreminder.petreminder_user` como applicationId. Los archivos locales
  `lib/firebase_options.dart`, `android/app/google-services.json`,
  `firebase.json` y `.firebaserc` están excluidos de Git. No publicar cuentas
  de servicio ni claves privadas. Configurar Authentication y proveedores
  de correo/Google, y revisar reglas e índices antes de desplegar.
- `android/local.properties` debe apuntar al SDK y Flutter de la computadora
  actual; el archivo recibido conserva rutas de otra computadora y no se publica.

La CI analiza y prueba ambos módulos y la política de cierre de comentarios de la ronda histórica beta.1.
Para esas pruebas genera configuración Firebase ficticia, sin conectar a
producción. El build Android usa la configuración local real, excluida de Git.
Consultar los resultados reales de esta entrega en `docs/ENTREGAS.md`.

### Mascotas y validación

Solo hay un botón «Agregar mascota» en Inicio. Cada especie conocida ofrece
al menos ocho razas o variedades, «Mestizo / Sin raza» y «Otro». Esta última
opción permite escribir una variedad; la especie «Otro» permite escribir
también la especie. La edad se captura en años y meses, y se muestra en ambos
módulos sin perder los documentos antiguos, que se leen con cero meses.

| Campo | Rango permitido |
| --- | --- |
| Nombre de usuario o mascota | 2–60 caracteres; letras y espacios |
| Especie manual | 2–40 caracteres |
| Raza manual | 2–80 caracteres; opcional para especie manual |
| Descripción | 0–500 caracteres |
| Meses adicionales | 0–11 |
| Contraseña de registro nueva | 8–128 caracteres; mayúscula, minúscula, número y símbolo |
| Edad total de Perro / Gato | 0–30 años |
| Conejo / Ave / Hámster | 0–20 / 0–100 / 0–5 años |
| Tortuga / Pez / Otro | 0–200 / 0–100 / 0–250 años |

El máximo incluye los meses: 30 años y 1 mes no es válido para Gato. Son
límites de registro de la aplicación, no estimaciones de esperanza de vida.
Los límites también se validan en Firestore. Al borrar una mascota o un
horario se eliminan sus registros de alimentación; historial y estadísticas
excluyen registros huérfanos de versiones anteriores.

## Versionado y continuación

`main` es la rama de integración. Antes de integrar cambios, ejecutar las
comprobaciones correspondientes y revisar el diff. Esta primera línea base
permanece en beta mientras se completa la evaluación de los tres testers.
Utilizar ramas temporales `feat/...`, `fix/...`, `docs/...`, `test/...` o
`chore/...`, con Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`,
`chore:`) y actualizar el changelog.

```powershell
git switch main
git pull --ff-only origin main
git switch -c feat/siguiente-mejora
# Editar, revisar y validar antes del commit
git diff
flutter pub get
flutter analyze
flutter test
node --test .github/scripts/lock-beta.test.cjs
git add <archivos-revisados>
git commit -m "feat: describir la mejora"
git push -u origin feat/siguiente-mejora
```

Integrar la rama revisada mediante pull request o merge local comprobado,
y eliminarla cuando esté integrada. Aplicar SemVer; los siguientes candidatos
serían `1.0.0-beta.2+3`, etc. Crear tags preliminares solo sobre commits
comprobados y enviados. No crear `v1.0.0` estable hasta validar la aplicación.
Las Releases preliminares con APK y SHA-256 corresponden a la distribución
separada en `Eieen56/app_pet`. No reemplazar artefactos ya distribuidos.

## Comandos básicos

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

## Firebase

El proyecto Android está conectado a `petreminder-user-2026` y utiliza:

- Firebase Authentication para correo/contraseña y Google Sign-In.
- Cloud Firestore para usuarios, mascotas, horarios e historial.
- Reglas por propietario en `firestore.rules`.
- Deteccion del Custom Claim `admin: true` para abrir el modulo administrativo
  dentro de la misma aplicacion Android.

Las fotografías de mascotas y perfil se guardan únicamente en el almacenamiento
privado de la aplicación en el teléfono. Firebase Storage no se utiliza y
`storage.rules` deniega todas las operaciones.

Para desplegar las reglas de Firestore:

```powershell
firebase deploy --only firestore:rules --project petreminder-user-2026
```

El panel administrativo se comparte desde `petreminder_admin/`. Tras iniciar
sesion, GoRouter envia las cuentas con el Custom Claim booleano `admin: true` a
`/admin/dashboard`; las cuentas normales permanecen en el flujo de mascotas.
El cliente movil no puede asignar ese claim ni modificar `accountStatus` sin
los permisos administrativos validados por Firestore.

No se concede acceso por comparar un usuario o una contraseña en el cliente.
Se conservan las cuentas existentes en Firebase; no hay contraseñas
administrativas almacenadas en este repositorio. El alias histórico `eileno`
se conserva por compatibilidad, pero no acredita que esa cuenta siga vigente.

## Notificaciones Android

La aplicación solicita permiso para notificaciones y alarmas exactas. Cada
horario activo genera dos recordatorios locales diarios: cinco minutos antes y
a la hora indicada. Android puede volver a pedir el permiso de alarmas exactas
después de reinstalar la aplicación. Se normalizan las zonas GMT/UTC y sus
desfases para evitar errores durante el arranque.

## Compilación

```powershell
flutter build apk --release
```

El APK resultante se genera en
`build/app/outputs/flutter-apk/app-release.apk`.

Esta beta utiliza la firma de depuración configurada en el proyecto. Consultar
la guía beta antes de actualizar una instalación con una firma diferente.
