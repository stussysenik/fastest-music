import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/artist_nationality_provider.dart';
import '../../shared_widgets/loading_indicator.dart';
import '../../shared_widgets/error_view.dart';

class ArtistNationalityScreen extends ConsumerWidget {
  const ArtistNationalityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nationalitiesAsync = ref.watch(artistNationalitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artists by Nationality'),
      ),
      body: nationalitiesAsync.when(
        data: (nationalities) {
          // Group artists by country code
          final grouped = <String, List<String>>{};
          for (final entry in nationalities.entries) {
            grouped.putIfAbsent(entry.value, () => []).add(entry.key);
          }

          // Sort by country code
          final sortedCountries = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: sortedCountries.length,
            itemBuilder: (context, index) {
              final code = sortedCountries[index];
              final artists = grouped[code]!..sort();
              final flag = countryCodeToEmoji(code);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          code,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${artists.length})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  ...artists.map(
                    (artist) => ListTile(
                      title: Text(artist),
                      leading: const Icon(Icons.person, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const Divider(),
                ],
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(message: error.toString()),
      ),
    );
  }
}
