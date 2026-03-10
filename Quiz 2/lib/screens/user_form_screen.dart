import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_snackbar.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();

  String _imageUri = '';
  bool _isSaving = false;
  bool _clearImage = false;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _emailController.text = widget.user!.email;
      _ageController.text = widget.user!.age;
      _imageUri = widget.user!.imageUri ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (result != null && mounted) {
      setState(() {
        _imageUri = result.path;
        _clearImage = false;
      });
      AppSnackbar.show(context, message: 'Photo selected', type: SnackbarType.success);
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (result != null && mounted) {
      setState(() {
        _imageUri = result.path;
        _clearImage = false;
      });
      AppSnackbar.show(context, message: 'Photo taken', type: SnackbarType.success);
    }
  }

  void _removeImage() {
    setState(() {
      _imageUri = '';
      _clearImage = true;
    });
    AppSnackbar.show(context, message: 'Photo removed', type: SnackbarType.info);
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _ageController.clear();
    setState(() {
      _imageUri = '';
      _clearImage = false;
    });
    AppSnackbar.show(context, message: 'Form cleared', type: SnackbarType.info);
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Email is required';
    }

    final emailReg = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailReg.hasMatch(text)) {
      return 'Enter a valid email address';
    }

    final provider = context.read<UserProvider>();
    if (provider.emailExists(text, excludingId: widget.user?.id)) {
      return 'This email is already in use';
    }

    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      AppSnackbar.show(
        context,
        message: 'Please fix the errors before saving',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final provider = context.read<UserProvider>();
      if (isEditing) {
        await provider.updateUser(
          widget.user!.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          age: _ageController.text.trim(),
          imageUri: _imageUri.isNotEmpty ? _imageUri : null,
          clearImage: _clearImage,
        );
      } else {
        await provider.addUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          age: _ageController.text.trim(),
          imageUri: _imageUri.isNotEmpty ? _imageUri : null,
        );
      }
      if (mounted) {
        Navigator.pop(
          context,
          isEditing ? 'User details updated successfully' : 'User added successfully',
        );
      }
    } on DuplicateUserException catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: e.message, type: SnackbarType.error);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: 'Failed to save user', type: SnackbarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  Widget _buildAvatarPreview(AppThemeColors theme) {
    final name = _nameController.text.isNotEmpty ? _nameController.text : 'User';
    final trimmedName = name.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName.substring(0, 1).toUpperCase() : 'U';
    final isLocalFile = _imageUri.isNotEmpty && !_imageUri.startsWith('http');

    Widget avatar;
    if (isLocalFile) {
      avatar = ClipOval(
        child: Image.file(
          File(_imageUri),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialAvatar(initial: initial),
        ),
      );
    } else {
      avatar = _InitialAvatar(initial: initial);
    }

    return Stack(
      children: [
        avatar,
        if (_imageUri.isEmpty)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.person_rounded, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = isDark ? AppThemeColors.dark : AppThemeColors.light;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isEditing ? 'Edit User' : 'Add User',
          style: TextStyle(color: theme.text, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: theme.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      _buildAvatarPreview(theme),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _ImageButton(icon: Icons.photo_library_rounded, label: 'Gallery', color: AppColors.primary, onTap: _pickFromGallery),
                          _ImageButton(icon: Icons.camera_alt_rounded, label: 'Camera', color: AppColors.accent, onTap: _takePhoto),
                          if (_imageUri.isNotEmpty)
                            _ImageButton(icon: Icons.close_rounded, label: 'Remove', color: theme.danger, onTap: _removeImage),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'PROFILE INFO',
                style: TextStyle(color: theme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
              ),
              const SizedBox(height: 16),
              _FormField(
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                required: true,
                theme: theme,
                child: TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: theme.text, fontSize: 15, fontWeight: FontWeight.w400),
                  decoration: _inputDecoration('Enter full name', theme),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (v.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              _FormField(
                label: 'Email Address',
                icon: Icons.mail_outline_rounded,
                required: true,
                theme: theme,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  style: TextStyle(color: theme.text, fontSize: 15, fontWeight: FontWeight.w400),
                  decoration: _inputDecoration('Enter email address', theme),
                  validator: _validateEmail,
                ),
              ),
              const SizedBox(height: 16),
              _FormField(
                label: 'Age',
                icon: Icons.calendar_today_outlined,
                required: true,
                theme: theme,
                child: TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  style: TextStyle(color: theme.text, fontSize: 15, fontWeight: FontWeight.w400),
                  decoration: _inputDecoration('Enter age', theme),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Age is required';
                    }
                    final age = int.tryParse(v.trim());
                    if (age == null || age < 1 || age > 150) {
                      return 'Enter a valid age (1-150)';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.35),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isEditing ? Icons.check_rounded : Icons.person_add_rounded, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              isEditing ? 'Update User' : 'Add User',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _resetForm,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.border),
                    foregroundColor: theme.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded, size: 16, color: theme.textSecondary),
                      const SizedBox(width: 8),
                      Text('Reset Form', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, AppThemeColors theme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.placeholder, fontSize: 15),
      filled: true,
      fillColor: theme.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.danger, width: 1.5),
      ),
      errorStyle: TextStyle(color: theme.danger, fontSize: 12, fontWeight: FontWeight.w400),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initial;

  const _InitialAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool required;
  final AppThemeColors theme;
  final Widget child;

  const _FormField({required this.label, required this.icon, required this.required, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: theme.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
            if (required) Text(' *', style: TextStyle(color: theme.danger, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ImageButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ImageButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}







