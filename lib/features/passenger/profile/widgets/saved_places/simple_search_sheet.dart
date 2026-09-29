import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../shared/providers/places_provider.dart';

class SimpleSearchSheet extends ConsumerWidget {
  const SimpleSearchSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(placeSuggestionsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text('Choisir un lieu', style: AppTextStyles.h3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher une adresse...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.primaryDark,
                ),
                filled: true,
                fillColor: context.colors.greyExtraLight.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) =>
                  ref.read(searchQueryProvider.notifier).updateQuery(val),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: suggestionsAsync.when(
                data: (suggestions) => ListView.builder(
                  controller: scrollController,
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final s = suggestions[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.grey,
                      ),
                      title: Text(s.mainText),
                      subtitle: Text(s.secondaryText),
                      onTap: () async {
                        final localDetails = s.localDetails;
                        if (localDetails != null) {
                          Navigator.pop(context, localDetails);
                          return;
                        }
                        final service = ref.read(placesServiceProvider);
                        final details = await service.getPlaceDetails(
                          s.placeId,
                        );
                        if (details != null && context.mounted) {
                          Navigator.pop(context, details);
                        }
                      },
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
