import 'package:flutter/material.dart';
import '../../../core/config/theme_config.dart';

/// 霓虹按钮组件
///
/// 采用赛博朋克风格的按钮，带有发光效果
class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Color? color;
  final IconData? icon;
  final ButtonSize size;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.color,
    this.icon,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? ThemeConfig.primary;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: _buildButton(effectiveColor),
    );
  }

  Widget _buildButton(Color color) {
    return Container(
      height: _getHeight(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed != null
              ? [color, color.withOpacity(0.8)]
              : [Colors.grey.shade700, Colors.grey.shade800],
        ),
        borderRadius: BorderRadius.circular(ThemeConfig.buttonRadius),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(ThemeConfig.buttonRadius),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: _getIconSize(), color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: _getFontSize(),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      );
    }
    return Text(
      text,
      style: TextStyle(
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }
}

enum ButtonSize { small, medium, large }
