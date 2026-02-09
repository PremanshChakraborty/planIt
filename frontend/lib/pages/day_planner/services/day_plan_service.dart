import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:travel_app/config/constants.dart';
import 'package:travel_app/models/trip.dart';
import 'package:travel_app/pages/day_planner/models/day_plan.dart';
import 'package:travel_app/pages/day_planner/models/processed_day_plan.dart';
import 'package:travel_app/pages/day_planner/provider/day_plan_map_provider.dart';
import 'package:travel_app/pages/day_planner/models/routes_response.dart';
import 'package:travel_app/providers/auth_provider.dart';

class DayPlanService {
  Auth auth;
  DayPlanService({required this.auth});

  Future<DayPlan> saveDayPlan(DayPlan plan) async {
    try {
      String token = auth.token ?? '';
      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/dayplans/'),
        body: jsonEncode(plan.toJson()),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      final body = jsonDecode(res.body);
      if (res.statusCode != 201 &&
          res.statusCode != 200 ||
          body['success'] != true) {
        throw Exception(body['message']);
      }
      return DayPlan.fromJson(body['dayPlan']);
    } catch (e, stackTrace) {
      if (e is Exception) {
        rethrow;
      }
      if (e is SocketException) {
        throw Exception("No internet connection");
      } else {
        print(e);
        print(stackTrace);
        throw Exception("Something went wrong. Please try again.");
      }
    }
  }

  Future<List<DayPlan>> fetchDayPlans(String tripId) async {
    try {
      String token = auth.token ?? '';
      http.Response res = await http.get(
        Uri.parse('${Constants.uri}/api/dayplans/trip/$tripId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      final body = jsonDecode(res.body);
      if (res.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message']);
      }
      List<DayPlan> dayPlans = [];
      if (body['dayPlans'] != null) {
        dayPlans =
            (body['dayPlans'] as List).map((e) => DayPlan.fromJson(e)).toList();
      }
      return dayPlans;
    } catch (e) {
      if (e is SocketException) {
        throw Exception("No internet connection");
      }
      rethrow;
    }
  }

  Future<List<ProcessedDayPlan>> getProcessedDayPlans(Trip trip) async {
    try {
      // 1. Fetch all day plans for the trip
      final dayPlans = await fetchDayPlans(trip.id);

      List<ProcessedDayPlan> processedList = [];
      DateTime currentLocationStartDate = trip.startDate;

      // 2. Iterate through trip locations to sort and calc dates
      for (var location in trip.locations) {
        // Find plans for this location
        // Note: location.placeId matches dayPlan.locationId
        var locationPlans = dayPlans
            .where((plan) => plan.locationId == location.placeId)
            .toList();

        // Sort by day number within location
        locationPlans.sort((a, b) => a.day.compareTo(b.day));

        for (var plan in locationPlans) {
          // Calculate absolute date
          // plan.day is 1-based index day of the stay
          DateTime absDate =
              currentLocationStartDate.add(Duration(days: plan.day - 1));

          // Find creator image
          String? creatorImg = plan.createdBy.imageUrl;

          processedList.add(ProcessedDayPlan(
            dayPlan: plan,
            absoluteDate: absDate,
            creatorImageUrl: creatorImg,
          ));
        }

        // Advance start date for next location
        currentLocationStartDate =
            currentLocationStartDate.add(Duration(days: location.day));
      }

      return processedList;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDayPlan(String id) async {
    try {
      String token = auth.token ?? '';
      http.Response res = await http.delete(
        Uri.parse('${Constants.uri}/api/dayplans/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      final body = jsonDecode(res.body);
      if (res.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message']);
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception("No internet connection");
      }
      rethrow;
    }
  }

  Future<bool> toggleStar(String id) async {
    try {
      String token = auth.token ?? '';
      http.Response res = await http.patch(
        Uri.parse('${Constants.uri}/api/dayplans/$id/toggle-star'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      final body = jsonDecode(res.body);
      if (res.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message']);
      }
      return body['isStarred'] as bool;
    } catch (e) {
      if (e is SocketException) {
        throw Exception("No internet connection");
      }
      rethrow;
    }
  }

  Future<RoutesResponse> getRoute(DayPlan plan, TravelMode travelMode,
      {bool optimized = false}) async {
    try {
      http.Response res = await http.post(
        Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
        body: jsonEncode({
          "origin": {"placeId": plan.sequence.first.placeId},
          "destination": {"placeId": plan.sequence.last.placeId},
          "intermediates": plan.sequence
              .sublist(1, plan.sequence.length - 1)
              .map((e) => {
                    "placeId": e.placeId,
                    "vehicleStopover": true,
                  })
              .toList(),
          "travelMode": travelMode.name,
          "routingPreference": "TRAFFIC_UNAWARE",
          "computeAlternativeRoutes": false,
          "routeModifiers": {
            "avoidTolls": false,
            "avoidHighways": false,
            "avoidFerries": false
          },
          "languageCode": "en-US",
          "units": "METRIC",
          "optimizeWaypointOrder": optimized,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Goog-Api-Key': Constants.googlePlacesApiKey,
          'X-Goog-FieldMask':
              'routes.duration,routes.distanceMeters,routes.viewport,routes.legs.polyline.encodedPolyline,routes.legs.distanceMeters,routes.legs.duration,routes.localizedValues,routes.legs.localizedValues,routes.routeToken,routes.optimizedIntermediateWaypointIndex',
        },
      );
      final body = jsonDecode(res.body);
      if (body['error'] != null) {
        throw Exception(body['error']['message']);
      }
      return RoutesResponse.fromJson((body['routes'] as List<dynamic>)[0]);
    } catch (e) {
      print(e);
      if (e is SocketException) {
        throw Exception("No internet connection");
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception("Something went wrong. Please try again.");
    }
  }
}
