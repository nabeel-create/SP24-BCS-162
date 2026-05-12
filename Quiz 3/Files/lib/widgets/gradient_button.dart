import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outline = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outline;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        else if (icon != null)
          Icon(
            icon,
            size: 17,
            color: outline ? AppColors.primary : Colors.white,
          ),
        if (icon != null || loading) const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: outline ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(AppColors.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          gradient: outline ? null : AppColors.purpleGradient(),
          color: outline ? AppColors.card : null,
          borderRadius: BorderRadius.circular(AppColors.radius),
          border: Border.all(
            color: outline ? AppColors.border : Colors.transparent,
          ),
        ),
        child: child,
      ),
    );
  }
}
