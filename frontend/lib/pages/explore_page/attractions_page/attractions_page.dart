// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/auth_provider.dart';
import 'package:travel_app/services/trip_services.dart';
import 'package:travel_app/pages/explore_page/widgets/placeTile.dart';
import 'package:travel_app/providers/attractions_provider.dart';

class NearbyAttractionsPage extends StatelessWidget {
  final PlaceModel place;
  final String? apiKey;
  final String tripId;
  final int locationIndex;
  final String ownerId;

  const NearbyAttractionsPage({
    super.key,
    required this.place,
    this.apiKey,
    required this.tripId,
    required this.locationIndex,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AttractionsProvider>(
      create: (_) => AttractionsProvider(
        place: place,
        apiKey: apiKey,
        tripService:
            TripService(auth: Provider.of<Auth>(context, listen: false)),
        tripId: tripId,
        locationIndex: locationIndex,
        currentUserId: Provider.of<Auth>(context, listen: false).user!.id,
        ownerId: ownerId,
      ),
      child: const _NearbyAttractionsView(),
    );
  }
}

class _NearbyAttractionsView extends StatefulWidget {
  const _NearbyAttractionsView();

  @override
  State<_NearbyAttractionsView> createState() => _NearbyAttractionsViewState();
}

class _NearbyAttractionsViewState extends State<_NearbyAttractionsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttractionsProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: 14.0, right: 14.0, top: 8.0, bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    onTapOutside: (event) => FocusScope.of(context).unfocus(),
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search attractions...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      isDense: true,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          provider.fetchNearbyAttractions(
                              query: _searchController.text.trim());
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withOpacity(0.9),
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(0),
                              right: Radius.circular(9),
                            ),
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Center(
                        child: Text(provider.error!,
                            style: theme.textTheme.bodyMedium))
                    : provider.attractions == null ||
                            provider.attractions!.isEmpty
                        ? Center(
                            child: Text('No attractions found.',
                                style: theme.textTheme.bodyMedium))
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: provider.attractions!.length,
                            separatorBuilder: (_, __) => Container(
                              height: 18,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            itemBuilder: (context, index) {
                              final attraction = provider.attractions![index];
                              final isSaved = provider
                                  .isAttractionSaved(attraction.placeId);
                              final savedAttractionDetails =
                                  provider.getSavedAttractionDetails(
                                      attraction.placeId);
                              final images = provider
                                  .getAttractionImages(attraction.placeId);
                              final isLoadingMore =
                                  provider.isLoadingAdditionalImages(
                                      attraction.placeId);
                              final openingHours =
                                  provider.getAttractionOpeningHours(
                                      attraction.placeId);
                              return PlaceTile(
                                place: attraction,
                                isSaved: isSaved,
                                addedBy: savedAttractionDetails?.addedBy,
                                currentUserId: provider.currentUserId,
                                ownerId: provider.ownerId,
                                isHotel: false,
                                onSaveTap: () => provider.toggleSaveAttraction(
                                  AttractionModel(
                                    placeId: attraction.placeId ?? '',
                                    name: attraction.name ?? '',
                                    image: attraction.photos?.firstOrNull
                                            ?.photoReference ??
                                        '',
                                    rating: attraction.rating ?? 0,
                                    type: attraction.types?.firstOrNull ?? '',
                                    latitude:
                                        attraction.geometry?.location?.lat ??
                                            0.0,
                                    longitude:
                                        attraction.geometry?.location?.lng ??
                                            0.0,
                                  ),
                                  context,
                                ),
                                imageUrls: images,
                                isLoadingMore: isLoadingMore,
                                openingHours: openingHours,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
