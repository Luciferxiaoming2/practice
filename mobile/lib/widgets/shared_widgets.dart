import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const PrimaryButton({super.key, required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF7C3AED),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withOpacity(0.39),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }
}

class StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const StepIndicator({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i < current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: active ? const Color(0xFF7C3AED) : const Color(0xFF7C3AED).withOpacity(0.15),
            ),
          ),
        );
      }),
    );
  }
}
