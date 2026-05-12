import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum GenderFilter { all, male, female, other }

enum SortKey { newest, oldest, nameAsc, nameDesc }

extension GenderFilterLabel on GenderFilter {
  String get label {
    switch (this) {
      case GenderFilter.all:
        return 'All';
      case GenderFilter.male:
        return 'Male';
      case GenderFilter.female:
        return 'Female';
      case GenderFilter.other:
        return 'Other';
    }
  }
}

extension SortKeyLabel on SortKey {
  String get label {
    switch (this) {
      case SortKey.newest:
        return 'Newest';
      case SortKey.oldest:
        return 'Oldest';
      case SortKey.nameAsc:
        return 'Name A-Z';
      case SortKey.nameDesc:
        return 'Name Z-A';
    }
  }
}

class SearchFilter extends StatelessWidget {
  const SearchFilter({
    super.key,
    required this.queryController,
    required this.onQueryChanged,
    required this.genderFilter,
    required this.onGenderChanged,
    required this.sort,
    required this.onSortChanged,
    required this.resultCount,
    required this.totalCount,
  });

  final TextEditingController queryController;
  final ValueChanged<String> onQueryChanged;
  final GenderFilter genderFilter;
  final ValueChanged<GenderFilter> onGenderChanged;
  final SortKey sort;
  final ValueChanged<SortKey> onSortChanged;
  final int resultCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              final search = TextField(
                controller: queryController,
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, phone or address...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                  suffixIcon: queryController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            queryController.clear();
                            onQueryChanged('');
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.input,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              );
              final sortControl = Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  for (final item in SortKey.values)
                    ChoiceChip(
                      selected: sort == item,
                      label: Text(item.label),
                      onSelected: (_) => onSortChanged(item),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: sort == item
                            ? Colors.white
                            : AppColors.mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppColors.input,
                      side: const BorderSide(color: AppColors.border),
                    ),
                ],
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [search, const SizedBox(height: 10), sortControl],
                );
              }
              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 10),
                  sortControl,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final gender in GenderFilter.values)
                      ChoiceChip(
                        selected: genderFilter == gender,
                        label: Text(gender.label),
                        onSelected: (_) => onGenderChanged(gender),
                        selectedColor: _genderColor(gender),
                        backgroundColor: AppColors.input,
                        side: BorderSide(
                          color: genderFilter == gender
                              ? _genderColor(gender)
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: genderFilter == gender
                              ? Colors.white
                              : AppColors.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                resultCount == totalCount
                    ? '$totalCount records'
                    : '$resultCount of $totalCount records',
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _genderColor(GenderFilter gender) {
    switch (gender) {
      case GenderFilter.all:
        return AppColors.primary;
      case GenderFilter.male:
        return const Color(0xFF2563EB);
      case GenderFilter.female:
        return const Color(0xFFDB2777);
      case GenderFilter.other:
        return const Color(0xFF7C3AED);
    }
  }
}
