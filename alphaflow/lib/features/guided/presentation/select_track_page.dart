import 'package:alphaflow/features/guided/data/guided_tracks_data.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectTrackPage extends ConsumerWidget {
  const SelectTrackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(guidedTracksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Guided Track'),
      ),
      body: tracks.isEmpty
          ? const Center(child: Text("No tracks available."))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Text(
                        track.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(track.title),
                      subtitle: Text(track.description),
                      onTap: () {
                        final selectedTrackNotifier =
                            ref.read(selectedTrackProvider.notifier);
                        selectedTrackNotifier.setSelectedTrack(track.id);
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (route) => false);
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
