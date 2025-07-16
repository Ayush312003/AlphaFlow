import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/features/guided/presentation/guided_home_page.dart';
import 'package:alphaflow/features/custom/presentation/custom_home_page.dart';
import 'package:alphaflow/features/onboarding/presentation/select_mode_page.dart';
import 'package:alphaflow/widgets/navigation_drawer_widget.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/common/widgets/track_card.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';
import 'package:alphaflow/common/widgets/glassmorphism_card.dart';
import 'package:alphaflow/features/guided/presentation/analytics_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(localAppModeProvider);

    // If no app mode is set, show the select mode page
    if (appMode == null) {
      return const SelectModePage();
    }

    // If guided mode but no track selected, show the track selection grid
    if (appMode == AppMode.guided) {
      final selectedTrackId = ref.watch(localSelectedTrackProvider);
      if (selectedTrackId == null) {
        return _buildTrackSelectionPage(context, ref);
      }
    }

    // If we have a valid app mode and track (if guided), show the appropriate home page
    return _buildHomePage(context, ref, appMode);
  }

  Widget _buildTrackSelectionPage(BuildContext context, WidgetRef ref) {
    const Widget drawerWidget = NavigationDrawerWidget();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      drawer: drawerWidget,
      body: _AnimatedTrackSelectionBody(),
    );
  }

  Widget _buildHomePage(BuildContext context, WidgetRef ref, AppMode appMode) {
    const Widget drawerWidget = NavigationDrawerWidget();

    String appBarTitle = "AlphaFlow";
    Widget currentPageBody;

    if (appMode == AppMode.guided) {
      final selectedTrackId = ref.watch(localSelectedTrackProvider);
      final trackAsync = ref.watch(guidedTrackByIdProvider(selectedTrackId!));
      return trackAsync.when(
        data: (track) {
          appBarTitle = track?.title ?? "Guided Mode";
          currentPageBody = const GuidedHomePage();
          return Scaffold(
            backgroundColor: AlphaFlowTheme.background,
            appBar: AppBar(
              title: Text(
                appBarTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AlphaFlowTheme.textPrimary,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.analytics_outlined,
                    color: AlphaFlowTheme.textPrimary,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AnalyticsPage()),
                    );
                  },
                ),
              ],
            ),
            drawer: drawerWidget,
            body: currentPageBody,
          );
        },
        loading: () => Scaffold(
          backgroundColor: AlphaFlowTheme.background,
          appBar: AppBar(
            title: const Text(
              "Guided Mode",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AlphaFlowTheme.textPrimary,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          drawer: drawerWidget,
          body: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFA500), // Orange
            ),
          ),
        ),
        error: (error, stack) => Scaffold(
          backgroundColor: AlphaFlowTheme.background,
          appBar: AppBar(
            title: const Text(
              "Guided Mode",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AlphaFlowTheme.textPrimary,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          drawer: drawerWidget,
          body: Center(child: Text("Error loading track: $error")),
        ),
      );
    } else if (appMode == AppMode.custom) {
      appBarTitle = "Custom Mode";
      currentPageBody = const CustomHomePage();
    } else {
      currentPageBody = const Center(child: Text("Unknown app mode", style: TextStyle(fontSize: 16)));
    }

    return Scaffold(
      backgroundColor: AlphaFlowTheme.background,
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AlphaFlowTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: drawerWidget,
      body: currentPageBody,
    );
  }
}

class _AnimatedTrackSelectionBody extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AnimatedTrackSelectionBody> createState() => _AnimatedTrackSelectionBodyState();
}

class _AnimatedTrackSelectionBodyState extends ConsumerState<_AnimatedTrackSelectionBody> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sora = GoogleFonts.sora().fontFamily;
    final Color orange = const Color(0xFFFFA500);
    final Color white = Colors.white;
    final Color secondary = const Color(0xFFCCCCCC);
    final tracksAsync = ref.watch(guidedTracksProvider);

    return Stack(
      children: [
        // Glassmorphic background overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              backgroundBlendMode: BlendMode.overlay,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        SafeArea(
          child: tracksAsync.when(
            data: (tracks) {
              if (tracks.isEmpty) {
                return const TrackSelectionEmptyState();
              }
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                        'Choose Your Track',
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
                        'Discover tracks designed to help you grow and build discipline.',
                        style: TextStyle(
                          color: secondary,
                          fontFamily: sora,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Animated Track Cards
                      ...List.generate(tracks.length, (index) {
                        final track = tracks[index];
                        final isSelected = _selectedIndex == index;
                        final animation = Tween<Offset>(
                          begin: Offset(0, 0.2 + index * 0.05),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _controller,
                          curve: Interval(
                            0.1 * index,
                            0.6 + 0.1 * index,
                            curve: Curves.easeOutCubic,
                          ),
                        ));
                        final fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
                          parent: _controller,
                          curve: Interval(
                            0.1 * index,
                            0.7 + 0.1 * index,
                            curve: Curves.easeIn,
                          ),
                        ));
                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Opacity(
                              opacity: fade.value,
                              child: Transform.translate(
                                offset: animation.value * 40,
                                child: child,
                              ),
                            );
                          },
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedIndex = index);
                              Future.delayed(const Duration(milliseconds: 120), () {
                                ref.read(selectedTrackNotifierProvider.notifier).setSelectedTrack(track.id);
                              });
                            },
                            child: AnimatedScale(
                              scale: isSelected ? 0.97 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              child: PremiumTrackCard(
                                trackId: track.id,
                                title: track.title,
                                subtitle: track.description,
                                levelCount: track.levels.length,
                                isSelected: isSelected,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 40),
                      // Footer
                      Text(
                        'You can switch tracks later in settings.',
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
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFA500),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Something went wrong",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please try again later",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Error: $error",
                      style: TextStyle(
                        color: Colors.red.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
