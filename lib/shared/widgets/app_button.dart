import 'package:flutter/material.dart';

import 'package:poms/core/constants/app_constants.dart';

enum AppButtonVariant { primary, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.minimumSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final Widget? icon;
  final Size? minimumSize;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = minimumSize ?? const Size(double.infinity, 52);

    if (isLoading) {
      return _buildLoadingButton(context, effectiveSize);
    }

    return switch (variant) {
      AppButtonVariant.primary => _buildElevated(context, effectiveSize),
      AppButtonVariant.outlined => _buildOutlined(context, effectiveSize),
      AppButtonVariant.text => _buildText(context),
    };
  }

  Widget _buildLoadingButton(BuildContext context, Size size) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(minimumSize: size),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildElevated(BuildContext context, Size size) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(minimumSize: size),
        icon: icon!,
        label: Text(label),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(minimumSize: size),
      child: Text(label),
    );
  }

  Widget _buildOutlined(BuildContext context, Size size) {
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(minimumSize: size),
        icon: icon!,
        label: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(minimumSize: size),
      child: Text(label),
    );
  }

  Widget _buildText(BuildContext context) {
    if (icon != null) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: icon!,
        label: Text(label),
      );
    }
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}

/// Compact icon-only button
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.size = AppConstants.spacingXL,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: size,
    );
  }
}
