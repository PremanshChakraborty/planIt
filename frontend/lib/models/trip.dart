import 'package:json_annotation/json_annotation.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/models/user.dart';

part 'trip.g.dart';

@JsonSerializable()
class Trip {
  final String id;
  final PlaceModel startLocation;
  final List<PlaceModel> locations;
  final DateTime startDate;
  final int guests;
  final String? budget;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User user; // Trip owner
  final List<User>? collaborators; // List of collaborators
  final bool? isOwner; // Whether current user is the owner

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  Trip({
    required this.id, 
    required this.startLocation, 
    required this.locations, 
    required this.startDate, 
    required this.guests, 
    required this.budget, 
    required this.createdAt, 
    required this.updatedAt,
    required this.user,
    this.collaborators,
    this.isOwner,
  });

  Map<String, dynamic> toJson() => _$TripToJson(this);
}