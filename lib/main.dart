import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/app_theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/resident/resident_dashboard.dart';

/// Global theme notifier - accessible everywhere
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }
}

/// Singleton instance
final themeProvider = ThemeProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  runApp(const SocietyMaintenanceApp());
}

/// Root widget with theme and auth-based routing
class SocietyMaintenanceApp extends StatefulWidget {
  const SocietyMaintenanceApp({super.key});

  @override
  State<SocietyMaintenanceApp> createState() => _SocietyMaintenanceAppState();
}

class _SocietyMaintenanceAppState extends State<SocietyMaintenanceApp> {
  @override
  void initState() {
    super.initState();
    themeProvider.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaintainX Society',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      darkTheme: AppTheme.darkThemeData,
      themeMode: themeProvider.mode,
      home: const SplashScreen(),
    );
  }
}

/// Listens to auth state and routes to correct dashboard or login
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
        }

        // Not logged in or email not verified
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // Email not verified — show login
        if (!snapshot.data!.emailVerified) {
          return const LoginScreen();
        }

        // Logged in — determine role
        return FutureBuilder(
          future: AuthService().getCurrentUserProfile(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              );
            }

            final user = userSnapshot.data;
            if (user == null) {
              return const LoginScreen();
            }

            // Route based on role
            if (user.isAdmin) {
              return const AdminDashboard();
            } else {
              return const ResidentDashboard();
            }
          },
        );
      },
    );
  }
}
