import 'package:flutter/material.dart';

import '../models/submission.dart';
import '../state/submission_store.dart';
import '../theme/app_colors.dart';
import '../widgets/form_input.dart';
import '../widgets/gender_picker.dart';
import '../widgets/gradient_button.dart';

class FormPage extends StatefulWidget {
  const FormPage({
    super.key,
    required this.store,
    required this.onDone,
    this.editing,
  });

  final SubmissionStore store;
  final Submission? editing;
  final VoidCallback onDone;

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController phone;
  late final TextEditingController address;
  Gender? gender;
  final errors = <String, String>{};

  bool get editing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editing;
    name = TextEditingController(text: item?.fullName ?? '');
    email = TextEditingController(text: item?.email ?? '');
    phone = TextEditingController(text: item?.phoneNumber ?? '');
    address = TextEditingController(text: item?.address ?? '');
    gender = item?.gender;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onDone,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editing ? 'Edit Submission' : 'New Submission',
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'All fields are required',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleGradient(),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              editing
                                  ? Icons.edit_outlined
                                  : Icons.note_add_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                editing ? 'Edit Submission' : 'New Submission',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                editing
                                    ? 'Update the details below and save'
                                    : 'Fill in all fields to submit',
                                style: const TextStyle(
                                  color: Color(0xCCFFFFFF),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              SizedBox(
                                width: 4,
                                height: 20,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Personal Information',
                                style: TextStyle(
                                  color: AppColors.foreground,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final twoCol = constraints.maxWidth > 680;
                              final fields = [
                                FormInput(
                                  label: 'Full Name',
                                  placeholder: 'e.g. Ahmed Ali',
                                  controller: name,
                                  error: errors['name'],
                                  icon: Icons.person_outline,
                                  textCapitalization: TextCapitalization.words,
                                ),
                                FormInput(
                                  label: 'Email Address',
                                  placeholder: 'e.g. ahmed@example.com',
                                  controller: email,
                                  error: errors['email'],
                                  icon: Icons.mail_outline,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                FormInput(
                                  label: 'Phone Number',
                                  placeholder: 'e.g. +92 300 1234567',
                                  controller: phone,
                                  error: errors['phone'],
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                FormInput(
                                  label: 'Address',
                                  placeholder: 'e.g. 123 Main Street, Lahore',
                                  controller: address,
                                  error: errors['address'],
                                  icon: Icons.location_on_outlined,
                                ),
                              ];
                              if (!twoCol) return Column(children: fields);
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: fields[0]),
                                      const SizedBox(width: 16),
                                      Expanded(child: fields[1]),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(child: fields[2]),
                                      const SizedBox(width: 16),
                                      Expanded(child: fields[3]),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          GenderPicker(
                            value: gender,
                            error: errors['gender'],
                            onChanged: (value) => setState(() {
                              gender = value;
                              errors.remove('gender');
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      children: [
                        GradientButton(
                          label: 'Cancel',
                          icon: Icons.close_rounded,
                          outline: true,
                          onPressed: widget.onDone,
                        ),
                        GradientButton(
                          label: editing
                              ? 'Update Record'
                              : 'Submit to Supabase',
                          icon: editing
                              ? Icons.save_outlined
                              : Icons.send_outlined,
                          loading: widget.store.saving,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final input = Submission(
      id: widget.editing?.id ?? '',
      fullName: name.text.trim(),
      email: email.text.trim().toLowerCase(),
      phoneNumber: phone.text.trim(),
      address: address.text.trim(),
      gender: gender!,
    );
    try {
      if (editing) {
        await widget.store.updateEntry(widget.editing!.id, input);
      } else {
        await widget.store.createEntry(input);
      }
      if (mounted) widget.onDone();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  bool _validate() {
    final next = <String, String>{};
    if (name.text.trim().isEmpty) {
      next['name'] = 'Full name is required';
    } else if (name.text.trim().length < 3) {
      next['name'] = 'Name must be at least 3 characters';
    }
    if (email.text.trim().isEmpty) {
      next['email'] = 'Email is required';
    } else if (!RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(email.text.trim())) {
      next['email'] = 'Enter a valid email address';
    }
    if (phone.text.trim().isEmpty) {
      next['phone'] = 'Phone number is required';
    } else if (!RegExp(r'^[\d\s+\-()]{7,15}$').hasMatch(phone.text.trim())) {
      next['phone'] = 'Enter a valid phone number';
    }
    if (address.text.trim().isEmpty) {
      next['address'] = 'Address is required';
    } else if (address.text.trim().length < 5) {
      next['address'] = 'Please enter a complete address';
    }
    if (gender == null) next['gender'] = 'Please select a gender';
    setState(() {
      errors
        ..clear()
        ..addAll(next);
    });
    return next.isEmpty;
  }
}
