import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum SnackbarType { success, error, info, warning }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = isDark ? AppThemeColors.dark : AppThemeColors.light;

    Color color;
    IconData icon;
    switch (type) {
      case SnackbarType.success:
        color = theme.success;
        icon = Icons.check_circle_rounded;
        break;
      case SnackbarType.error:
        color = theme.danger;
        icon = Icons.cancel_rounded;
        break;
      case SnackbarType.warning:
        color = theme.warning;
        icon = Icons.warning_rounded;
        break;
      case SnackbarType.info:
        color = AppColors.primary;
        icon = Icons.info_rounded;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF1A2C3D) : const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
