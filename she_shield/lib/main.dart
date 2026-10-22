import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/database_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sos_screens.dart';
import 'screens/travel_monitor_screen.dart';
import 'screens/wearable_pairing_screen.dart';
import 'screens/cyber_screens.dart';
import 'screens/evidence_vault_screens.dart';
import 'screens/guardian_linking_screen.dart';
import 'screens/safety_articles_screen.dart';
import 'screens/guardian_dashboard_screen.dart';
import 'screens/responder_dashboard_screen.dart';
import 'screens/police_admin_screens.dart' hide RegisterResponderScreen;
import 'screens/admin_command_center_screen.dart';
import 'screens/help_center_screen.dart';
import 'screens/demo_center_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => DatabaseService(),
      child: const SheShieldApp(),
    ),
  );
}

class SheShieldApp extends StatelessWidget {
  const SheShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(
      builder: (context, db, _) {
        return MaterialApp(
          title: 'SHE SHIELD',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: !db.onboardingCompleted
              ? '/onboarding'
              : (db.currentUserId == null ? '/welcome' : '/dashboard'),
          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/register_user': (context) => const RegisterUserScreen(),
            '/register_guardian': (context) => const RegisterGuardianScreen(),
            '/register_responder': (context) => const RegisterResponderScreen(),
            '/admin_login': (context) => const AdminLoginScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/sos': (context) => const SosScreen(),
            '/sos_protection': (context) => const SosProtectionCenterScreen(),
            '/travel_monitor': (context) => const TravelMonitorScreen(),
            '/cab_monitor': (context) => CabMonitorScreen(),
            '/walk_monitor': (context) => WalkMonitorScreen(),
            '/wearable_pairing': (context) => const WearablePairingScreen(),
            '/cyber_report': (context) => const CyberReportScreen(),
            '/complaint_status': (context) => const ComplaintStatusScreen(),
            '/evidence_vault': (context) => const EvidenceVaultScreen(),
            '/manage_guardians': (context) => const GuardianLinkingScreen(),
            '/awareness_hub': (context) => const SafetyArticlesScreen(),
            '/guardian_dashboard': (context) => const GuardianDashboardScreen(),
            '/responder_dashboard': (context) => const ResponderDashboardScreen(),
            '/admin_dashboard': (context) => const AdminCommandCenterScreen(),
            '/help_center': (context) => const HelpCenterScreen(),
            '/demo_center': (context) => const DemoCenterScreen(),
          },
        );
      },
    );
  }
}
