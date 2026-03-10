import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/patient_provider.dart';
import 'screens/add_patient_screen.dart';
import 'screens/edit_patient_screen.dart';
import 'screens/home_screen.dart';
import 'screens/patient_detail_screen.dart';
import 'theme/colors.dart';
import 'widgets/toast.dart';

void main() {
  runApp(const DoctorApp());
}

class DoctorApp extends StatelessWidget {
  const DoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      useMaterial3: false,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );

    return ChangeNotifierProvider(
      create: (_) => PatientProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: AppToast.messengerKey,
        theme: baseTheme.copyWith(
          textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
        ),
        routes: {
          '/': (_) => const HomeScreen(),
          '/add-patient': (_) => const AddPatientScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/patient') {
            final id = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => PatientDetailScreen(patientId: id),
            );
          }
          if (settings.name == '/edit-patient') {
            final id = settings.arguments as String;
            return MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => EditPatientScreen(patientId: id),
            );
          }
          return null;
        },
      ),
    );
  }
}
