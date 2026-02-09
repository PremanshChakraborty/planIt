import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travel_app/pages/day_planner/models/day_plan.dart';
import 'package:travel_app/pages/day_planner/models/plan_block.dart';
import 'package:travel_app/pages/day_planner/models/routes_response.dart';
import 'package:travel_app/pages/day_planner/services/day_plan_service.dart';
import 'package:travel_app/pages/live_trip_page/utils/map_markers.dart';
import 'package:travel_app/models/place_model.dart';

enum TravelMode {
  DRIVE,
  TWO_WHEELER,
}

extension TravelModeX on TravelMode {
  String toJson() => name;

  static TravelMode fromJson(String value) {
    return TravelMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TravelMode.DRIVE, // safe fallback
    );
  }
}

class DayPlanMapProvider extends ChangeNotifier {
  final DayPlanService dayPlanService;
  DayPlan plan;
  final String locationName;
  late final GoogleMapController mapController;
  final ThemeData theme;

  TravelMode travelMode = TravelMode.DRIVE;
  bool isLoading = false;
  String error = '';
  String successMessage = '';
  int? selectedLegIndex;
  final Map<String, GlobalKey> locationKeys = {};
  bool hasCameraFitted = true;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  RoutesResponse? originalRoute;
  RoutesResponse? route;
  Function(String placeId, AddedBy addedBy)? onMarkerTap;

  bool isOptimized = false;
  bool showingOptimized = false;

  DayPlanMapProvider(
      {required this.locationName,
      required this.dayPlanService,
      required this.plan,
      required this.theme});

