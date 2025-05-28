// lib/widgets/gradient_button.dart
import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final List<Color>? gradientColors;
  final bool enabled;

  const GradientButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.gradientColors,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [const Color(0xFF00B68F), const Color(0xFF1DB0E9)];

    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onPressed : null,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: colors,
            ),
            boxShadow: enabled
                ? [
              BoxShadow(
                color: colors.first.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}