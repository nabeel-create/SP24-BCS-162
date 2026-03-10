import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/patient.dart';
import '../providers/patient_provider.dart';
import '../theme/colors.dart';
import '../utils/image_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/toast.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();
    final patients = provider.patients;
    final loading = provider.loading;

    final search = _searchController.text.trim().toLowerCase();
    final filtered = search.isEmpty
        ? patients
        : patients.where((p) {
            return p.name.toLowerCase().contains(search) ||
                p.diagnosis.toLowerCase().contains(search) ||
                p.phone.contains(search);
          }).toList();

    final totalToday = patients.where((p) {
      final days = _daysSince(p.createdAt);
      return days == 0;
    }).length;

    final critical = patients.where((p) => p.status == 'Critical').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'My Patients',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      await HapticFeedback.mediumImpact();
                      if (!mounted) return;
                      Navigator.of(context).pushNamed('/add-patient');
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ),
            if (!loading && patients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(
                  children: [
                    _StatCard(label: 'Total', value: patients.length.toString()),
                    const SizedBox(width: 8),
                    _StatCard(label: 'Today', value: totalToday.toString()),
                    const SizedBox(width: 8),
                    _StatCard(
                      label: 'Critical',
                      value: critical.toString(),
                      highlight: critical > 0,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      label: 'Follow-up',
                      value: patients.where((p) => p.status == 'Follow-up').length.toString(),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Feather.search, size: 16, color: AppColors.placeholder),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name, diagnosis, phone...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.placeholder,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: Icon(Ionicons.close_circle, size: 18, color: AppColors.placeholder),
                      ),
                  ],
                ),
              ),
            ),
            if (!loading && _searchController.text.isEmpty && patients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: [
                    Icon(Ionicons.information_circle_outline,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Tap a card to view details • Tap trash icon to delete',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: loading
                  ? _LoadingState()
                  : filtered.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final patient = filtered[index];
                            return PatientCard(
                              patient: patient,
                              onDeleteRequest: () async {
                                await HapticFeedback.mediumImpact();                                final confirmed = await showConfirmDialog(
                                  context: context,
                                  title: 'Delete Patient Record',
                                  message:
                                      "Are you sure you want to permanently delete ${patient.name}'s record? This action cannot be undone.",
                                  confirmText: 'Yes, Delete',
                                  cancelText: 'Cancel',
                                  confirmColor: AppColors.danger,
                                  icon: Ionicons.trash_outline,
                                );
                                if (confirmed) {
                                  await provider.deletePatient(patient.id);
                                  AppToast.show(
                                    message: "${patient.name}'s record deleted",
                                    type: ToastType.success,
                                  );
                                }                              },
                              onOpen: () async {
                                await HapticFeedback.lightImpact();
                                if (!mounted) return;
                                Navigator.of(context).pushNamed(
                                  '/patient',
                                  arguments: patient.id,
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientCard extends StatelessWidget {
  const PatientCard({
    super.key,
    required this.patient,
    required this.onDeleteRequest,
    required this.onOpen,
  });

  final Patient patient;
  final VoidCallback onDeleteRequest;
  final VoidCallback onOpen;

  static const _bloodTypeColors = {
    'A+': Color(0xFFE53935),
    'A-': Color(0xFFEF9A9A),
    'B+': Color(0xFF1E88E5),
    'B-': Color(0xFF90CAF9),
    'AB+': Color(0xFF8E24AA),
    'AB-': Color(0xFFCE93D8),
    'O+': Color(0xFF43A047),
    'O-': Color(0xFFA5D6A7),
  };

  static const _statusConfig = {
    'Active': _StatusStyle(Color(0xFF2E7D32), Color(0xFFE8F5E9)),
    'Critical': _StatusStyle(Color(0xFFB71C1C), Color(0xFFFFEBEE)),
    'Follow-up': _StatusStyle(Color(0xFFE65100), Color(0xFFFFF3E0)),
    'Discharged': _StatusStyle(Color(0xFF455A64), Color(0xFFECEFF1)),
  };

  @override
  Widget build(BuildContext context) {
    final initial = patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '';
    final bloodColor = _bloodTypeColors[patient.bloodType] ?? AppColors.primary;
    final status = _statusConfig[patient.status] ?? _statusConfig['Active']!;
    final daysSince = _daysSince(patient.createdAt);

    return GestureDetector(
      onTap: onOpen,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _Avatar(imageUri: patient.imageUri, initial: initial),
                if (patient.bloodType.isNotEmpty)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: bloodColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        patient.bloodType,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          patient.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: status.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          patient.status,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: status.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    patient.diagnosis.isNotEmpty ? patient.diagnosis : 'No diagnosis recorded',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MetaItem(icon: Ionicons.person_outline, text: '${patient.age} yrs'),
                      if (patient.gender.isNotEmpty)
                        _MetaItem(
                          icon: patient.gender == 'Male'
                              ? Ionicons.male
                              : patient.gender == 'Female'
                                  ? Ionicons.female
                                  : Ionicons.person,
                          text: patient.gender,
                        ),
                      _MetaItem(
                        icon: Ionicons.time_outline,
                        text: daysSince == 0 ? 'Today' : '${daysSince}d ago',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: onDeleteRequest,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Ionicons.trash_outline, size: 17, color: AppColors.danger),
                  ),
                ),
                const SizedBox(height: 6),
                Icon(Ionicons.chevron_forward, size: 18, color: AppColors.border),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUri, required this.initial});

  final String imageUri;
  final String initial;

  @override
  Widget build(BuildContext context) {
    if (imageUri.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image(
          image: resolveImageProvider(imageUri),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(28),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MaterialCommunityIcons.clipboard_plus_outline, size: 72, color: AppColors.border),
            const SizedBox(height: 12),
            Text(
              'No Patients Yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tap the + button to add your first patient record',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'Loading patients...',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: highlight ? Border.all(color: const Color(0xFFFFCDD2), width: 1.5) : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.danger : AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle(this.color, this.background);

  final Color color;
  final Color background;
}

int _daysSince(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    final diff = DateTime.now().difference(date).inDays;
    return diff;
  } catch (_) {
    return 0;
  }
}



