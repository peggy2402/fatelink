import 'package:flutter/material.dart';

class LoginDivider extends StatelessWidget {
  const LoginDivider(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFD7DAE6), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF8B92A6), fontSize: 14),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD7DAE6), thickness: 1)),
      ],
    );
  }
}
