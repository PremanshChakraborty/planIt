class RoutesResponse {
  final String duration;
  final int distanceMeters;
  final RouteViewport? viewport; // Nullable as it might be missing
  final List<RouteLeg> legs;
  final LocalizedValues? localizedValues;
  final String? routeToken;
  final List<int>? optimizedIntermediateWaypointIndex;

  RoutesResponse({
    required this.duration,
    required this.distanceMeters,
    this.viewport,
    required this.legs,
    this.localizedValues,
    this.routeToken,
    this.optimizedIntermediateWaypointIndex,
  });

  factory RoutesResponse.fromJson(Map<String, dynamic> json) {
    return RoutesResponse(
      duration: json['duration'] as String? ?? '',
      distanceMeters: json['distanceMeters'] as int? ?? 0,
      viewport: json['viewport'] != null
          ? RouteViewport.fromJson(json['viewport'])
          : null,
      legs: (json['legs'] as List<dynamic>?)
              ?.map((e) => RouteLeg.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      localizedValues: json['localizedValues'] != null
          ? LocalizedValues.fromJson(json['localizedValues'])
          : null,
      routeToken: json['routeToken'] as String?,
      optimizedIntermediateWaypointIndex:
          (json['optimizedIntermediateWaypointIndex'] as List<dynamic>?)
                  ?.map((e) => e as int)
                  .toList() ??
              (json['intermediateWaypointRequestIndex'] as List<dynamic>?)
                  ?.map((e) => e as int)
                  .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'distanceMeters': distanceMeters,
      if (viewport != null) 'viewport': viewport!.toJson(),
      'legs': legs.map((e) => e.toJson()).toList(),
      if (localizedValues != null) 'localizedValues': localizedValues!.toJson(),
      if (routeToken != null) 'routeToken': routeToken,
      if (optimizedIntermediateWaypointIndex != null)
        'optimizedIntermediateWaypointIndex':
            optimizedIntermediateWaypointIndex,
    };
  }
}

class RouteViewport {
  final LatLngLiteral low;
  final LatLngLiteral high;

  RouteViewport({required this.low, required this.high});

  factory RouteViewport.fromJson(Map<String, dynamic> json) {
    return RouteViewport(
      low: LatLngLiteral.fromJson(json['low'] ?? {}),
      high: LatLngLiteral.fromJson(json['high'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {'low': low.toJson(), 'high': high.toJson()};
}

class LatLngLiteral {
  final double latitude;
  final double longitude;

  LatLngLiteral({required this.latitude, required this.longitude});

  factory LatLngLiteral.fromJson(Map<String, dynamic> json) {
    return LatLngLiteral(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

class RouteLeg {
  final RoutePolyline polyline;
  final int distanceMeters;
  final String duration;
  final LocalizedValues? localizedValues;

  RouteLeg({
    required this.polyline,
    required this.distanceMeters,
    required this.duration,
    this.localizedValues,
  });

  factory RouteLeg.fromJson(Map<String, dynamic> json) {
    return RouteLeg(
      polyline: RoutePolyline.fromJson(json['polyline'] ?? {}),
      distanceMeters: json['distanceMeters'] as int? ?? 0,
      duration: json['duration'] as String? ?? '',
      localizedValues: json['localizedValues'] != null
          ? LocalizedValues.fromJson(json['localizedValues'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'polyline': polyline.toJson(),
      'distanceMeters': distanceMeters,
      'duration': duration,
      if (localizedValues != null) 'localizedValues': localizedValues!.toJson(),
    };
  }
}

class RoutePolyline {
  final String encodedPolyline;

  RoutePolyline({required this.encodedPolyline});

  factory RoutePolyline.fromJson(Map<String, dynamic> json) {
    return RoutePolyline(
      encodedPolyline: json['encodedPolyline'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'encodedPolyline': encodedPolyline};
}

class LocalizedValues {
  final LocalizedText? distance;
  final LocalizedText? duration;
  final LocalizedText? staticDuration;

  LocalizedValues({this.distance, this.duration, this.staticDuration});

  factory LocalizedValues.fromJson(Map<String, dynamic> json) {
    return LocalizedValues(
      distance: json['distance'] != null
          ? LocalizedText.fromJson(json['distance'])
          : null,
      duration: json['duration'] != null
          ? LocalizedText.fromJson(json['duration'])
          : null,
      staticDuration: json['staticDuration'] != null
          ? LocalizedText.fromJson(json['staticDuration'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (distance != null) 'distance': distance!.toJson(),
      if (duration != null) 'duration': duration!.toJson(),
      if (staticDuration != null) 'staticDuration': staticDuration!.toJson(),
    };
  }
}

class LocalizedText {
  final String text;

  LocalizedText({required this.text});

  factory LocalizedText.fromJson(Map<String, dynamic> json) {
    return LocalizedText(
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'text': text};
}
