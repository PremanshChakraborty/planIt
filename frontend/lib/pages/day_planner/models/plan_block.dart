import 'package:travel_app/models/place_model.dart';

enum BlockType {
  attraction,
  hotel,
}

extension BlockTypeX on BlockType {
  String toJson() => name;

  static BlockType fromJson(String value) {
    return BlockType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BlockType.attraction, // safe fallback
    );
  }
}

class PlanBlock {
  final String placeId;
  final String name;
  final BlockType type;
  final String image;
  final double rating;
  final double latitude;
  final double longitude;
  final AddedBy addedBy;

  PlanBlock({
    required this.placeId,
    required this.name,
    required this.type,
    required this.image,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.addedBy,
  });

  factory PlanBlock.fromJson(Map<String, dynamic> json) {
    return PlanBlock(
      placeId: json['placeId'],
      name: json['name'],
      type: BlockTypeX.fromJson(json['type']),
      image: json['image'],
      rating: (json['rating'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      addedBy: AddedBy.fromJson(json['addedBy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'type': type.name,
      'image': image,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'addedBy': addedBy.toJson(),
    };
  }
}

class BlockList {
  final List<PlanBlock> blocks;

  BlockList({
    required this.blocks,
  });

  factory BlockList.fromJson(Map<String, dynamic> json) {
    return BlockList(
      blocks: List.from(json['blocks'].map((e) => PlanBlock.fromJson(e))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blocks': blocks.map((e) => e.toJson()).toList(),
    };
  }

  factory BlockList.fromPlaceModel(PlaceModel location) {
    final Map<String, PlanBlock> blocksById = {};

    for (final element in location.attractions ?? []) {
      blocksById[element.placeId] = PlanBlock(
        placeId: element.placeId,
        name: element.name,
        type: BlockType.attraction,
        image: element.image,
        rating: element.rating,
        latitude: element.latitude,
        longitude: element.longitude,
        addedBy: element.addedBy!,
      );
    }

    for (final element in location.hotels ?? []) {
      blocksById[element.placeId] = PlanBlock(
        placeId: element.placeId,
        name: element.name,
        type: BlockType.hotel,
        image: element.image,
        rating: element.rating,
        latitude: element.latitude,
        longitude: element.longitude,
        addedBy: element.addedBy!,
      );
    }

    return BlockList(
      blocks: blocksById.values.toList(),
    );
  }
}
