import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'auth_screens.dart'; // For GlassCard

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: "Welcome SHE SHIELD",
      description: "Your ultimate cyber-integrated personal safety shield. Explore advanced tools built to protect and empower you.",
      icon: Icons.shield,
      color: Colors.purple,
    ),
    OnboardingSlideData(
      title: "Emergency SOS System",
      description: "Trigger instant SOS via floating button, voice phrase, long press, widget, or offline mode. Includes a customizable countdown timer, cancel PIN, and automatic responder alerts.",
      icon: Icons.emergency,
      color: Colors.red,
    ),
    OnboardingSlideData(
      title: "Smart Walk Guardian",
      description: "Monitors your path using real-time motion anomaly detectors. Escalates emergency alerts automatically on running detection, phone drops, or deviation from safe routes.",
      icon: Icons.directions_walk,
      color: Colors.teal,
    ),
    OnboardingSlideData(
      t
<truncated 11650 bytes>
       ),
                            onPressed: () async {
                              await db.completeOnboarding();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(context, '/welcome');
                              }
                            },
                            child: const Text("Get Started"),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(100, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Text("Next"),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingSlideData {
  final String title;
  final String description;
  final IconData icon;
  final MaterialColor color;

  OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
