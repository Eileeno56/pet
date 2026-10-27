> Copia de referencia del reporte beta.1. Original: https://github.com/Eileeno56/app_pet/blob/main/opiniones/IKLEN10/README.md
> No representa revalidación de la actualización.

# Opiniones de Iker

- **Usuario de GitHub:** [@IKLEN10](https://github.com/IKLEN10)
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

# Reporte de opiniones

**Estado:** Pendiente de completar por Iker.

- **Fecha de la prueba o revisión:** 22/10/2026
- **Dispositivo y versión de Android:** Samsung A52, Android 13
- **Versión de la aplicación:** PetReminder 1.0.0-beta.1+2

## Desglose de Pruebas por Módulo
  ### 1. Módulo: Autenticación y Registro (`Registro / Login`)
* **Funciones revisadas:** Creación de cuenta manual e Inicio de sesión con Google.
* **Pasos realizados:** 
1. Intentar registrar una cuenta ingresando números en el nombre (`Ooeekrrn444555`).
2. Ingresar una contraseña simple/débil (ej. solo letras y números simples como `eei3i3i3ii33` sin exigir mayúsculas, símbolos o reglas de complejidad).
  3. Editar el nombre de usuario desde el modal de Perfil (`Ooeekrrn44455577`).
  4. Probar el inicio de sesión directo mediante la integración con Google Account.
* **Resultado esperado:** 
  * El formulario debe exigir una contraseña fuerte (combinación de mayúsculas, minúsculas, números y caracteres especiales) e impedir números en el nombre.
  * El nombre debe solo aceptar letras y por lo menos una palabra.
  * La autenticación con Google debe completar el flujo de acceso correctamente.
* **Resultado obtenido:** 
  * Permite registrar usuarios con contraseñas débiles (solo pide un mínimo de 6 caracteres sin exigir complejidad) - `Error`.
  * Permite nombres con caracteres numéricos tanto en el registro como en la edición de perfil - `Error`.
  * La autenticación con Google funciona de manera fluida y exitosa.
<img width="auto" height="500" alt="image" src="https://github.com/user-attachments/assets/41512b20-54e5-47fc-86ee-5e464d0c911a" />

  ---
### 2. Módulo: Gestión de Mascotas (`Agregar / Editar Mascota`)
- **Funciones revisadas:** Formulario de registro y edición de mascotas, sanitización y validación de edad por especie, asignación de fotografía de perfil y campo de descripción.
- **Pasos realizados:**
1. Intentar registrar una mascota ingresando números y caracteres especiales en el campo de *Nombre* (ej. `984848diidken&`) y en la *Descripción*.
  2. Ingresar el valor `020` en el campo de *Edad en años* durante la creación de la mascota.
  3. Intentar guardar una edad de `100` años al editar la mascota.
  4. Cargar una fotografía desde la cámara o galería y guardar la información.
- **Resultado esperado:**
  - El campo de nombre debe validar la entrada para aceptar únicamente letras y espacios, bloqueando números o caracteres especiales.
  - La aplicación debe manejar correctamente los números enteros en la edad (eliminar ceros iniciales) y bloquear registros que superen el límite máximo por especie (máximo 30 años para gatos).
  - La imagen seleccionada de la cámara o galería debe guardarse y visualizarse correctamente en el perfil de la mascota.
- **Resultado obtenido:**
  - **Falta de sanitización de texto:** Permite ingresar y guardar números, símbolos y caracteres especiales en el campo de nombre (y texto sin filtro en la descripción)- `Error`.
  - **Manejo correcto de edad:** Sanitiza correctamente los enteros al convertir automáticamente `020` a `20` años, y bloquea el guardado cuando la edad sobrepasa el límite permitido (ej. `100` años).
  - **Renderizado de imagen:** La fotografía seleccionada se guarda y muestra adecuadamente en el perfil detallado de la mascota.
<img width="auto" height="500" alt="image" src="https://github.com/user-attachments/assets/8f7b0e6e-65b5-4582-9722-2e06c4b47ec2" />
<img width="auto" height="500" alt="image" src="https://github.com/user-attachments/assets/2fb44da1-1252-4d9b-9717-373d5fb59a91" />


---



### 3. Módulo: Perfil de Usuario (`Editar Nombre`)
- **Funciones revisadas:** Ventana modal de modificación del nombre de usuario desde la sección de Perfil.
- **Pasos realizados:**
1. Ir a la pestaña **Perfil** de la aplicación.
  2. Presionar el ícono/botón de edición sobre el nombre del usuario.
  3. En la ventana emergente *Editar nombre*, teclear una combinación de letras, números y repetitivos (ej. `Ooeekrrn44455577`).
  4. Presionar el botón **Guardar**.
- **Resultado esperado:**
  - El modal de edición debe contar con validaciones de entrada que restrinjan el campo a solo letras (alfabético), exigiendo un nombre válido antes de permitir guardar los cambios.
- **Resultado obtenido:**
  - **Falta de sanitización de texto:** La ventana modal acepta y guarda cadenas con números y caracteres especiales sin aplicar ningún tipo de filtro o restricción - `Error`.
<img width="auto" height="500" alt="image" src="https://github.com/user-attachments/assets/0b6b5267-7b1c-4e7b-9963-e913571cb4f0" />

  ---
### 4. Módulo: Recordatorios y Notificaciones (`Horarios de Alimentación`)
- **Funciones revisadas:** Creación y edición de horarios de comida, selector de hora (TimePicker), interruptor de estado (Switch), marcado de tarea realizada ("Ya comió") y envío de notificaciones push del sistema.
- **Pasos realizados:**
1. En el perfil de la mascota, presionar **Agregar horario**.
  2. Seleccionar la hora deseada en el reloj interactivo y guardar.
  3. Esperar al momento programado y verificar si el dispositivo emite la notificación push de Android.
  4. Presionar el botón **"Ya comió"** en la tarjeta del horario.
- **Resultado esperado:**
  - El selector de hora debe guardar el horario de manera precisa.
  - Al llegar el minuto exacto, la aplicación debe enviar una notificación nativa del sistema informando que es hora de alimentar a la mascota.
  - Al confirmar la acción ("Ya comió"), el estado debe actualizarse visiblemente a *"Alimentada"*.
- **Resultado obtenido:**
  - El selector de hora programa el evento sin fallos.
  - La app emite la alerta del sistema a tiempo con la estructura adecuada.
  - La interfaz actualiza correctamente la etiqueta a *"Alimentada"* al confirmar la comida.
<img width="auto" height="500" alt="image" src="https://github.com/user-attachments/assets/36d13bcd-c60f-4f72-95f8-c491a77dc5c3" />
<img width="auto" height="500" alt="image" src="https://github.com/user-attachments/assets/794fb940-ba9e-4d73-9043-71717a67a9f5" />
<img width="auto" height="500" alt="image" src="https://github.com/user-attachments/assets/40897f18-6efb-492b-92bf-e34b68e8601e" />

---

### 5. Módulo: Pantalla Principal, Historial y Métricas (`Inicio / Historial / Perfil`)
- **Funciones revisadas:** Resumen de mascotas en Inicio, listado de eventos en Historial y contadores de métricas de alimentación en Perfil.
- **Pasos realizados:**
1. Revisar las tarjetas de las mascotas en la pestaña **Inicio** para verificar el estado de la próxima comida y fotografías.
  2. Confirmar un horario de comida ("Ya comió") y navegar a la pestaña **Historial**.
  3. Consultar las métricas de *"Esta semana"* y *"Por mascota"* en la pestaña **Perfil**.
- **Resultado esperado:**
  - La pantalla principal debe listar correctamente cada mascota con su foto/avatar, estado de la próxima comida y estado actual.
  - La sección Historial debe registrar la hora programada y la hora exacta en la que se confirmó la acción.
  - Las estadísticas del Perfil deben incrementar y sincronizar en tiempo real los contadores (Programadas, Realizadas, Pendientes y desglose por mascota).
- **Resultado obtenido:**
  - La tarjeta de Inicio actualiza dinámicamente el horario de próxima comida y el estado.
  - El módulo registra con exactitud la bitácora de alimentación del día (*"Hoy"*) indicando la mascota y hora exacta de confirmación.
  - El panel de Perfil actualiza los contadores semanales y el avance por mascota.
<img width="auto" height="500" alt="image" src="https://github.com/user-attachments/assets/eb8a534f-6100-414d-9a80-27d01219c53f" />
<img width="auto" height="500" alt="image" src="https://github.com/user-attachments/assets/a02d0cd4-5fd3-4c4d-978c-013ace8d4804" />
<img width="auto" height="500" alt="WhatsApp Image 2026-10-23 at 1 51 09 AM" src="https://github.com/user-attachments/assets/455d62a0-5867-4534-b9cf-efa4e59f13db" />


---


- **Opinión sobre facilidad de uso y diseño:** 
La aplicación es muy fácil de usar y se ve moderna. Funciona excelente para lo importante: avisa a tiempo las horas de comida y guarda bien el historial y las estadísticas. Su único detalle está en los formularios, ya que deja escribir números y símbolos donde solo deberían ir nombres.

- **Sugerencias de mejora:**
1. Implementar un módulo para registrar y llevar el control diario del alimento que consume la mascota, permitiendo calcular la porción ideal según su especie, peso y edad, e indicando si cumplió con su meta diaria de alimentación.
  2. Agregar una sección para gestionar historial médico.
  3. Agregar la opción de vincular a otro miembro de la familia mediante código QR o correo para que ambos reciban las notificaciones y puedan marcar cuando la mascota ya comió.

- **Resultado general:** Con errores

