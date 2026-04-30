import 'package:flutter/material.dart';

import 'game_controller.dart';
import 'screens/history_screen.dart';
import 'screens/result_screen.dart';

Route<void> buildHistoryRoute(GameController controller) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return HistoryScreen(controller: controller);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetTween = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      );
      return SlideTransition(
        position: animation.drive(
          CurveTween(curve: Curves.easeOutCubic),
        ).drive(offsetTween),
        child: child,
      );
    },
  );
}

Route<void> buildResultRoute(GameController controller) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) {
      return ResultScreen(controller: controller);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}
