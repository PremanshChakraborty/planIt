import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:travel_app/config/constants.dart';
import 'package:travel_app/pages/day_planner/models/place_details.dart';

class GoogleServicesProvider extends ChangeNotifier {
  late GooglePlace _googlePlace;
  final Map<String, PlaceDetails> _placeDetailsCache = {};

  GoogleServicesProvider() {
    _googlePlace = GooglePlace(Constants.googlePlacesApiKey);
  }

  /// Fetches place details from Google Places API with caching
  /// Returns cached details if available, otherwise fetches from API
  Future<PlaceDetails?> fetchPlaceDetails(String placeId) async {
    // Check cache first
    if (_placeDetailsCache.containsKey(placeId)) {
      return _placeDetailsCache[placeId];
    }

    try {
      final details = await _googlePlace.details.get(placeId);
      if (details != null && details.result != null) {
        final placeDetails = PlaceDetails.fromDetailsResult(
          details.result!,
          Constants.googlePlacesApiKey,
        );
        // Cache the result
        _placeDetailsCache[placeId] = placeDetails;
        notifyListeners(); // Notify listeners just in case, though this method returns a Future
        return placeDetails;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
