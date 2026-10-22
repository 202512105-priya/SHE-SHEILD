import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class OnboardingSlideData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String badgeText;

  OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.badgeText,
  });
}

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
      title: "Welcome to SHE SHIELD",
      description:
          "Your ultimate AI-powered cyber-integrated personal safety ecosystem. Built to protect, empower, and defend women in any situation.",
      icon: Icons.shield,
      color: Colors.purple,
      badgeText: "AI SAFETY CORE",
    ),
    OnboardingSlideData(
      title: "Emergency SOS System",
      description:
          "Trigger instant multi-channel SOS alerts via voice phrase, hardware buttons, gestures, or app hold countdown with real-time responder dispatch.",
      icon: Icons.emergency,
      color: Colors.red,
      badgeText: "CRITICAL SOS",
    ),
    OnboardingSlideData(
      title: "Smart Walk Guardian",
      description:
          "Real-time path tracking powered by motion anomaly detection. Automatically escalates emergency alerts on sudden running, drops, or off-route detours.",
      icon: Icons.directions_walk,
      color: Colors.teal,
      badgeText: "LIVE TRACKING",
    ),
    OnboardingSlideData(
      title: "Smart Cab Monitoring",
      description:
          "Verify cab license plates, calculate driver safety scores, and receive instant route deviation alerts during ride-sharing trips.",
      icon: Icons.local_taxi,
      color: Colors.amber.shade800,
      badgeText: "TRIP GUARDIAN",
    ),
    OnboardingSlideData(
      title: "Voice SOS Engine",
      description:
          "Activate stealth SOS using custom secret phrases ('capcap') or whisper commands ('Box Box') with offline voice recognition.",
      icon: Icons.mic,
      color: Colors.deepPurple,
      badgeText: "VOICE DETECT",
    ),
    OnboardingSlideData(
      title: "Digital Evidence Locker",
      description:
          "Tamper-proof storage vault securing audio, video, and GPS logs using SHA-256 cryptographic hashes for court-admissible legal evidence.",
      icon: Icons.lock_clock,
      color: Colors.indigo,
      badgeText: "BLOCKCHAIN PROOF",
    ),
    OnboardingSlideData(
      title: "Responder Dashboard",
      description:
          "Direct connection to police dispatchers and medical first responders with high-priority emergency queueing and live GPS telemetry.",
      icon: Icons.local_police,
      color: Colors.blue.shade900,
      badgeText: "POLICE GRID",
    ),
    OnboardingSlideData(
      title: "Cyber Crime Protection",
      description:
          "AI-driven threat detection for cyberstalking, harassment, and blackmail. Instant zero-delay complaint filing to law enforcement.",
      icon: Icons.security,
      color: Colors.redAccent,
      badgeText: "CYBER DEFENSE",
    ),
    OnboardingSlideData(
      title: "Wearable SOS Integration",
      description:
          "Pair smart rings, bands, and pendants via Bluetooth Low Energy for hidden one-touch emergency triggers anytime.",
      icon: Icons.watch_outlined,
      color: Colors.orange.shade800,
      badgeText: "BLE WEARABLES",
    ),
    OnboardingSlideData(
      title: "Guardian Network",
      description:
          "Link trusted family members and friends. Share live tracking, trip progress, and immediate broadcast alerts.",
      icon: Icons.people_alt,
      color: Colors.pink,
      badgeText: "TRUST NETWORK",
    ),
    OnboardingSlideData(
      title: "Offline Fallback SOS",
      description:
          "Zero internet coverage? Encrypted SMS payloads and cached GPS coordinates ensure your safety signal reaches help anywhere.",
      icon: Icons.portable_wifi_off,
      color: Colors.blueGrey,
      badgeText: "OFFLINE READY",
    ),
    OnboardingSlideData(
      title: "Setup & Personalization",
      description:
          "Complete your profile, configure biometric verification, customize hardware shortcuts, and enter your emergency network.",
      icon: Icons.tune,
      color: Colors.green.shade700,
      badgeText: "GET STARTED",
    ),
  ];

  void _finishOnboarding() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    db.completeOnboarding();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _slides[_currentPage].color.withValues(alpha: 0.12),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(_slides[_currentPage].icon, color: _slides[_currentPage].color, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "SHE SHIELD",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PageView Slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: slide.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: slide.color.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              slide.badgeText,
                              style: TextStyle(
                                color: slide.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: slide.color.withValues(alpha: 0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: slide.color.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              slide.icon,
                              size: 72,
                              color: slide.color,
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Slide Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? _slides[_currentPage].color
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Navigation Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text("Prev"),
                      )
                    else
                      const SizedBox(width: 80),

                    Text(
                      "${_currentPage + 1} of ${_slides.length}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    if (_currentPage == _slides.length - 1)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _finishOnboarding,
                        child: const Row(
                          children: [
                            Text("Get Started", style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _slides[_currentPage].color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 2,
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
                        child: const Row(
                          children: [
                            Text("Next"),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
