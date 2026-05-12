import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import 'gradient_button.dart';

class ConfigPanel extends StatefulWidget {
  const ConfigPanel({super.key, required this.config, required this.onSave});

  final SupabaseConfig config;
  final void Function(String url, String anonKey) onSave;

  @override
  State<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<ConfigPanel> {
  late final TextEditingController urlController;
  late final TextEditingController keyController;

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController(text: widget.config.url);
    keyController = TextEditingController(text: widget.config.anonKey);
  }

  @override
  void dispose() {
    urlController.dispose();
    keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final urlField = _field(
            'Supabase URL',
            'https://project.supabase.co',
            urlController,
          );
          final keyField = _field('Anon API Key', 'eyJ...', keyController);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.settings_ethernet_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'URL and API Option',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (narrow)
                Column(
                  children: [urlField, const SizedBox(height: 10), keyField],
                )
              else
                Row(
                  children: [
                    Expanded(child: urlField),
                    const SizedBox(width: 10),
                    Expanded(child: keyField),
                  ],
                ),
              const SizedBox(height: 12),
              GradientButton(
                label: 'Connect / Refresh',
                icon: Icons.refresh_rounded,
                onPressed: () =>
                    widget.onSave(urlController.text, keyController.text),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: label.contains('Key'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
  }
}
