import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chopel_app/theme/app_theme.dart';

class HopalTextField extends StatelessWidget {
  final String hint;
  final IconData? icon;
  final bool isPassword;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool obscureText;

  const HopalTextField({
    super.key,
    required this.hint,
    this.icon,
    this.isPassword = false,
    this.controller,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
    this.maxLines = 1,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText || isPassword,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        inputFormatters: inputFormatters,
        maxLines: (obscureText || isPassword) ? 1 : maxLines,
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textMuted),
          prefixIcon: icon != null ? Icon(icon, color: AppTheme.textMuted, size: 20) : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing16),
        ),
      ),
    );
  }
}
