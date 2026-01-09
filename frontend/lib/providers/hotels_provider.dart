import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:travel_app/services/trip_services.dart';
import '../config/constants.dart';
import '../models/place_model.dart';

class HotelsProvider extends ChangeNotifier {
  final PlaceModel place;
  final String? apiKey;
  late GooglePlace _googlePlace;
  final TripService tripService;
  final String tripId;
  final int locationIndex;
  final String currentUserId;
  final String ownerId;

  List<SearchResult>? _hotels;
  bool _loading = true;
  String? _error;
  Map<String, HotelModel> _savedHotels = {};
  final Map<String, List<String>> _hotelImages = {};
  final Map<String, bool> _loadingAdditionalImages = {};
  final Map<String, List<String>?> _hotelOpeningHours = {};

  List<SearchResult>? get hotels => _hotels;
  bool get loading => _loading;
  String? get error => _error;

  HotelsProvider({
    required this.place,
    this.apiKey,
    required this.tripService,
    required this.tripId,
    required this.locationIndex,
    required this.currentUserId,
    required this.ownerId,
  }) {
    _googlePlace = GooglePlace(apiKey ?? Constants.googlePlacesApiKey);
    if (place.hotels != null && place.hotels!.isNotEmpty) {
      for (var hotel in place.hotels!) {
        _savedHotels[hotel.placeId] = hotel;
      }
    }
    fetchNearbyHotels();
  }

  void fetchNearbyHotels({String? query}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _googlePlace.search.getNearBySearch(
        Location(lat: place.latitude, lng: place.longitude),
        50000,
        type: "lodging",
        keyword: (query != null && query.isNotEmpty) ? query : null,
      );
      _hotels = response?.results;
      _loading = false;
      _error = null;
      notifyListeners();
      // Initialize image maps for each hotel
      if (_hotels != null) {
        for (var hotel in _hotels!) {
          if (hotel.placeId != null) {
            _loadingAdditionalImages[hotel.placeId!] = true;
            // Initialize with the first photo if available
            if (hotel.photos != null && hotel.photos!.isNotEmpty) {
              _hotelImages[hotel.placeId!] = [
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${hotel.photos![0].photoReference}&key=${apiKey ?? Constants.googlePlacesApiKey}'
              ];
            } else {
              _hotelImages[hotel.placeId!] = [
                'https://via.placeholder.com/400x200?text=No+Image'
              ];
            }
            _fetchAdditionalImages(hotel.placeId!);
          }
        }
      }
    } catch (e) {
      _loading = false;
      _error = "Failed to fetch hotels.";
      notifyListeners();
    }
  }

  void _fetchAdditionalImages(String placeId) async {
    try {
      final details = await _googlePlace.details.get(placeId);
      if (details != null && details.result != null) {
        // Get photos
        if (details.result!.photos != null) {
          final photos = details.result!.photos!;
          final photoUrls = photos
              .take(5)
              .map((photo) =>
                  'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${photo.photoReference}&key=${apiKey ?? Constants.googlePlacesApiKey}')
              .toList();
          _hotelImages[placeId] = photoUrls;
        }
        // Get opening hours
        if (details.result!.openingHours != null &&
            details.result!.openingHours!.weekdayText != null) {
          _hotelOpeningHours[placeId] =
              details.result!.openingHours!.weekdayText;
        }
        _loadingAdditionalImages[placeId] = false;
        notifyListeners();
      } else {
        _loadingAdditionalImages[placeId] = false;
        notifyListeners();
      }
    } catch (e) {
      _loadingAdditionalImages[placeId] = false;
      notifyListeners();
    }
  }

  void toggleSaveHotel(
    HotelModel hotel,
    BuildContext context,
  ) async {
    try {
      String msg =
          await tripService.addRemoveHotelToTrip(tripId, hotel, locationIndex);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_savedHotels.containsKey(hotel.placeId)) {
      _savedHotels.remove(hotel.placeId);
    } else {
      _savedHotels[hotel.placeId] = hotel;
    }
    notifyListeners();
  }

  bool isHotelSaved(String? hotelId) {
    if (hotelId == null) return false;
    return _savedHotels.containsKey(hotelId);
  }

  HotelModel? getSavedHotelDetails(String? hotelId) {
    if (hotelId == null) return null;
    return _savedHotels[hotelId];
  }

  List<String> getHotelImages(String? hotelId) {
    if (hotelId == null) {
      return [];
    }
    return _hotelImages[hotelId] ?? [];
  }

  bool isLoadingAdditionalImages(String? hotelId) {
    if (hotelId == null) return false;
    return _loadingAdditionalImages[hotelId] ?? false;
  }

  List<String>? getHotelOpeningHours(String? hotelId) {
    if (hotelId == null) return null;
    return _hotelOpeningHours[hotelId];
  }
}
