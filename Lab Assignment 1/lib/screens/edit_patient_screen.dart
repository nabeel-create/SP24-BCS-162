import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/patient.dart';
import '../providers/patient_provider.dart';
import '../theme/colors.dart';
import '../utils/file_storage.dart';
import '../utils/image_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/toast.dart';

const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const _genders = ['Male', 'Female', 'Other'];
const _statuses = ['Active', 'Follow-up', 'Critical', 'Discharged'];

const _statusColors = {
  'Active': _StatusColors(Color(0xFF2E7D32), Color(0xFFE8F5E9)),
  'Critical': _StatusColors(Color(0xFFB71C1C), Color(0xFFFFEBEE)),
  'Follow-up': _StatusColors(Color(0xFFE65100), Color(0xFFFFF3E0)),
  'Discharged': _StatusColors(Color(0xFF455A64), Color(0xFFECEFF1)),
};

class EditPatientScreen extends StatefulWidget {
  const EditPatientScreen({super.key, required this.patientId});

  final String patientId;

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final Map<String, String> _errors = {};
  bool _saving = false;
  Patient? _patient;
  late Map<String, String> _form;
  late Map<String, String> _initialForm;
  String? _pendingImagePath;
  String? _originalImagePath;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PatientProvider>(context, listen: false);
    _patient = provider.getPatient(widget.patientId);
    _form = _patient == null ? _defaultForm : _patientToForm(_patient!);
    _initialForm = Map<String, String>.from(_form);
    _originalImagePath = _form['imageUri'];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (result == null) return;
    try {
      final savedPath = await FileStorage.saveImage(result);
      if (_pendingImagePath != null && _pendingImagePath != savedPath) {
        await FileStorage.deleteIfExists(_pendingImagePath!);
      }
      setState(() {
        _pendingImagePath = savedPath;
        _form['imageUri'] = savedPath;
      });
    } catch (_) {
      AppToast.show(message: 'Unable to save image. Please try again.', type: ToastType.error);
    }
  }

  void _updateField(String key, String value) {
    setState(() {
      _form[key] = value;
      _errors.remove(key);
    });
  }

  bool get _hasChanges {
    for (final entry in _initialForm.entries) {
      if ((_form[entry.key] ?? '') != entry.value) return true;
    }
    return false;
  }

  bool _validate() {
    _errors.clear();
    if ((_form['name'] ?? '').trim().isEmpty) {
      _errors['name'] = 'Patient name is required';
    }
    if ((_form['age'] ?? '').trim().isEmpty) {
      _errors['age'] = 'Age is required';
    } else {
      final age = int.tryParse(_form['age']!.trim());
      if (age == null || age < 0 || age > 150) {
        _errors['age'] = 'Enter a valid age (0–150)';
      }
    }
    if ((_form['phone'] ?? '').trim().isEmpty) {
      _errors['phone'] = 'Phone number is required';
    } else {
      final clean = _form['phone']!.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
      if (!RegExp(r'^\d{7,15}$').hasMatch(clean)) {
        _errors['phone'] = 'Enter a valid phone number';
      }
    }

    setState(() {});
    return _errors.isEmpty;
  }

  Future<void> _handleSave() async {
    if (!_validate()) {
      await HapticFeedback.mediumImpact();
      AppToast.show(message: 'Please fix the errors above', type: ToastType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<PatientProvider>().updatePatient(widget.patientId, _form);
      await HapticFeedback.lightImpact();
      if (_pendingImagePath != null &&
          _originalImagePath != null &&
          _originalImagePath!.isNotEmpty &&
          _originalImagePath != _pendingImagePath) {
        await FileStorage.deleteIfExists(_originalImagePath!);
      }
      _pendingImagePath = null;
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (_pendingImagePath != null) {
        await FileStorage.deleteIfExists(_pendingImagePath!);
        _pendingImagePath = null;
      }
      AppToast.show(message: 'Failed to save patient. Please try again.', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    final discard = await showConfirmDialog(
      context: context,
      title: 'Discard Changes?',
      message: 'You have unsaved changes. Are you sure you want to go back without saving?',
      confirmText: 'Discard',
      cancelText: 'Keep Editing',
      confirmColor: const Color(0xFF455A64),
      icon: Ionicons.arrow_back_outline,
    );
    if (discard && _pendingImagePath != null) {
      await FileStorage.deleteIfExists(_pendingImagePath!);
      _pendingImagePath = null;
    }
    return discard;
  }

  @override
  void dispose() {
    if (_pendingImagePath != null) {
      FileStorage.deleteIfExists(_pendingImagePath!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_patient == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Patient not found',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final provider = context.watch<PatientProvider>();
    final documents = provider.documentsFor(widget.patientId);

    return WillPopScope(
      onWillPop: _confirmDiscard,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text(
            'Edit Patient',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _form['imageUri']!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              child: Image(
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                image: resolveImageProvider(_form['imageUri']!),
                              ),
                            )
                          : DottedBorder(
                              borderType: BorderType.Circle,
                              color: AppColors.primary,
                              strokeWidth: 2,
                              dashPattern: const [6, 4],
                              child: Container(
                                width: 90,
                                height: 90,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Feather.camera, size: 28, color: AppColors.primary),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add Photo',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Feather.edit_2, size: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: 'Personal Information',
                  icon: Ionicons.person_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormField(
                        label: 'Full Name',
                        value: _form['name']!,
                        requiredField: true,
                        icon: Ionicons.person_outline,
                        error: _errors['name'],
                        onChanged: (v) => _updateField('name', v),
                        placeholder: 'e.g. Ahmed Khan',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              label: 'Age',
                              value: _form['age']!,
                              requiredField: true,
                              icon: Ionicons.calendar_outline,
                              error: _errors['age'],
                              keyboardType: TextInputType.number,
                              onChanged: (v) => _updateField('age', v),
                              placeholder: '35',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FormField(
                              label: 'Weight (kg)',
                              value: _form['weight']!,
                              icon: MaterialCommunityIcons.scale,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => _updateField('weight', v),
                              placeholder: '70',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FormField(
                              label: 'Height (cm)',
                              value: _form['height']!,
                              icon: Ionicons.resize_outline,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => _updateField('height', v),
                              placeholder: '170',
                            ),
                          ),
                        ],
                      ),
                      _SelectChips(
                        label: 'Gender',
                        options: _genders,
                        selected: _form['gender']!,
                        onSelect: (v) => _updateField('gender', v),
                      ),
                      _FormField(
                        label: 'Phone Number',
                        value: _form['phone']!,
                        requiredField: true,
                        icon: Ionicons.call_outline,
                        error: _errors['phone'],
                        keyboardType: TextInputType.phone,
                        onChanged: (v) => _updateField('phone', v),
                        placeholder: 'e.g. 03001234567',
                      ),
                      _FormField(
                        label: 'Email Address',
                        value: _form['email']!,
                        icon: Ionicons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => _updateField('email', v),
                        placeholder: 'patient@email.com',
                      ),
                      _FormField(
                        label: 'Home Address',
                        value: _form['address']!,
                        icon: Ionicons.location_outline,
                        onChanged: (v) => _updateField('address', v),
                        placeholder: 'Street, City, Country',
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Emergency Contact',
                  icon: Ionicons.warning_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormField(
                        label: 'Contact Name',
                        value: _form['emergencyContact']!,
                        icon: Ionicons.person_circle_outline,
                        onChanged: (v) => _updateField('emergencyContact', v),
                        placeholder: 'e.g. Sara Ahmed (Wife)',
                      ),
                      _FormField(
                        label: 'Emergency Phone',
                        value: _form['emergencyPhone']!,
                        icon: Ionicons.call,
                        keyboardType: TextInputType.phone,
                        onChanged: (v) => _updateField('emergencyPhone', v),
                        placeholder: 'e.g. 03009876543',
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Medical Information',
                  icon: Ionicons.medical_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SelectChips(
                        label: 'Patient Status',
                        options: _statuses,
                        selected: _form['status']!,
                        colorMap: _statusColors,
                        onSelect: (v) => _updateField('status', v),
                      ),
                      _SelectChips(
                        label: 'Blood Type',
                        options: _bloodTypes,
                        selected: _form['bloodType']!,
                        onSelect: (v) => _updateField('bloodType', v),
                      ),
                      _FormField(
                        label: 'Primary Diagnosis',
                        value: _form['diagnosis']!,
                        icon: Ionicons.medical_outline,
                        onChanged: (v) => _updateField('diagnosis', v),
                        placeholder: 'e.g. Type 2 Diabetes',
                      ),
                      _FormField(
                        label: 'Known Allergies',
                        value: _form['allergies']!,
                        icon: Ionicons.warning_outline,
                        onChanged: (v) => _updateField('allergies', v),
                        placeholder: 'e.g. Penicillin, Pollen, Nuts',
                      ),
                      _FormField(
                        label: 'Current Medications',
                        value: _form['medications']!,
                        icon: Ionicons.flask_outline,
                        onChanged: (v) => _updateField('medications', v),
                        placeholder: 'e.g. Metformin 500mg, Aspirin',
                      ),
                      _FormField(
                        label: 'Next Appointment Date',
                        value: _form['appointmentDate']!,
                        icon: Ionicons.calendar_outline,
                        onChanged: (v) => _updateField('appointmentDate', v),
                        placeholder: 'e.g. March 15, 2026',
                      ),
                      _FormField(
                        label: 'Clinical Notes',
                        value: _form['notes']!,
                        multiline: true,
                        onChanged: (v) => _updateField('notes', v),
                        placeholder: 'Observations, treatment plan, follow-up instructions...',
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Documents',
                  icon: Ionicons.document_text_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            patientId: widget.patientId,
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
                            name: doc.name,
                            type: doc.type,
                            size: doc.size,
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
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      shadowColor: AppColors.primary,
                    ),
                    icon: const Icon(Ionicons.checkmark_circle, size: 20, color: Colors.white),
                    label: Text(
                      _saving ? 'Saving...' : 'Save Patient Record',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.keyboardType,
    this.multiline = false,
    this.error,
    this.requiredField = false,
    this.icon,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final TextInputType? keyboardType;
  final bool multiline;
  final String? error;
  final bool requiredField;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
              children: [
                if (requiredField)
                  TextSpan(
                    text: ' *',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.danger,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: error == null ? AppColors.border : AppColors.danger, width: 1.5),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppColors.placeholder),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: TextFormField(
                    initialValue: value,
                    onChanged: onChanged,
                    keyboardType: keyboardType,
                    maxLines: multiline ? 3 : 1,
                    minLines: multiline ? 3 : 1,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.text,
                    ),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.placeholder,
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectChips extends StatelessWidget {
  const _SelectChips({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.colorMap,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final Map<String, _StatusColors>? colorMap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final active = selected == option;
              final colors = colorMap?[option];
              final background = active
                  ? (colors?.background ?? AppColors.primary)
                  : AppColors.surface;
              final borderColor = active
                  ? (colors?.color ?? AppColors.primary)
                  : AppColors.border;
              final textColor = active
                  ? (colors?.color ?? Colors.white)
                  : AppColors.textSecondary;
              return GestureDetector(
                onTap: () async {
                  await HapticFeedback.selectionClick();
                  onSelect(option);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Text(
                    option,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusColors {
  const _StatusColors(this.color, this.background);

  final Color color;
  final Color background;
}

Map<String, String> _patientToForm(Patient patient) {
  return {
    'name': patient.name,
    'age': patient.age,
    'phone': patient.phone,
    'email': patient.email,
    'diagnosis': patient.diagnosis,
    'notes': patient.notes,
    'bloodType': patient.bloodType,
    'gender': patient.gender,
    'address': patient.address,
    'imageUri': patient.imageUri,
    'allergies': patient.allergies,
    'medications': patient.medications,
    'emergencyContact': patient.emergencyContact,
    'emergencyPhone': patient.emergencyPhone,
    'weight': patient.weight,
    'height': patient.height,
    'status': patient.status,
    'appointmentDate': patient.appointmentDate,
  };
}

Map<String, String> get _defaultForm => {
      'name': '',
      'age': '',
      'phone': '',
      'email': '',
      'diagnosis': '',
      'notes': '',
      'bloodType': '',
      'gender': '',
      'address': '',
      'imageUri': '',
      'allergies': '',
      'medications': '',
      'emergencyContact': '',
      'emergencyPhone': '',
      'weight': '',
      'height': '',
      'status': 'Active',
      'appointmentDate': '',
    };

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
  const _DocumentTile({
    required this.name,
    required this.type,
    required this.size,
    required this.onDelete,
  });

  final String name;
  final String type;
  final int size;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final normalized = type.toUpperCase();
    final icon = _documentIcon(normalized);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
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
                    name,
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
                    '$normalized • ${_formatBytes(size)}',
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


