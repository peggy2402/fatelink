import 'package:flutter/material.dart';

class LoginDivider extends StatelessWidget {
  const LoginDivider(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFD7DAE6), thickness: 1)),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8B92A6), fontSize: 13),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD7DAE6), thickness: 1)),
      ],
    );
  }
}
