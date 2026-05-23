import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final bool isDanger;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
    required this.onCancel,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(message, style: const TextStyle(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: isDanger
              ? FilledButton.styleFrom(backgroundColor: Colors.red.shade600)
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}
