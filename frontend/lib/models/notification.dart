class NotificationModel {
  final String id;
  final String userId;
  final String tripId;
  final String type;
  final String actorId;
  final String message;
  final bool read;
  final DateTime createdAt;
  final String? tripName;
  final String? actorName;
  final String? actorImageUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.type,
    required this.actorId,
    required this.message,
    required this.read,
    required this.createdAt,
    this.tripName,
    this.actorName,
    this.actorImageUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'],
      userId: json['userId'] ?? '',
      tripId: json['tripId'] is Map
          ? (json['tripId']['_id'] ?? '')
          : (json['tripId'] ?? ''),
      type: json['type'] ?? '',
      actorId: json['actorId'] is Map
          ? (json['actorId']['_id'] ?? '')
          : (json['actorId'] ?? ''),
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      tripName: json['tripId'] is Map && json['tripId']['startLocation'] != null
          ? json['tripId']['startLocation']['placeName']
          : null,
      actorName: json['actorId'] != null && json['actorId'] is Map
          ? json['actorId']['name']
          : null,
      actorImageUrl: json['actorId'] != null && json['actorId'] is Map
          ? json['actorId']['imageUrl']
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'tripId': tripId,
      'type': type,
      'actorId': actorId,
      'message': message,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
