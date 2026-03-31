import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class MessageBubble extends StatelessWidget {
  final String role;
  final String text;
  final bool isPartial;

  const MessageBubble({
    super.key,
    required this.role,
    required this.text,
    this.isPartial = false,
  });

  bool get isUser => role == 'user';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryLight,
              child: const Text('A', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: AppTheme.border),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.onSurface,
                  fontSize: 15,
                  height: 1.4,
                  fontStyle: isPartial ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
