import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../teachers/teachers_screen.dart';
import '../subjects/subjects_screen.dart';
import '../reports/reports_screen.dart';

const _items = [
  (Icons.book_outlined, 'Teachers', 'Manage teaching staff'),
  (Icons.layers_outlined, 'Subjects', 'Manage subjects & assignments'),
  (Icons.warning_amber_outlined, 'Reports', 'Defaulters & analytics'),
];

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('More', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = _items[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) {
                    if (i == 0) return const TeachersScreen();
                    if (i == 1) return const SubjectsScreen();
                    return const ReportsScreen();
                  })),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: Icon(item.$1, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(item.$3, style: const TextStyle(fontSize: 13, color: AppColors.mutedFg)),
                      ])),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.mutedFg),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
