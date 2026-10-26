import 'package:flutter/material.dart';

/// Fondo decorativo compartido. El velo claro mantiene el contraste del texto.
class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const Positioned.fill(
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFFFFCFA),
              image: DecorationImage(
                image: AssetImage('assets/backgrounds/paws_hearts.png'),
                repeat: ImageRepeat.repeat,
                scale: 1.6,
                opacity: 0.22,
              ),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}
