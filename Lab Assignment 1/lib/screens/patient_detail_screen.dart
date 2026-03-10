import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/patient_document.dart';
import '../providers/patient_provider.dart';
import '../theme/colors.dart';
import '../utils/file_storage.dart';
import '../utils/image_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/toast.dart';

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key, required this.patientId});

  final String patientId;

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
    final provider = context.watch<PatientProvider>();
    final patient = provider.getPatient(patientId);
    final documents = provider.documentsFor(patientId);

    if (patient == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(MaterialCommunityIcons.account_question_outline, size: 64, color: AppColors.border),
              const SizedBox(height: 12),
              Text(
                'Patient not found',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final initial = patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '';
    final bloodColor = _bloodTypeColors[patient.bloodType] ?? AppColors.primary;
    final status = _statusConfig[patient.status] ?? _statusConfig['Active']!;
    final createdDate = _formatDate(patient.createdAt, 'MMMM d, yyyy');
    final updatedDate = _formatDate(patient.updatedAt, 'MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          patient.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    patient.imageUri.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(48),
                            child: Image(
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              image: resolveImageProvider(patient.imageUri),
                            ),
                          )
                        : Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(48),
                              border: Border.all(color: AppColors.primary.withOpacity(0.20), width: 3),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                    const SizedBox(height: 14),
                    Text(
                      patient.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        if (patient.gender.isNotEmpty)
                          _Badge(
                            icon: patient.gender == 'Male'
                                ? Ionicons.male
                                : patient.gender == 'Female'
                                    ? Ionicons.female
                                    : Ionicons.person,
                            label: patient.gender,
                            color: patient.gender == 'Male' ? const Color(0xFF1976D2) : const Color(0xFFE91E63),
                            background: patient.gender == 'Male'
                                ? const Color(0xFF1976D2).withOpacity(0.08)
                                : const Color(0xFFE91E63).withOpacity(0.08),
                          ),
                        if (patient.bloodType.isNotEmpty)
                          _Badge(
                            icon: MaterialCommunityIcons.blood_bag,
                            label: patient.bloodType,
                            color: bloodColor,
                            background: bloodColor.withOpacity(0.12),
                          ),
                        if (patient.age.isNotEmpty)
                          _Badge(
                            icon: Ionicons.person_outline,
                            label: '${patient.age} yrs',
                            color: AppColors.primary,
                            background: AppColors.primary.withOpacity(0.10),
                          ),
                        _Badge(
                          icon: Ionicons.pulse_outline,
                          label: patient.status,
                          color: status.color,
                          background: status.background,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      patient.diagnosis.isNotEmpty ? patient.diagnosis : 'No diagnosis recorded',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (patient.weight.isNotEmpty || patient.height.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      if (patient.weight.isNotEmpty)
                        Expanded(
                          child: _VitalCard(
                            icon: MaterialCommunityIcons.scale,
                            value: patient.weight,
                            label: 'Weight (kg)',
                          ),
                        ),
                      if (patient.weight.isNotEmpty && patient.height.isNotEmpty)
                        const SizedBox(width: 12),
                      if (patient.height.isNotEmpty)
                        Expanded(
                          child: _VitalCard(
                            icon: MaterialCommunityIcons.human_male_height,
                            value: patient.height,
                            label: 'Height (cm)',
                          ),
                        ),
                    ],
                  ),
                ),
              _DetailSection(
                title: 'Contact Information',
                child: _InfoCard(
                  children: [
                    if (patient.phone.isNotEmpty)
                      _InfoRow(icon: Ionicons.call_outline, label: 'Phone', value: patient.phone),
                    if (patient.email.isNotEmpty)
                      _InfoRow(icon: Ionicons.mail_outline, label: 'Email', value: patient.email),
                    if (patient.address.isNotEmpty)
                      _InfoRow(icon: Ionicons.location_outline, label: 'Address', value: patient.address),
                  ],
                ),
              ),
              if (patient.emergencyContact.isNotEmpty || patient.emergencyPhone.isNotEmpty)
                _DetailSection(
                  title: 'Emergency Contact',
                  child: _InfoCard(
                    borderColor: AppColors.danger,
                    children: [
                      if (patient.emergencyContact.isNotEmpty)
                        _InfoRow(
                          icon: Ionicons.person_circle_outline,
                          label: 'Contact Name',
                          value: patient.emergencyContact,
                        ),
                      if (patient.emergencyPhone.isNotEmpty)
                        _InfoRow(icon: Ionicons.call, label: 'Emergency Phone', value: patient.emergencyPhone),
                    ],
                  ),
                ),
              _DetailSection(
                title: 'Medical Record',
                child: _InfoCard(
                  children: [
                    if (patient.diagnosis.isNotEmpty)
                      _InfoRow(icon: Ionicons.medical_outline, label: 'Diagnosis', value: patient.diagnosis),
                    if (patient.allergies.isNotEmpty)
                      _InfoRow(icon: Ionicons.warning_outline, label: 'Allergies', value: patient.allergies),
                    if (patient.medications.isNotEmpty)
                      _InfoRow(icon: Ionicons.flask_outline, label: 'Current Medications', value: patient.medications),
                    if (patient.notes.isNotEmpty)
                      _InfoRow(
                        icon: Ionicons.document_text_outline,
                        label: 'Clinical Notes',
                        value: patient.notes,
                        multiline: true,
                      ),
                  ],
                ),
              ),
              _DetailSection(
                title: 'Documents',
                child: _InfoCard(
                  children: [
                    _DocumentHeader(
                      onAdd: () async {
                        await HapticFeedback.selectionClick();
                        final result = await FilePicker.platform.pickFiles(
                          allowMultiple: false,
                          withData: false,
                        );
                        if (result == null || result.files.isEmpty) return;
                        final picked = result.files.first;
                        final stored = await FileStorage.saveDocument(picked);
                        if (stored == null) {
                          AppToast.show(
                            message: 'Unable to save document on this device.',
                            type: ToastType.error,
                          );
                          return;
                        }
                        await provider.addDocument(
                          patientId: patient.id,
                          name: stored.name,
                          type: stored.type,
                          path: stored.path,
                          size: stored.size,
                        );
                        AppToast.show(message: 'Document added', type: ToastType.success);
                      },
                    ),
                    if (documents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'No documents added yet',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      ...documents.map(
                        (doc) => _DocumentTile(
                          document: doc,
                          onDelete: () async {
                            await HapticFeedback.mediumImpact();
                            final confirmed = await showConfirmDialog(
                              context: context,
                              title: 'Delete Document',
                              message: 'Remove ${doc.name} from this patient record?',
                              confirmText: 'Delete',
                              cancelText: 'Cancel',
                              confirmColor: AppColors.danger,
                              icon: Ionicons.trash_outline,
                            );
                            if (confirmed) {
                              await provider.deleteDocument(doc.id);
                              AppToast.show(message: 'Document removed', type: ToastType.success);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (patient.appointmentDate.isNotEmpty)
                _DetailSection(
                  title: 'Appointment',
                  child: _InfoCard(
                    borderColor: AppColors.accent,
                    children: [
                      _InfoRow(
                        icon: Ionicons.calendar_outline,
                        label: 'Next Appointment',
                        value: patient.appointmentDate,
                        highlightColor: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              _DetailSection(
                title: 'Record Info',
                child: _InfoCard(
                  children: [
                    _InfoRow(icon: Ionicons.calendar_outline, label: 'Added On', value: createdDate),
                    _InfoRow(icon: Ionicons.refresh_outline, label: 'Last Updated', value: updatedDate),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await HapticFeedback.lightImpact();
                          if (context.mounted) {
                            Navigator.of(context).pushNamed('/edit-patient', arguments: patient.id);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          shadowColor: AppColors.primary,
                        ),
                        icon: Icon(Feather.edit_2, size: 18, color: Colors.white),
                        label: Text(
                          'Edit Record',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await HapticFeedback.mediumImpact();
                          final confirmed = await showConfirmDialog(
                            context: context,
                            title: 'Delete Patient Record',
                            message:
                                "This will permanently remove ${patient.name}'s complete medical record. This action cannot be undone.",
                            confirmText: 'Yes, Delete',
                            cancelText: 'Keep Record',
                            confirmColor: AppColors.danger,
                            icon: Ionicons.trash_outline,
                          );
                          if (confirmed) {
                            await provider.deletePatient(patient.id);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.danger.withOpacity(0.4), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: AppColors.danger.withOpacity(0.07),
                        ),
                        icon: Icon(Ionicons.trash_outline, size: 18, color: AppColors.danger),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.danger),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color, required this.background});

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children, this.borderColor});

  final List<Widget> children;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border(left: BorderSide(color: borderColor!, width: 3)) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlightColor,
    this.multiline = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? highlightColor;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (highlightColor ?? AppColors.primary).withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: highlightColor ?? AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: highlightColor == null ? FontWeight.w400 : FontWeight.w600,
                    color: highlightColor ?? AppColors.text,
                    height: multiline ? 1.4 : 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle(this.color, this.background);

  final Color color;
  final Color background;
}

String _formatDate(String iso, String pattern) {
  try {
    final date = DateTime.parse(iso);
    return DateFormat(pattern).format(date);
  } catch (_) {
    return '';
  }
}

class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Attachments',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            backgroundColor: AppColors.primary.withOpacity(0.10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(Feather.paperclip, size: 14, color: AppColors.primary),
          label: Text(
            'Add',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document, required this.onDelete});

  final PatientDocument document;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final type = document.type.toUpperCase();
    final icon = _documentIcon(type);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$type • ${_formatBytes(document.size)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Ionicons.trash_outline, size: 16, color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _documentIcon(String type) {
  if (type == 'PDF') return Ionicons.document_text_outline;
  if (type == 'PNG' || type == 'JPG' || type == 'JPEG') return Ionicons.image_outline;
  return Ionicons.attach_outline;
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 KB';
  const kb = 1024;
  const mb = 1024 * 1024;
  if (bytes >= mb) {
    return '${(bytes / mb).toStringAsFixed(1)} MB';
  }
  return '${(bytes / kb).toStringAsFixed(0)} KB';
}


