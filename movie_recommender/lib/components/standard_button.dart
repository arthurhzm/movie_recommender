import 'package:flutter/material.dart';

class StandardButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const StandardButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      child: child,
    );
  }
}
