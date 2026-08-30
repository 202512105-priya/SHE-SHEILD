        builder: (context, db, _) {
          return MaterialApp(
            title: 'SHE SHIELD',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.purple,
                primary: Colors.purple,
                secondary: Colors.pinkAccent,
                background: Colors.purple.shade50,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: Colors.purple.shade100),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: Colors.purple.shade100.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(color: Colors.purple, width: 2),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
       
<truncated 72 bytes>
  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            initialRoute: !db.onboardingCompleted
                ? '/onboarding'
                : (db.currentUserId == null ? '/welcome' : '/dashboard'),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/help_center': (context) => const HelpCenterScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register_user': (context) => const RegisterUserScreen(),
              '/register_guardian': (context) => const RegisterGuardianScreen(),
              '/register_responder': (context) => const RegisterResponderScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/sos': (context) => const SosScreen(),
              '/cyber_report': (context) => const CyberReportScreen(),
              '/evidence_vault': (context) => const EvidenceVaultScreen(),
              '/cab_monitor': (context) => const CabMonitorScreen(),
              '/walk_monitor': (context) => const WalkMonitorScreen(),
              '/complaint_status': (context) => const ComplaintStatusScreen(),
              '/manage_guardians': (context) => const GuardianLinkingScreen(),
              '/awareness_hub': (context) => const AwarenessHubScreen(),
              '/travel_monitor': (context) => const TravelMonitorScreen(),
            },
          );
        },
      ),
    );
  }
}

The above content does NOT show the entire file contents. If you need to view any lines of the file which were not shown to complete your task, call this tool again to view those lines.
