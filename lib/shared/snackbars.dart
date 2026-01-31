import 'package:flutter/material.dart';

void showSuccessSnackBar(BuildContext context, String message) {
  _showSnackBar(
    context,
    message,
    background: Colors.green.shade600,
    icon: Icons.check_circle,
  );
}

void showErrorSnackBar(BuildContext context, String message) {
  _showSnackBar(
    context,
    message,
    background: Colors.red.shade700,
    icon: Icons.error,
  );
}

void _showSnackBar(
  BuildContext context,
  String message, {
  required Color background,
  required IconData icon,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: background,
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
