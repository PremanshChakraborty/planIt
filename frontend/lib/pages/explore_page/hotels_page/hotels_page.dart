// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/auth_provider.dart';
import 'package:travel_app/services/trip_services.dart';
import 'package:travel_app/pages/explore_page/widgets/placeTile.dart';
import '../../../providers/hotels_provider.dart';

class NearbyHotelsPage extends StatelessWidget {
  final PlaceModel place;
  final String? apiKey;
  final String tripId;
  final int locationIndex;
  final String ownerId;

  const NearbyHotelsPage({
    super.key,
    required this.place,
    this.apiKey,
    required this.tripId,
    required this.locationIndex,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HotelsProvider>(
      create: (_) => HotelsProvider(
        place: place,
        apiKey: apiKey,
        tripService:
            TripService(auth: Provider.of<Auth>(context, listen: false)),
        tripId: tripId,
        locationIndex: locationIndex,
        currentUserId: Provider.of<Auth>(context, listen: false).user!.id,
        ownerId: ownerId,
      ),
      child: const _NearbyHotelsView(),
    );
  }
}

class _NearbyHotelsView extends StatefulWidget {
  const _NearbyHotelsView();

  @override
  State<_NearbyHotelsView> createState() => _NearbyHotelsViewState();
}

class _NearbyHotelsViewState extends State<_NearbyHotelsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HotelsProvider>(context);
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
                      hintText: 'Search hotels...',
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
                          provider.fetchNearbyHotels(
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
                    : provider.hotels == null || provider.hotels!.isEmpty
                        ? Center(
                            child: Text('No hotels found.',
                                style: theme.textTheme.bodyMedium))
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: provider.hotels!.length,
                            separatorBuilder: (_, __) => Container(
                              height: 18,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            itemBuilder: (context, index) {
                              final hotel = provider.hotels![index];
                              final isSaved =
                                  provider.isHotelSaved(hotel.placeId);
                              final savedHotelDetails =
                                  provider.getSavedHotelDetails(hotel.placeId);
                              final images =
                                  provider.getHotelImages(hotel.placeId);
                              final isLoadingMore = provider
                                  .isLoadingAdditionalImages(hotel.placeId);
                              final openingHours =
                                  provider.getHotelOpeningHours(hotel.placeId);
                              return PlaceTile(
                                place: hotel,
                                isSaved: isSaved,
                                addedBy: savedHotelDetails?.addedBy,
                                currentUserId: provider.currentUserId,
                                ownerId: provider.ownerId,
                                isHotel: true,
                                onSaveTap: () => provider.toggleSaveHotel(
                                  HotelModel(
                                    placeId: hotel.placeId ?? '',
                                    name: hotel.name ?? '',
                                    image: hotel.photos?.firstOrNull
                                            ?.photoReference ??
                                        '',
                                    rating: hotel.rating ?? 0,
                                    price: 'N/A',
                                    latitude:
                                        hotel.geometry?.location?.lat ?? 0.0,
                                    longitude:
                                        hotel.geometry?.location?.lng ?? 0.0,
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
