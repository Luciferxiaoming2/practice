import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final IconData? prefixIcon;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.prefixIcon,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569), // slate-600
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscure,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFA78BFA), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: const Color(0xFF94A3B8))
                : null,
          ),
        ),
      ],
    );
  }
}
