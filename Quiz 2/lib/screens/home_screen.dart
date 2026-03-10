import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_colors.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/user_card.dart';
import 'user_detail_screen.dart';
import 'user_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  void _showNavigationMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppSnackbar.show(context, message: message, type: SnackbarType.success);
    });
  }
  Future<void> _handleRefresh(UserProvider provider) async {
    await provider.refreshUsers();
    if (mounted) {
      AppSnackbar.show(context, message: 'Records refreshed', type: SnackbarType.success);
    }
  }

  Future<void> _handleExport(UserProvider provider) async {
    try {
      final json = provider.exportBackup();
      await Share.share(json, subject: 'ProfileVault Backup');
      if (mounted) {
        AppSnackbar.show(context, message: 'Backup exported successfully', type: SnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: 'Export failed', type: SnackbarType.error);
      }
    }
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const UserFormScreen(),
        fullscreenDialog: true,
      ),
    );
    if (!mounted || result == null) return;
    _showNavigationMessage(result);
  }

  Future<void> _navigateToEdit(User user) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => UserFormScreen(user: user),
        fullscreenDialog: true,
      ),
    );
    if (!mounted || result == null) return;
    _showNavigationMessage(result);
  }

  Future<void> _navigateToDetails(User user) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
    );
    if (!mounted || result == null) return;
    _showNavigationMessage(result);
  }

  Future<void> _deleteUser(User user) async {
    final provider = context.read<UserProvider>();
    final originalIndex = provider.indexOfUser(user.id);

    await provider.deleteUser(user.id);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A2C3D)
            : const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Text('${user.name} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.accent,
          onPressed: () async {
            try {
              await provider.restoreUser(user, index: originalIndex);
            } on DuplicateUserException catch (e) {
              if (mounted) {
                AppSnackbar.show(context, message: e.message, type: SnackbarType.error);
              }
            }
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = isDark ? AppThemeColors.dark : AppThemeColors.light;

    showDialog(
      context: context,
      barrierColor: theme.overlay,
      builder: (ctx) => Dialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_rounded, size: 24, color: theme.danger),
              ),
              const SizedBox(height: 12),
              Text(
                'Delete User',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Are you sure you want to delete\n'),
                    TextSpan(
                      text: user.name,
                      style: TextStyle(
                        color: theme.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '? You can undo it right after deleting.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.border),
                        foregroundColor: theme.text,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600, color: theme.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _deleteUser(user);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortDialog(UserProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = isDark ? AppThemeColors.dark : AppThemeColors.light;

    const options = [
      _SortOption(label: 'Name', field: SortField.name, icon: Icons.person_rounded),
      _SortOption(label: 'Age', field: SortField.age, icon: Icons.calendar_today_rounded),
      _SortOption(label: 'Date Added', field: SortField.createdAt, icon: Icons.access_time_rounded),
    ];

    showDialog(
      context: context,
      barrierColor: theme.overlay,
      builder: (ctx) => Dialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort By',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final isSelected = provider.sortField == opt.field;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        provider.setSortField(opt.field);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : theme.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(opt.icon, size: 16, color: isSelected ? AppColors.primary : theme.textSecondary),
                            const SizedBox(width: 12),
                            Text(
                              opt.label,
                              style: TextStyle(
                                color: isSelected ? AppColors.primary : theme.text,
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            if (isSelected) ...[
                              const Spacer(),
                              const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = isDark ? AppThemeColors.dark : AppThemeColors.light;
    final provider = context.watch<UserProvider>();
    final topPad = MediaQuery.of(context).padding.top;
    const horizontalPadding = 16.0;
    final headerTopSpacing = topPad + 78;

    const sortLabels = {
      SortField.name: 'Name',
      SortField.age: 'Age',
      SortField.createdAt: 'Date Added',
    };

    return Scaffold(
      backgroundColor: theme.background,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0D1B2A), const Color(0xFF0D1B2A)]
                    : [const Color(0xFFE8F1FB), const Color(0xFFF0F4F8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: theme.border)),
            ),
            padding: EdgeInsets.fromLTRB(horizontalPadding, headerTopSpacing, horizontalPadding, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ProfileVault',
                            style: GoogleFonts.inter(
                              color: theme.text,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.1,
                              height: 0.98,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${provider.users.length} ${provider.users.length == 1 ? "record" : "records"}',
                              style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _HeaderIconButton(icon: Icons.refresh_rounded, color: theme.card, iconColor: theme.textSecondary, onTap: () => _handleRefresh(provider)),
                        const SizedBox(width: 8),
                        _HeaderIconButton(icon: Icons.download_rounded, color: theme.card, iconColor: theme.textSecondary, onTap: () => _handleExport(provider)),
                        const SizedBox(width: 8),
                        _AddButton(onTap: _navigateToAdd),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 37,
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: theme.border),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 13),
                      Icon(Icons.search_rounded, size: 17, color: theme.placeholder),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(color: theme.text, fontSize: 13, fontWeight: FontWeight.w400, height: 1.2),
                          decoration: InputDecoration(
                            hintText: 'Search by name, email or age...',
                            hintStyle: TextStyle(color: theme.placeholder, fontSize: 13, fontWeight: FontWeight.w400, height: 1.2),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                          onChanged: provider.setSearchQuery,
                        ),
                      ),
                      if (provider.searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.close_rounded, size: 16, color: theme.placeholder),
                          ),
                        )
                      else
                        const SizedBox(width: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showSortDialog(provider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tune_rounded, size: 13, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(sortLabels[provider.sortField]!, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: provider.toggleSortOrder,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.border),
                        ),
                        child: Icon(provider.sortOrder == SortOrder.asc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 13, color: theme.textSecondary),
                      ),
                    ),
                    const Spacer(),
                    Text('${provider.filteredUsers.length} shown', style: TextStyle(color: theme.textSecondary, fontSize: 12, fontWeight: FontWeight.w400)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? ListView.builder(itemCount: 4, padding: const EdgeInsets.symmetric(vertical: 12), itemBuilder: (_, __) => const SkeletonCard())
                : provider.filteredUsers.isEmpty
                    ? _EmptyState(searchQuery: provider.searchQuery, theme: theme, onAdd: _navigateToAdd)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => _handleRefresh(provider),
                        child: ListView.builder(
                          padding: EdgeInsets.only(top: 12, bottom: MediaQuery.of(context).padding.bottom + 20),
                          itemCount: provider.filteredUsers.length,
                          itemBuilder: (_, i) {
                            final user = provider.filteredUsers[i];
                            return UserCard(
                              user: user,
                              onTap: () => _navigateToDetails(user),
                              onEdit: () => _navigateToEdit(user),
                              onDelete: () => _showDeleteDialog(user),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.color, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 17, color: iconColor)),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: const SizedBox(width: 44, height: 44, child: Icon(Icons.add_rounded, size: 19, color: Colors.white)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String searchQuery;
  final AppThemeColors theme;
  final VoidCallback onAdd;

  const _EmptyState({required this.searchQuery, required this.theme, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isSearching = searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 32, right: 32, bottom: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.group_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No results found' : 'No users yet',
              style: GoogleFonts.inter(color: theme.text, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isSearching ? 'No users match "$searchQuery"' : 'Tap below to add your first user profile',
              style: TextStyle(color: theme.textSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SortOption {
  final String label;
  final SortField field;
  final IconData icon;

  const _SortOption({required this.label, required this.field, required this.icon});
}