  Future<void> _getRoute({bool optimized = false}) async {
    try {
      // Store current route as backup if we are optimizing
      if (optimized && route != null) {
        originalRoute = route;
      }

      final newRoute =
          await dayPlanService.getRoute(plan, travelMode, optimized: optimized);

      if (optimized) {
        // Check if the route is actually different
        final indices = newRoute.optimizedIntermediateWaypointIndex;
        if (indices != null && _isSequential(indices)) {
          // Route order hasn't changed
          isOptimized = true;
          originalRoute = null; // Discard backup
        } else {
          print(indices);
          // Route has changed
          showingOptimized = true;
          route = newRoute;
        }
      } else {
        // Normal fetch
        route = newRoute;
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception("Something went wrong. Please try again.");
    }
  }

  bool _isSequential(List<int> indices) {
    for (int i = 0; i < indices.length; i++) {
      if (indices[i] != i) return false;
    }
    return true;
  }

  void revertOptimization() {
    if (originalRoute != null) {
      route = originalRoute;
      originalRoute = null;
      showingOptimized = false;
      isOptimized = false;
      // We also need to update map visuals (polylines, markers) for the reverted route
      // so we call the necessary update methods or trigger a rebuild via notifyListeners
      // typically recalculateRoute logic does this, but here we just swapped data.
      // So we manually trigger the drawing logic.
      _decodePolyline();
      _addMarkers();
      notifyListeners();
      fitCamera();
    }
  }

  Future<void> _decodePolyline() async {
    if (route == null) {
      return;
    }
    final polylinePoints = PolylinePoints();
    for (int i = 0; i < (route!.legs as List).length; ++i) {
      String polyline = route!.legs[i].polyline.encodedPolyline;
      List<PointLatLng> points = polylinePoints.decodePolyline(polyline);
      final polyLine = Polyline(
        consumeTapEvents: true,
        polylineId: PolylineId(i.toString()),
        points: points.map((e) => LatLng(e.latitude, e.longitude)).toList(),
        color: theme.colorScheme.primary,
        width: 3,
        zIndex: 0,
        onTap: () => setSelectedLegIndex(i),
      );
      polylines.add(polyLine);
    }
  }

  Future<void> _addMarkers() async {
    final hotelIcon = await MapMarkers.getHotelMarker(isSelected: false);
    final photographyIcon =
        await MapMarkers.getPhotographyLocationMarker(isSelected: false);
    Set<String> placeIds = {};
    for (var stop in plan.sequence) {
      if (placeIds.contains(stop.placeId)) continue;
      placeIds.add(stop.placeId);
      markers.add(
        Marker(
          markerId: MarkerId(stop.placeId),
          position: LatLng(stop.latitude, stop.longitude),
          icon: stop.type == BlockType.hotel ? hotelIcon : photographyIcon,
          anchor: const Offset(1.0, 0.5),
          infoWindow: InfoWindow(
            title: stop.name,
            snippet: '${stop.rating}⭐ • ${stop.type.name}',
            onTap: () {
              onMarkerTap?.call(stop.placeId, stop.addedBy);
            },
          ),
          onTap: () {
            onMarkerTap?.call(stop.placeId, stop.addedBy);
          },
        ),
      );
    }
  }

  void fitCamera() {
    if (route != null && route!.viewport != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
            route!.viewport!.low.latitude, route!.viewport!.low.longitude),
        northeast: LatLng(
            route!.viewport!.high.latitude, route!.viewport!.high.longitude),
      );
      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        hasCameraFitted = true;
        notifyListeners();
      });
    }
  }

  void setSelectedLegIndex(int index) {
    if (selectedLegIndex == index) {
      return;
    }
    resetSelectedLegIndex();
    selectedLegIndex = index;
    final key = locationKeys['day plan map $index'];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    final Polyline polyline;
    try {
      polyline = polylines
          .firstWhere((e) => e.polylineId.value == selectedLegIndex.toString());
    } catch (e) {
      return;
    }
    polylines.remove(polyline);
    polylines.add(
      Polyline(
        polylineId: PolylineId(selectedLegIndex.toString()),
        points: polyline.points,
        color: theme.colorScheme.secondary,
        width: 4,
        zIndex: 1,
      ),
    );

    // Calculate bounds for the selected leg
    if (polyline.points.isNotEmpty) {
      double minLat = polyline.points.first.latitude;
      double minLng = polyline.points.first.longitude;
      double maxLat = polyline.points.first.latitude;
      double maxLng = polyline.points.first.longitude;

      for (var point in polyline.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }

    notifyListeners();
  }

  void resetSelectedLegIndex() {
    if (selectedLegIndex == null) {
      return;
    }
    int oldIndex = selectedLegIndex!;
    final Polyline polyline;
    try {
      polyline = polylines
          .firstWhere((e) => e.polylineId.value == oldIndex.toString());
    } catch (e) {
      return;
    }
    polylines.remove(polyline);
    polylines.add(Polyline(
        consumeTapEvents: true,
        polylineId: PolylineId(oldIndex.toString()),
        points: polyline.points,
        color: theme.colorScheme.primary,
        width: 3,
        zIndex: 0,
        onTap: () => setSelectedLegIndex(oldIndex)));
    selectedLegIndex = null;
    notifyListeners();
  }

  void onCameraMoved() {
    hasCameraFitted = false;
    notifyListeners();
  }

  void resetSelection() {
    resetSelectedLegIndex();
    fitCamera();
  }

  void clearRoute() {
    route = null;
    markers = {};
    polylines = {};
    hasCameraFitted = false;
    originalRoute = null;
    isOptimized = false;
    showingOptimized = false;
    notifyListeners();
  }

  Future<void> recalculateRoute({bool optimized = false}) async {
    isLoading = true;
    notifyListeners();
    // Only clear route if NOT optimizing, to keep UI stable during optimization fetch
    if (!optimized) {
      clearRoute();
    }
    try {
      await _getRoute(optimized: optimized);
      // If we are showing optimized, we need to refresh map elements for the new route
      // If we are regular fetching, we also do it.
      // The only case we might skip is if optimization returned "no change",
      // but in that case _getRoute didn't update 'route', so these functions
      // will just redraw the same thing, which is fine.
      await _decodePolyline();
      await _addMarkers();
      isLoading = false;
      notifyListeners();
      fitCamera();
    } catch (e) {
      isLoading = false;
      handleError(e.toString());
      // If optimization failed, we might want to revert state?
      // For now, keep it simple.
    }
  }

  Future<void> changeTravelMode(TravelMode mode) async {
    travelMode = mode;
    recalculateRoute();
  }

  void saveOptimization(bool asCopy, String newTitle) async {
    if (asCopy) {
      if (newTitle == plan.planTitle) {
        handleError("Please provide a different title for the new plan");
        return;
      }
    }

    if (route?.optimizedIntermediateWaypointIndex == null) {
      handleError("No optimization data available to save");
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final indices = route!.optimizedIntermediateWaypointIndex!;
      final currentSequence = plan.sequence;
      // Reconstruct sequence
      // Start and End are fixed (first and last elements of current sequence)
      // Intermediate elements (index 1 to length-2) are reordered based on indices
      // indices map the request index (0-based relative to intermediates) to new order

      if (currentSequence.length <= 2) {
        // Should not happen for optimization, but safety check
        handleError("Route too short to optimize");
        isLoading = false;
        notifyListeners();
        return;
      }

      final start = currentSequence.first;
      final end = currentSequence.last;
      final intermediates =
          currentSequence.sublist(1, currentSequence.length - 1);

      List<PlanBlock> newIntermediates =
          List<PlanBlock>.filled(intermediates.length, intermediates[0]);

      // key is new index, value is old index
      // The API documentation says: "The values in this array map the index of the intermediate waypoint in the request to its new index in the optimized route."
      // So if indices[0] = 2, it means the 0th intermediate in request is now at index 2 in optimized result.
      // So newIntermediates[indices[i]] = intermediates[i]

      for (int i = 0; i < indices.length; i++) {
        if (indices[i] < newIntermediates.length) {
          newIntermediates[i] = intermediates[indices[i]];
        }
      }

      final newSequence = [start, ...newIntermediates, end];

      DayPlan planToSave;
      if (asCopy) {
        planToSave = DayPlan(
          id: '', // Backend will generate
          planTitle: newTitle,
          tripId: plan.tripId,
          locationId: plan.locationId,
          day: plan.day,
          sequence: newSequence,
          createdBy: AddedBy(userId: '', userName: ''), // Backend handles
          isStarred: false,
        );
      } else {
        planToSave = plan.copyWith(
          planTitle: newTitle, // Might be same if !asCopy, handled by caller
          sequence: newSequence,
        );
      }

      final savedPlan = await dayPlanService.saveDayPlan(planToSave);

      isLoading = false;
      if (asCopy) revertOptimization(); // Clears showingOptimized
      successMessage = asCopy
          ? "Optimized route saved as separate Plan!"
          : "Route optimized successfully!";

      if (!asCopy) {
        // Update the current plan with the saved (optimized) one
        showingOptimized = false;
        originalRoute = null;
        plan = savedPlan;
        isOptimized = true;
      }

      notifyListeners();
    } catch (e) {
      isLoading = false;
      handleError(e.toString());
    }
  }

  void init(GoogleMapController controller) {
    mapController = controller;
    recalculateRoute();
  }

  void clearError() {
    error = '';
    successMessage = '';
  }

  void handleError(String message) {
    error = message;
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      error = '';
    });
  }
}
