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
    if (value!.length < 8) return 'Usa al menos 8 caracteres.';
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value) ||
        !RegExp(r'[^A-Za-z0-9\s]').hasMatch(value)) {
      return 'Incluye mayúscula, minúscula, número y símbolo.';
    }
    final normalized = value.toLowerCase().replaceAll(
      RegExp(r'[0-9\s\W_]'),
      '',
    );
    if ([
          'password',
          'contrasea',
          'qwerty',
          'abcd',
          'petreminder',
        ].contains(normalized) ||
        RegExp(r'^(.{1,4})\1+$', dotAll: true).hasMatch(value)) {
      return 'Evita contraseñas comunes y secuencias repetidas.';
    }
    return null;
  }

  // Estimación visual: no sustituye la validación ni garantiza invulnerabilidad.
  static int passwordStrength(String value) => newPassword(value) != null
      ? 0
      : value.length >= 12 && value.runes.toSet().length >= 8
      ? 2
      : 1;

  static String petNameKey(String value) => value.trim().toLowerCase();

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
