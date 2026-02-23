import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'models/user_role.dart';
import 'providers/auth_provider.dart';
import 'providers/gate_pass_provider.dart';
import 'screens/login_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/staff/staff_dashboard.dart';
import 'screens/hod/hod_dashboard.dart';
import 'screens/security/security_dashboard.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GatePassProvider()),
      ],
      child: const SmartGatePassApp(),
    ),
  );
}

class SmartGatePassApp extends StatelessWidget {
  const SmartGatePassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Gate Pass',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        switch (auth.userRole) {
          case UserRole.student:
            return const StudentDashboard();
          case UserRole.staff:
            return const StaffDashboard();
          case UserRole.hod:
            return const HODDashboard();
          case UserRole.security:
            return const SecurityDashboard();
          case null:
            return const LoginScreen();
        }
      },
    );
  }
}
