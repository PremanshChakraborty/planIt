import 'package:flutter/material.dart';

class MyOutlineButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final Icon icon;
  final Color color;
  const MyOutlineButton({
    super.key,
    required this.title,
    required this.onPressed,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon.icon,
        size: 20,
        color: color,
      ),
      label: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, 0),
        side: BorderSide(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
