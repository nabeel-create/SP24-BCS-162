import 'package:flutter/material.dart';

import 'pages/app_shell.dart';
import 'state/submission_store.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const FormBaseApp());
}

class FormBaseApp extends StatefulWidget {
  const FormBaseApp({super.key});

  @override
  State<FormBaseApp> createState() => _FormBaseAppState();
}

class _FormBaseAppState extends State<FormBaseApp> {
  late final SubmissionStore store;

  @override
  void initState() {
    super.initState();
    store = SubmissionStore();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FormBase',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              surface: AppColors.card,
            ),
            fontFamily: 'Arial',
          ),
          home: AppShell(store: store),
        );
      },
    );
  }
}
