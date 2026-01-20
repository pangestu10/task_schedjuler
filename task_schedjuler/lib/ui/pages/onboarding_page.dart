
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingContent {
  final String image;
  final String title;
  final String description;

  OnboardingContent({
    required this.image,
    required this.title,
    required this.description,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      image: 'assets/onboardingscreens/onboarding1.png',
      title: 'Atur Harimu dengan Mudah',
      description: 'Buat jadwal harian yang terstruktur dan prioritas tugas yang jelas untuk produktivitas maksimal.',
    ),
    OnboardingContent(
      image: 'assets/onboardingscreens/onboarding2.png',
      title: 'Fokus Tanpa Gangguan',
      description: 'Gunakan pengatur waktu khusus untuk menjaga konsentrasi dan lacak durasi kerjamu secara akurat.',
    ),
    OnboardingContent(
      image: 'assets/onboardingscreens/onboarding3.png',
      title: 'Wawasan Produktivitas',
      description: 'Pantau perkembanganmu dengan analitik visual dan dapatkan saran cerdas untuk terus berkembang.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image Layer
          PageView.builder(
            controller: _pageController,
            itemCount: _contents.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.asset(
                _contents[index].image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),

          // 2. Gradient Overlay for Readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // 3. Content Layer (Bottom)
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  _contents[_currentPage].title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  _contents[_currentPage].description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page Indicator dots
                    Row(
                      children: List.generate(
                        _contents.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index 
                                ? Colors.blueAccent 
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    // Next / Get Started Button
                    if (_currentPage == _contents.length - 1)
                      ElevatedButton(
                        onPressed: _finishOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Mulai Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Icon(Icons.arrow_forward),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Skip Button (Top Right)
          if (_currentPage != _contents.length - 1)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: _finishOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: const Text('Lewati'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/wrapper');
    }
  }
}
