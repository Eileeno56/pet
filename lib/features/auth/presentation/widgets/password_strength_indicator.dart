import 'package:flutter/material.dart';
import 'package:petreminder_user/core/validators/input_validators.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final level = InputValidators.passwordStrength(password);
    final label = ['Poco seguro', 'Seguro', 'Muy seguro'][level];
    final color = [
      Colors.red.shade700,
      Colors.amber.shade700,
      Colors.green.shade700,
    ][level];
    return Semantics(
      liveRegion: true,
      label: 'Seguridad de la contraseña: $label',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Icon(Icons.circle, size: 14, color: color),
            const SizedBox(width: 8),
            Flexible(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
