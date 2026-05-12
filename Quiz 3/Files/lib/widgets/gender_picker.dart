import 'package:flutter/material.dart';

import '../models/submission.dart';
import '../theme/app_colors.dart';

class GenderPicker extends StatelessWidget {
  const GenderPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.error,
  });

  final Gender? value;
  final ValueChanged<Gender> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final gender in Gender.values)
              ChoiceChip(
                selected: value == gender,
                onSelected: (_) => onChanged(gender),
                avatar: Icon(
                  _iconFor(gender),
                  size: 17,
                  color: value == gender ? Colors.white : _colorFor(gender),
                ),
                label: Text(gender.label),
                labelStyle: TextStyle(
                  color: value == gender
                      ? Colors.white
                      : AppColors.mutedForeground,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: _colorFor(gender),
                backgroundColor: AppColors.input,
                side: BorderSide(
                  color: value == gender ? _colorFor(gender) : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: const TextStyle(color: AppColors.destructive, fontSize: 12),
          ),
        ],
      ],
    );
  }

  IconData _iconFor(Gender gender) {
    switch (gender) {
      case Gender.male:
        return Icons.male_rounded;
      case Gender.female:
        return Icons.female_rounded;
      case Gender.other:
        return Icons.person_outline_rounded;
    }
  }

  Color _colorFor(Gender gender) {
    switch (gender) {
      case Gender.male:
        return const Color(0xFF2563EB);
      case Gender.female:
        return const Color(0xFFDB2777);
      case Gender.other:
        return const Color(0xFF7C3AED);
    }
  }
}
