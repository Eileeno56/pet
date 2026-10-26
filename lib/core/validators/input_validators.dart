import 'package:petreminder_user/core/auth/admin_credentials.dart';
import 'package:petreminder_user/core/pets/pet_catalog.dart';

abstract final class InputValidators {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _namePattern = RegExp(
    r'^[A-Za-zÀ-ÖØ-öø-ÿĀ-ž]+(?: [A-Za-zÀ-ÖØ-öø-ÿĀ-ž]+)*$',
  );

  static String? lettersInName(String value) =>
      _namePattern.hasMatch(value.trim())
      ? null
      : 'Usa solo letras y espacios, sin números ni símbolos.';

  static String? requiredName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu nombre.';
    }
    if (value.trim().length < 2) {
      return 'El nombre es demasiado corto.';
    }
    if (value.trim().length > 60) {
      return 'Usa un nombre de hasta 60 caracteres.';
    }
    return lettersInName(value);
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Ingresa tu correo.';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Ingresa un correo válido.';
    }
    if (email.length > 254) return 'Usa un correo de hasta 254 caracteres.';
    return null;
  }

  static String? emailOrAdminUsername(String? value) {
    final login = value?.trim() ?? '';
    if (login.isEmpty) {
      return 'Ingresa tu usuario o correo.';
    }
    if (AdminCredentials.isUsername(login) || _emailPattern.hasMatch(login)) {
      return login.length <= 254 ? null : 'Usa hasta 254 caracteres.';
    }
    return 'Ingresa un usuario o correo válido.';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña.';
    }
    if (value.length < 6) {
      return 'Usa al menos 6 caracteres.';
    }
    if (value.length > 128) return 'Usa como máximo 128 caracteres.';
    return null;
  }

  // La política nueva solo se aplica al registro. Las cuentas antiguas conservan acceso.
  static String? newPassword(String? value) {
    final basic = password(value);
    if (basic != null) return basic;
    if (value!.runes.length < 15) {
      return 'Usa al menos 15 caracteres; puedes escribir una frase.';
    }
    final compact = value.replaceAll(RegExp(r'\s'), '');
    if (compact.runes.length < 10 ||
        RegExp(r'^(.)\1+$', dotAll: true).hasMatch(compact)) {
      return 'Elige una frase con más contenido, sin rellenarla con espacios o caracteres repetidos.';
    }
    final normalized = value.toLowerCase().replaceAll(RegExp(r'[\s\W_]'), '');
    if (RegExp(r'^(.)\1+$').hasMatch(normalized) ||
        [
          '123456789012345',
          'passwordpassword',
          'contraseñacontraseña',
          'qwertyuiopasdfgh',
          'petreminderpetreminder',
        ].contains(normalized)) {
      return 'Elige una frase menos común y difícil de adivinar.';
    }
    return null;
  }

  static String? petName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Ingresa el nombre de la mascota.';
    }
    if (name.length < 2) {
      return 'El nombre es demasiado corto.';
    }
    if (name.length > 60) {
      return 'Usa un nombre de hasta 60 caracteres.';
    }
    return lettersInName(name);
  }

  static String? petAge(
    String? value, {
    String species = 'Otro',
    int months = 0,
  }) {
    final age = int.tryParse(value?.trim() ?? '');
    if (age == null) {
      return 'Ingresa la edad en años.';
    }
    final max = PetCatalog.maximumYears(species);
    if (age < 0 || age * 12 + months > max * 12) {
      return 'La edad máxima para $species es $max años.';
    }
    return null;
  }

  static String? petMonths(String? value) {
    final months = int.tryParse(value?.trim() ?? '');
    return months == null || months < 0 || months > 11
        ? 'Ingresa de 0 a 11 meses.'
        : null;
  }

  static String? petBreed(String? value) =>
      _boundedText(value, 'la raza o variedad', 2, 80);
  static String? customSpecies(String? value) =>
      _boundedText(value, 'la especie', 2, 40);
  static String? petDescription(String? value) =>
      (value?.trim().length ?? 0) > 500 ? 'Usa hasta 500 caracteres.' : null;

  static String? _boundedText(String? value, String field, int min, int max) {
    final text = value?.trim() ?? '';
    if (text.length < min || text.length > max) {
      return 'Escribe $field con $min a $max caracteres.';
    }
    return null;
  }
}
