import 'package:flutter/material.dart';

/* ================= STYLED INPUT FIELD ================= */

class StyledInputField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const StyledInputField({
    super.key,
    required this.hintText,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black45),
        prefixIcon: Icon(icon, color: Colors.black45, size: 20),
        suffixIcon: suffixIcon,

        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFD0C9F2), // soft inactive lavender
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF8F7CFF), // active lavender
            width: 1.6,
          ),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}


/* ================= GRADIENT BUTTON ================= */

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color startColor;
  final Color endColor;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.startColor,
    required this.endColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [startColor, endColor],
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
