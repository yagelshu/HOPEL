import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';

class HopalTextField extends StatefulWidget {
  final String hint;
  final IconData? icon;
  final bool isPassword;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
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
    this.onChanged,
    this.inputFormatters,
    this.maxLines = 1,
    this.obscureText = false,
  });

  @override
  State<HopalTextField> createState() => _HopalTextFieldState();
}

class _HopalTextFieldState extends State<HopalTextField> {
  bool _isPasswordVisible = false;

  bool get _isSecretField => widget.obscureText || widget.isPassword;
  bool get _isEmailField => widget.keyboardType == TextInputType.emailAddress;
  bool get _isCredentialField => _isSecretField || _isEmailField;

  @override
  Widget build(BuildContext context) {
    final effectiveObscure = _isSecretField && !_isPasswordVisible;
    final effectiveKeyboardType = (_isSecretField && widget.keyboardType == TextInputType.text)
        ? TextInputType.visiblePassword
        : widget.keyboardType;

    Widget? effectiveSuffix = widget.suffixIcon;
    if (effectiveSuffix == null && _isSecretField) {
      effectiveSuffix = IconButton(
        tooltip: _isPasswordVisible ? 'הסתר סיסמה' : 'הצג סיסמה',
        icon: Icon(
          _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: effectiveObscure,
        keyboardType: effectiveKeyboardType,
        autocorrect: !_isCredentialField,
        enableSuggestions: !_isSecretField,
        textCapitalization: _isCredentialField ? TextCapitalization.none : TextCapitalization.sentences,
        textDirection: _isCredentialField ? TextDirection.ltr : null,
        textAlign: _isCredentialField ? TextAlign.right : TextAlign.start,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        inputFormatters: widget.inputFormatters,
        maxLines: _isSecretField ? 1 : widget.maxLines,
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintTextDirection: TextDirection.rtl,
          hintStyle: TextStyle(color: AppTheme.textMuted),
          prefixIcon: widget.icon != null ? Icon(widget.icon, color: AppTheme.textMuted, size: 20) : null,
          suffixIcon: effectiveSuffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing16),
        ),
      ),
    );
  }
}
