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
import 'screens/admin_command_center_screen.dart';
import 'screens/help_center_screen.dart';
import 'screens/demo_center_screen.dart';
import 'screens/journey_share_track_screen.dart';

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

  static Widget _buildScreenForRoute(String routeName) {
    switch (routeName) {
      case '/onboarding':
        return const OnboardingScreen();
      case '/welcome':
        return const WelcomeScreen();
      case '/login':
        return const LoginScreen();
      case '/register_user':
        return const RegisterUserScreen();
      case '/dashboard':
        return const DashboardScreen();
      case '/sos':
        return const SosScreen();
      case '/sos_protection':
        return const SosProtectionCenterScreen();
      case '/travel_monitor':
        return const TravelMonitorScreen();
      case '/cab_monitor':
        return CabMonitorScreen();
      case '/walk_monitor':
        return WalkMonitorScreen();
      case '/wearable_pairing':
        return const WearablePairingScreen();
      case '/cyber_report':
        return const CyberReportScreen();
      case '/complaint_status':
        return const ComplaintStatusScreen();
      case '/evidence_vault':
        return const EvidenceVaultScreen();
      case '/manage_guardians':
        return const GuardianLinkingScreen();
      case '/awareness_hub':
        return const SafetyArticlesScreen();
      case '/guardian_dashboard':
        return const GuardianDashboardScreen();
      case '/responder_dashboard':
        return const ResponderDashboardScreen();
      case '/admin_dashboard':
        return const AdminCommandCenterScreen();
      case '/help_center':
        return const HelpCenterScreen();
      case '/demo_center':
        return const DemoCenterScreen();
      default:
        return const WelcomeScreen();
    }
  }

  static const Set<String> _publicRoutes = {
    '/onboarding',
    '/welcome',
    '/login',
    '/register_user',
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHE SHIELD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/onboarding',
      onGenerateRoute: (RouteSettings settings) {
        final rawName = settings.name ?? '/onboarding';
        final routeName = rawName == '/' ? '/onboarding' : rawName;

        // Token-verified Guardian Live Tracking route (publicly reachable via secret URL)
        final parsedUri = Uri.tryParse(routeName);
        final uriPath = parsedUri?.path ?? routeName;
        final uriQuery = parsedUri?.queryParameters ?? const <String, String>{};
        if (uriPath.startsWith('/track/')) {
          final rawToken = uriPath.substring('/track/'.length).replaceAll(RegExp(r'/+$'), '');
          if (rawToken.isNotEmpty) {
            return MaterialPageRoute(
              settings: RouteSettings(name: routeName),
              builder: (_) => JourneyShareTrackScreen(token: rawToken),
            );
          }
        }

        if (uriPath == '/register_user') {
          final inviteTok = uriQuery['invite'];
          final shareTok = uriQuery['share'];
          return MaterialPageRoute(
            settings: RouteSettings(name: routeName),
            builder: (_) => RegisterUserScreen(
              initialAccountType: (inviteTok != null || shareTok != null) ? 'guardian' : 'registered_user',
              inviteToken: inviteTok,
              shareToken: shareTok,
            ),
          );
        }

        // Public routes render directly; protected routes wrap in reactive Role & Session Guard
        if (_publicRoutes.contains(uriPath)) {
          return MaterialPageRoute(
            settings: RouteSettings(name: routeName),
            builder: (_) => _buildScreenForRoute(uriPath),
          );
        }

        return MaterialPageRoute(
          settings: RouteSettings(name: routeName),
          builder: (_) => _ProtectedRouteGuard(
            routeName: uriPath,
            childBuilder: () => _buildScreenForRoute(uriPath),
          ),
        );
      },
    );
  }
}

class _ProtectedRouteGuard extends StatelessWidget {
  final String routeName;
  final Widget Function() childBuilder;

  const _ProtectedRouteGuard({
    required this.routeName,
    required this.childBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(
      builder: (context, db, _) {
        if (db.isSessionRestoring) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verifying secure session...'),
                ],
              ),
            ),
          );
        }

        if (!db.isAuthenticated) {
          return LoginScreen(
            initialMessage: 'Authentication required to access $routeName.',
          );
        }

        if (!db.canAccessRoute(routeName)) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Access Denied (403)'),
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gpp_bad, size: 68, color: Colors.red.shade700),
                    const SizedBox(height: 16),
                    const Text(
                      '403 Unauthorized Role Access',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your role (${db.currentRole ?? "unknown"}) is not authorized to open $routeName.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Return to Authorized Dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade800,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          db.homeRouteForRole,
                          (_) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return childBuilder();
      },
    );
  }
}
