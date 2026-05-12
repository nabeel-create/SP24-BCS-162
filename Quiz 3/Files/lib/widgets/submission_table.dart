import 'package:flutter/material.dart';

import '../models/submission.dart';
import '../theme/app_colors.dart';

class SubmissionTable extends StatelessWidget {
  const SubmissionTable({
    super.key,
    required this.data,
    required this.deletingId,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Submission> data;
  final String? deletingId;
  final ValueChanged<Submission> onEdit;
  final ValueChanged<Submission> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1220,
          child: Column(
            children: [
              Container(
                color: AppColors.muted,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: const Row(
                  children: [
                    _Head('#', 42),
                    _Head('Name', 190),
                    _Head('Email', 230),
                    _Head('Phone', 150),
                    _Head('Address', 250),
                    _Head('Gender', 110),
                    _Head('Date', 120),
                    _Head('Actions', 90),
                  ],
                ),
              ),
              if (data.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(42),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        color: AppColors.mutedForeground,
                        size: 34,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No results found',
                        style: TextStyle(color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 520),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final deleting = deletingId == item.id;
                      return Opacity(
                        opacity: deleting ? 0.45 : 1,
                        child: Container(
                          color: index.isEven
                              ? AppColors.card
                              : AppColors.muted.withValues(alpha: 0.35),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              _Cell('${index + 1}', 42),
                              SizedBox(
                                width: 190,
                                child: _NameCell(item: item),
                              ),
                              _Cell(item.email, 230),
                              _Cell(item.phoneNumber, 150),
                              _Cell(item.address, 250),
                              SizedBox(
                                width: 110,
                                child: _GenderBadge(gender: item.gender),
                              ),
                              _Cell(_date(item.createdAt), 120),
                              SizedBox(
                                width: 90,
                                child: Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      onPressed: deleting
                                          ? null
                                          : () => onEdit(item),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: deleting
                                          ? null
                                          : () => onDelete(item),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppColors.destructive,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFEE2E2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _date(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text, this.width);

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, this.width);

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
      ),
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({required this.item});

  final Submission item;

  @override
  Widget build(BuildContext context) {
    final color = _genderColor(item.gender);
    final initials = item.fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color.withValues(alpha: 0.14),
          child: Text(
            initials,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderBadge extends StatelessWidget {
  const _GenderBadge({required this.gender});

  final Gender gender;

  @override
  Widget build(BuildContext context) {
    final color = _genderColor(gender);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          gender.label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Color _genderColor(Gender gender) {
  switch (gender) {
    case Gender.male:
      return const Color(0xFF2563EB);
    case Gender.female:
      return const Color(0xFFDB2777);
    case Gender.other:
      return const Color(0xFF7C3AED);
  }
}
