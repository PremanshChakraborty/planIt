class PlaceModel {
  final String placeId;
  final String placeName;
  final int day;
  final double latitude;
  final double longitude;
  final List<AttractionModel>? attractions;
  final List<HotelModel>? hotels;
  final AddedBy? addedBy; // Optional, may not be present for startLocation

  PlaceModel({
    required this.placeId,
    required this.placeName,
    required this.day,
    required this.latitude,
    required this.longitude,
    this.attractions,
    this.hotels,
    this.addedBy,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      placeId: json['placeId'] as String,
      placeName: json['placeName'] as String,
      day: json['day'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      attractions: json['attractions'] != null
          ? (json['attractions'] as List)
              .map((e) => AttractionModel.fromJson(e))
              .toList()
          : null,
      hotels: json['hotels'] != null
          ? (json['hotels'] as List).map((e) => HotelModel.fromJson(e)).toList()
          : null,
      addedBy:
          json['addedBy'] != null ? AddedBy.fromJson(json['addedBy']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'placeName': placeName,
      'day': day,
      'latitude': latitude,
      'longitude': longitude,
      'attractions': attractions?.map((e) => e.toJson()).toList(),
      if (hotels != null && hotels!.isNotEmpty)
        'hotels': hotels?.map((e) => e.toJson()).toList(),
      if (addedBy != null) 'addedBy': addedBy!.toJson(),
    };
  }
}

class AddedBy {
  final String userId;
  final String userName;
  final String? imageUrl;

  AddedBy({
    required this.userId,
    required this.userName,
    this.imageUrl,
  });

  factory AddedBy.fromJson(Map<String, dynamic> json) {
    // Handle both old structure (userId, userName) and new populated structure (_id, name)
    return AddedBy(
      userId: (json['_id'] ?? json['userId'])?.toString() ?? '',
      userName: (json['name'] ?? json['userName']) as String? ?? 'Unknown',
      imageUrl: (json['imageUrl'] ?? json['image']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'imageUrl': imageUrl,
    };
  }
}

class AttractionModel {
  final String placeId;
  final String name;
  final String image;
  final double rating;
  final String type;
  final double latitude;
  final double longitude;
  final AddedBy? addedBy; // Optional, may not be present in all responses

  AttractionModel({
    required this.placeId,
    required this.name,
    required this.image,
    required this.rating,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.addedBy,
  });

  factory AttractionModel.fromJson(Map<String, dynamic> json) {
    return AttractionModel(
      placeId: json['placeId'],
      name: json['name'],
      image: json['image'],
      rating: (json['rating'] as num).toDouble(),
      type: json['type'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      addedBy:
          json['addedBy'] != null ? AddedBy.fromJson(json['addedBy']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'image': image,
      'rating': rating,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      if (addedBy != null) 'addedBy': addedBy!.toJson(),
    };
  }
}

class HotelModel {
  final String placeId;
  final String name;
  final String image;
  final String
      price; // backend uses string price, defaults to "N/A" for Google Places
  final double rating;
  final double latitude;
  final double longitude;
  final AddedBy? addedBy; // Optional, may not be present in all responses

  HotelModel({
    required this.placeId,
    required this.name,
    required this.image,
    this.price = 'N/A',
    required this.rating,
    required this.latitude,
    required this.longitude,
    this.addedBy,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      placeId: json['placeId'],
      name: json['name'],
      image: json['image'],
      price: json['price'] ?? 'N/A',
      rating: (json['rating'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      addedBy:
          json['addedBy'] != null ? AddedBy.fromJson(json['addedBy']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'image': image,
      'price': price,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      if (addedBy != null) 'addedBy': addedBy!.toJson(),
    };
  }
}
