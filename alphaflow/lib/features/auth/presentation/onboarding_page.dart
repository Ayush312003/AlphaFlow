import 'package:alphaflow/core/theme/alphaflow_theme.dart';
import 'package:alphaflow/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/common/widgets/generic_glassmorphism_card.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlphaFlowTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: const [
                OnboardingSlide(
                  title: 'Welcome to AlphaFlow',
                  description:
                  'Build discipline. Earn progress. Take control — one task at a time.',
                  image: 'assets/Yoga_Nature.json',
                ),
                OnboardingSlide(
                  title: 'Achieve Your Goals',
                  description:
                  'Follow guided tracks or craft your own. Your journey, your rules.',
                  image: 'assets/Trophy.json',
                ),
                OnboardingSlide(
                  title: 'Master Your Flow',
                  description:
                  'Stay in sync with smart insights, streaks, and real progress.',
                  image: 'assets/Mobile_UI_Onboarding_Animation.json',
                ),
              ],
            ),
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) => buildDot(index, context)),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 40,
              right: 40,
              child: FadeTransition(
                opacity: _animationController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.login, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      elevation: 8,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AlphaFlowTheme.guidedAccentOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      final authService = ref.read(authServiceProvider);
                      authService.signInWithGoogle();
                    },
                    label: Text(
                      'Sign in with Google',
                      style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      height: 8,
      width: _currentPage == index ? 28 : 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _currentPage == index
            ? AlphaFlowTheme.guidedAccentOrange
            : Colors.white.withOpacity(0.3),
      ),
    );
  }
}

class OnboardingSlide extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const OnboardingSlide({
    super.key,
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            image,
            height: 280,
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              fontSize: 18,
              height: 1.4,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}
