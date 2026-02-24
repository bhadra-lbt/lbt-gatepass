import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'models/user_role.dart';
import 'providers/auth_provider.dart';
import 'providers/gate_pass_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/staff/staff_dashboard.dart';
import 'screens/hod/hod_dashboard.dart';
import 'screens/security/security_dashboard.dart';
import 'services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
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
        // 0. Show Splash Screen while checking initial Auth status
        if (!auth.isInitialized) {
          return const SplashScreen();
        }

        // 1. Check if user is authenticated (Firebase Auth)
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        // 2. Check if user has a profile document in Firestore
        if (!auth.hasProfile) {
          // While profile is loading, show a loader
          if (auth.isLoading) {
            return const SplashScreen(); // Show splash during individual profile loads too
          }
          // If not loading and no profile, force profile completion
          return const CompleteProfileScreen();
        }

        // 3. Navigate to respective dashboard based on Firestore role
        switch (auth.userRole) {
          case UserRole.student:
            return const StudentDashboard();
          case UserRole.staff:
            return const StaffDashboard();
          case UserRole.hod:
            return const HODDashboard();
          case UserRole.security:
            return const SecurityDashboard();
          default:
            return const CompleteProfileScreen();
        }
      },
    );
  }
}
