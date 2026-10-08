import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';

class HopalSearchBar extends StatefulWidget {
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final bool autofocus;

  const HopalSearchBar({
    super.key,
    required this.placeholder,
    this.onChanged,
    this.onClear,
    this.controller,
    this.autofocus = false,
  });

  @override
  State<HopalSearchBar> createState() => _HopalSearchBarState();
}

class _HopalSearchBarState extends State<HopalSearchBar> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    _internalController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _internalController.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: AppTheme.radiusMd,
      ),
      child: TextField(
        controller: _internalController,
        onChanged: widget.onChanged,
        autofocus: widget.autofocus,
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: TextStyle(color: AppTheme.textMuted),
          prefixIcon: Icon(LucideIcons.search, color: AppTheme.textMuted, size: 20),
          suffixIcon: _internalController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, color: AppTheme.textMuted, size: 20),
                  onPressed: () {
                    _internalController.clear();
                    widget.onChanged?.call('');
                    widget.onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
        ),
      ),
    );
  }
}
