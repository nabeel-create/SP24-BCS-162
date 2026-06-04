import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      'present' => ('Present', AppColors.present, AppColors.presentBg),
      'absent' => ('Absent', AppColors.absent, AppColors.absentBg),
      'late' => ('Late', AppColors.late, AppColors.lateBg),
      _ => ('—', AppColors.mutedFg, AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
