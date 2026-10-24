import 'package:flutter/material.dart';

/// The shared brand artwork used throughout the app.
class AppLogo extends StatelessWidget {
  static const assetPath = 'assets/metimeclub_logo.png';

  final double size;

  const AppLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticLabel: 'Me Time Club logo',
      ),
    );
  }
}
