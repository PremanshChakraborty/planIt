import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/pages/day_planner/models/plan_block.dart';

class DayPlan {
  final String id;
  final String planTitle;
  final String tripId;
  final String locationId;
  final int day;
  final List<PlanBlock> sequence;
  final AddedBy createdBy;
  final AddedBy? updatedBy;
  final bool isStarred;

  const DayPlan({
    required this.id,
    required this.planTitle,
    required this.tripId,
    required this.locationId,
    required this.day,
    required this.sequence,
    required this.createdBy,
    this.updatedBy,
    required this.isStarred,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      id: json['_id'],
      tripId: json['tripId'],
      locationId: json['locationId'],
      planTitle: json['planTitle'],
      day: json['day'],
      sequence: List<PlanBlock>.from(
          json['sequence'].map((x) => PlanBlock.fromJson(x))),
      createdBy: AddedBy.fromJson(json['createdBy']),
      updatedBy: json['updatedBy'] == null
          ? null
          : AddedBy.fromJson(json['updatedBy']),
      isStarred: json['isStarred'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'locationId': locationId,
      'planTitle': planTitle,
      'day': day,
      'sequence': List<dynamic>.from(sequence.map((x) => x.toJson())),
      'createdBy': createdBy.toJson(),
      'updatedBy': updatedBy?.toJson(),
      'isStarred': isStarred,
    };
  }

  DayPlan copyWith({
    String? id,
    String? tripId,
    String? locationId,
    String? planTitle,
    int? day,
    List<PlanBlock>? sequence,
    AddedBy? createdBy,
    AddedBy? updatedBy,
    bool? isStarred,
  }) {
    return DayPlan(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      locationId: locationId ?? this.locationId,
      planTitle: planTitle ?? this.planTitle,
      day: day ?? this.day,
      sequence: sequence ?? this.sequence,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}
