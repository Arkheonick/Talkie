import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class MicButton extends StatelessWidget {
  final bool isListening;
  final bool isProcessing;
  final VoidCallback onTap;

  const MicButton({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening
              ? const Color(0xFFEF4444)
              : isProcessing
                  ? AppTheme.border
                  : AppTheme.primary,
          boxShadow: isListening
              ? [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  )
                ]
              : isProcessing
                  ? []
                  : [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ],
        ),
        child: isProcessing
            ? const Padding(
                padding: EdgeInsets.all(22),
                child: CircularProgressIndicator(
                  color: AppTheme.muted,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 32,
              ),
      ),
    );
  }
}
