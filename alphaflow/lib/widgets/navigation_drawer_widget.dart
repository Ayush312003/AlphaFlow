import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/data/models/guided_track.dart';

class NavigationDrawerWidget extends ConsumerWidget {
  const NavigationDrawerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAppMode = ref.watch(localAppModeProvider);
    final guidedTracksAsync = ref.watch(guidedTracksProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'AlphaFlow Menu',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_accessibility_outlined),
            title: const Text('Custom Mode'),
            selected: currentAppMode == AppMode.custom,
            selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            onTap: () {
              ref.read(appModeNotifierProvider.notifier).setAppMode(AppMode.custom);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              "Guided Tracks",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ),
          guidedTracksAsync.when(
            data: (allGuidedTracks) {
              return Column(
                children: allGuidedTracks.map((track) {
                  final isSelectedTrack = ref.watch(localAppModeProvider) == AppMode.guided &&
                                         ref.watch(localSelectedTrackProvider) == track.id;
                  return ListTile(
                    leading: Text(
                      track.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(
                      track.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)
                    ),
                    dense: true,
                    selected: isSelectedTrack,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    onTap: () {
                      ref.read(appModeNotifierProvider.notifier).setAppMode(AppMode.guided);
                      ref.read(selectedTrackNotifierProvider.notifier).setSelectedTrack(track.id);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              );
            },
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading tracks...'),
            ),
            error: (error, stack) => ListTile(
              leading: const Icon(Icons.error),
              title: Text('Error loading tracks: $error'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushNamed(context, '/settings'); // Navigate to settings page
            },
          ),
        ],
      ),
    );
  }
}
