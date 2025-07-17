import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectModePage extends ConsumerWidget {
  const SelectModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double cardRadius = 24;
    final Color background = const Color(0xFF0D0D0D);
    final Color cardBg = const Color(0xFF111111).withOpacity(0.9);
    final Color orange = const Color(0xFFFFA500);
    final Color white = Colors.white;
    final Color secondary = const Color(0xFFCCCCCC);
    final sora = GoogleFonts.sora().fontFamily;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Branding
                Text(
                  'AlphaFlow',
                  style: TextStyle(
                    color: secondary.withOpacity(0.7),
                    fontFamily: sora,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Main Heading
                Text(
                  'Select Your Mode',
                  style: TextStyle(
                    color: white,
                    fontFamily: sora,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Tagline
                Text(
                  'AlphaFlow helps you build discipline through focused routines.',
                  style: TextStyle(
                    color: secondary,
                    fontFamily: sora,
                    fontWeight: FontWeight.normal,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Mode Cards
                _ModeCard(
                  title: 'Guided Mode',
                  subtitle: 'Predefined tasks. Earn XP. Level up.',
                  icon: Icons.track_changes_rounded,
                  borderColor: orange,
                  backgroundColor: cardBg,
                  textColor: white,
                  secondaryTextColor: secondary,
                  radius: cardRadius,
                  onTap: () => _selectMode(ref, AppMode.guided, context),
                ),
                const SizedBox(height: 24),
                _ModeCard(
                  title: 'Custom Mode',
                  subtitle: 'Design your own tasks. Build your flow.',
                  icon: Icons.edit_note_rounded,
                  borderColor: orange,
                  backgroundColor: cardBg,
                  textColor: white,
                  secondaryTextColor: secondary,
                  radius: cardRadius,
                  onTap: () => _selectMode(ref, AppMode.custom, context),
                ),
                const SizedBox(height: 40),
                // Footer
                Text(
                  'You can switch later in settings.',
                  style: TextStyle(
                    color: secondary.withOpacity(0.8),
                    fontFamily: sora,
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectMode(WidgetRef ref, AppMode mode, BuildContext context) async {
    final appModeNotifier = ref.read(appModeNotifierProvider.notifier);
    await appModeNotifier.setAppMode(mode);
    ref.invalidate(localAppModeProvider);
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;
  final Color secondaryTextColor;
  final double radius;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.radius,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sora = GoogleFonts.sora().fontFamily;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        focusColor: Colors.white.withOpacity(0.10),
        hoverColor: Colors.white.withOpacity(0.08),
        splashColor: Colors.white.withOpacity(0.12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon (Material only)
              Container(
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(14),
                child: Icon(
                  icon,
                  color: borderColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              // Title
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontFamily: sora,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontFamily: sora,
                  fontWeight: FontWeight.normal,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: borderColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
