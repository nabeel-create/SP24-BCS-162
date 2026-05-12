import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GenderChart extends StatelessWidget {
  const GenderChart({
    super.key,
    required this.male,
    required this.female,
    required this.other,
    required this.total,
  });

  final int male;
  final int female;
  final int other;
  final int total;

  @override
  Widget build(BuildContext context) {
    final segments = [
      _Segment('Male', male, const Color(0xFF2563EB)),
      _Segment('Female', female, const Color(0xFFDB2777)),
      _Segment('Other', other, const Color(0xFF7C3AED)),
    ].where((item) => item.value > 0).toList();

    return Container(
      constraints: const BoxConstraints(minWidth: 260),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gender Distribution',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$total total submissions',
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          if (total == 0)
            const SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'No data yet',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      flex: segment.value,
                      child: Container(height: 14, color: segment.color),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              children: [
                for (final segment in segments)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: segment.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            segment.label,
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${segment.value} (${(segment.value / total * 100).round()}%)',
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment {
  const _Segment(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}
