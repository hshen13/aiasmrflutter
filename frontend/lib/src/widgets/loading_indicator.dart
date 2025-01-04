import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool overlay;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final double size;

  const LoadingIndicator({
    super.key,
    this.message,
    this.overlay = false,
    this.backgroundColor,
    this.indicatorColor,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              indicatorColor ?? theme.colorScheme.primary,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: overlay ? Colors.white : theme.textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (!overlay) {
      return Center(child: content);
    }

    return Container(
      color: backgroundColor ?? Colors.black.withOpacity(0.7),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          elevation: 8,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 24,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
