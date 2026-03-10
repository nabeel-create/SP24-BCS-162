import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class AppToast {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show({
    required String message,
    ToastType type = ToastType.success,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    final config = _config[type]!;
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: config.background,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(config.icon, size: 20, color: config.iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ToastType { success, error, warning, info }

class _ToastConfig {
  const _ToastConfig({
    required this.background,
    required this.icon,
    required this.iconColor,
  });

  final Color background;
  final IconData icon;
  final Color iconColor;
}

const _config = {
  ToastType.success: _ToastConfig(
    background: Color(0xFF1B5E20),
    icon: Ionicons.checkmark_circle,
    iconColor: Color(0xFF69F0AE),
  ),
  ToastType.error: _ToastConfig(
    background: Color(0xFFB71C1C),
    icon: Ionicons.close_circle,
    iconColor: Color(0xFFFF8A80),
  ),
  ToastType.warning: _ToastConfig(
    background: Color(0xFFE65100),
    icon: Ionicons.warning,
    iconColor: Color(0xFFFFD180),
  ),
  ToastType.info: _ToastConfig(
    background: Color(0xFF0D47A1),
    icon: Ionicons.information_circle,
    iconColor: Color(0xFF82B1FF),
  ),
};

