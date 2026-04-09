import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/student/student_home.dart';
import 'screens/recruiter/recruiter_home.dart';
import 'screens/recruiter/job_creation_form.dart';
import 'screens/recruiter/applicants_list.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/shared/company_profile_screen.dart';
import 'screens/shared/student_public_profile.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';

final authService = AuthService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
      ],
      child: const SmartPlacementApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  refreshListenable: authService,
  redirect: (context, state) {
    final authService = context.read<AuthService>();
    final isLoggedIn = authService.currentUser != null;
    final isGoingToAuth = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (authService.isLoading) {
      return null; // Wait for initialization
    }

    if (!isLoggedIn && !isGoingToAuth) {
      return '/login';
    }

    if (isLoggedIn && isGoingToAuth) {
      // Redirect based on role
      switch (authService.currentUser!.role) {
        case UserRole.student:
          return '/student-home';
        case UserRole.recruiter:
          return '/recruiter-home';
        case UserRole.admin:
          return '/admin-dashboard';
      }
    }

    return null; // No redirect needed
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/student-home',
      builder: (context, state) => const StudentHome(),
    ),
    GoRoute(
      path: '/recruiter-home',
      builder: (context, state) => const RecruiterHome(),
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboard(),
    ),
    GoRoute(
      path: '/job-creation',
      builder: (context, state) => const JobCreationForm(),
    ),
    GoRoute(
      path: '/applicants/:jobId',
      builder: (context, state) {
        final jobId = state.pathParameters['jobId']!;
        return ApplicantsList(jobId: jobId);
      },
    ),
    GoRoute(
      path: '/company/:name',
      builder: (context, state) {
        final name = state.pathParameters['name']!;
        return CompanyProfileScreen(companyName: Uri.decodeComponent(name));
      },
    ),
    GoRoute(
      path: '/student-profile/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return StudentPublicProfile(studentId: id);
      },
    ),
  ],
);

class SmartPlacementApp extends StatelessWidget {
  const SmartPlacementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Placement Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: _router,
    );
  }
}
