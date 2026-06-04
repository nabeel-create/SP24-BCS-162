import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/students/students_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/departments/departments_screen.dart';
import '../screens/more/more_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    StudentsScreen(),
    AttendanceScreen(),
    DepartmentsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          backgroundColor: AppColors.card,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.mutedFg,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Students'),
            BottomNavigationBarItem(icon: Icon(Icons.check_box_outline_blank), activeIcon: Icon(Icons.check_box), label: 'Attendance'),
            BottomNavigationBarItem(icon: Icon(Icons.business_outlined), activeIcon: Icon(Icons.business), label: 'Depts'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'More'),
          ],
        ),
      ),
    );
  }
}
