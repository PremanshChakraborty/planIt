import 'package:google_place/google_place.dart';

class PlaceDetails {
  final String placeId;
  final String name;
  final String? vicinity;
  final double? rating;
  final List<String> photoUrls;
  final List<String>? openingHours;
  final bool? openNow;
  final List<String>? types;
  final String? formattedAddress;
  final String? phoneNumber;
  final String? website;

  PlaceDetails({
    required this.placeId,
    required this.name,
    this.vicinity,
    this.rating,
    required this.photoUrls,
    this.openingHours,
    this.openNow,
    this.types,
    this.formattedAddress,
    this.phoneNumber,
    this.website,
  });

  factory PlaceDetails.fromDetailsResult(DetailsResult result, String apiKey) {
    final photoUrls = result.photos != null && result.photos!.isNotEmpty
        ? result.photos!
            .take(10)
            .map((photo) =>
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${photo.photoReference}&key=$apiKey')
            .toList()
        : <String>[];

    return PlaceDetails(
      placeId: result.placeId ?? '',
      name: result.name ?? 'Unknown',
      vicinity: result.vicinity,
      rating: result.rating,
      photoUrls: photoUrls,
      openingHours: result.openingHours?.weekdayText,
      openNow: result.openingHours?.openNow,
      types: result.types,
      formattedAddress: result.formattedAddress,
      phoneNumber: result.formattedPhoneNumber,
      website: result.website,
    );
  }
}
