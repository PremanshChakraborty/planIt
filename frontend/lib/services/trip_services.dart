import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/models/trip.dart';
import 'package:travel_app/providers/auth_provider.dart';

import '../config/constants.dart';

class TripService {
  Auth auth;

  TripService({required this.auth});

  Future<void> postTrip(Map<String, dynamic> data) async {
    try {
      String token = auth.token ?? '';
      print(data);
      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/trips'),
        body: jsonEncode(data),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      if (res.statusCode != 201) {
        print(res.body);
        throw Exception('Error ${res.statusCode} : ${res.body}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        print(e);
        throw Exception("Something went wrong. Please try again.");
      }
    }
  }

  Future<List<Trip>> getAllTrips(String token) async {
    List<Trip> trips = [];
    try {
      http.Response res = await http.get(
        Uri.parse('${Constants.uri}/api/trips'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      if (res.statusCode != 200) {
        throw Exception(res.body);
      }
      final body = jsonDecode(res.body);

      // Backend now returns {success: true, trips: [...]}
      List<dynamic> data;
      if (body is Map && body.containsKey('trips')) {
        data = body['trips'];
      } else if (body is List) {
        // Fallback for old format
        data = body;
      } else {
        throw Exception('Unexpected response format');
      }

      for (var entry in data) {
        // Convert user _id to id for User model compatibility and add missing fields
        if (entry['user'] != null) {
          if (entry['user']['_id'] != null) {
            entry['user']['id'] = entry['user']['_id'].toString();
          }
          // Add default values for missing required fields
          if (entry['user']['emergencyContacts'] == null) {
            entry['user']['emergencyContacts'] = [];
          }
          if (entry['user']['phone'] == null) {
            entry['user']['phone'] = null;
          }
        }
        // Convert collaborator _id to id and add missing fields
        if (entry['collaborators'] != null) {
          for (var collab in entry['collaborators']) {
            if (collab['_id'] != null) {
              collab['id'] = collab['_id'].toString();
            }
            // Add default values for missing required fields
            if (collab['emergencyContacts'] == null) {
              collab['emergencyContacts'] = [];
            }
            if (collab['phone'] == null) {
              collab['phone'] = null;
            }
          }
        }
        trips.add(Trip.fromJson(entry));
      }
      return trips;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception("Something went wrong. Please try again.");
      }
    }
  }

  Future<Trip> updateTrip(String id, Map<String, dynamic> data) async {
    try {
      String token = auth.token ?? '';
      http.Response res = await http.put(
        Uri.parse('${Constants.uri}/api/trips/$id'),
        body: jsonEncode(data),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      final body = jsonDecode(res.body);
      if (res.statusCode != 200 || body['success'] != true) {
        throw Exception(body);
      }
      return Trip.fromJson(body['trip']);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      if (e is SocketException) {
        throw Exception("No internet connection");
      } else {
        throw Exception("Something went wrong. Please try again.");
      }
    }
  }

  Future<void> deleteTrip(String id) async {
    try {
      String token = auth.token ?? '';
      http.Response res = await http.delete(
        Uri.parse('${Constants.uri}/api/trips/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      final body = jsonDecode(res.body);
      if (res.statusCode != 200) {
        throw Exception(body);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      if (e is SocketException) {
        throw Exception("No internet connection");
      } else {
        throw Exception("Something went wrong. Please try again.");
      }
    }
  }

  Future<String> addRemoveAttractionToTrip(
      String tripId, AttractionModel attraction, int locationIndex) async {
    try {
      String token = auth.token ?? '';
      http.Response res = await http.patch(
        Uri.parse('${Constants.uri}/api/trips/attraction'),
        body: jsonEncode({
          'tripId': tripId,
          'attraction': attraction.toJson(),
          'locationIndex': locationIndex,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      final body = jsonDecode(res.body);
      if (res.statusCode != 200) {
        throw Exception(body['msg']);
      }
      return body['message'];
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      if (e is SocketException) {
        throw Exception("No internet connection");
      } else {
        throw Exception("Something went wrong. Please try again.");
      }
    }
  }

  Future<String> addRemoveHotelToTrip(
      String tripId, HotelModel hotel, int locationIndex) async {
    try {
      String token = auth.token ?? '';
      http.Response res = await http.patch(
        Uri.parse('${Constants.uri}/api/trips/hotel'),
        body: jsonEncode({
          'tripId': tripId,
          'hotel': hotel.toJson(),
          'locationIndex': locationIndex,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      final body = jsonDecode(res.body);
      if (res.statusCode != 200) {
        throw Exception(body['msg']);
      }
      return body['message'];
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      if (e is SocketException) {
        throw Exception("No internet connection");
      } else {
        throw Exception("Something went wrong. Please try again.");
      }
    }
  }

  Future<Trip> getTrip(String id) async {
    try {
      String token = auth.token ?? '';
      http.Response res = await http.get(
        Uri.parse('${Constants.uri}/api/trips/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      final body = jsonDecode(res.body);
      if (res.statusCode != 200) {
        throw Exception(res.body);
      }

      // Convert user _id to id for User model compatibility and add missing fields
      if (body['user'] != null) {
        if (body['user']['_id'] != null) {
          body['user']['id'] = body['user']['_id'].toString();
        }
        // Add default values for missing required fields
        if (body['user']['emergencyContacts'] == null) {
          body['user']['emergencyContacts'] = [];
        }
        if (body['user']['phone'] == null) {
          body['user']['phone'] = null;
        }
      }
      // Convert collaborator _id to id and add missing fields
      if (body['collaborators'] != null) {
        for (var collab in body['collaborators']) {
          if (collab['_id'] != null) {
            collab['id'] = collab['_id'].toString();
          }
          // Add default values for missing required fields
          if (collab['emergencyContacts'] == null) {
            collab['emergencyContacts'] = [];
          }
          if (collab['phone'] == null) {
            collab['phone'] = null;
          }
        }
      }

      return Trip.fromJson(body);
    } catch (e, stackTrace) {
      if (e is Exception) {
        rethrow;
      }
      if (e is SocketException) {
        throw Exception("No internet connection");
      } else {
        print(stackTrace);
        throw Exception("Something went wrong. Please try again.");
      }
    }
  }

  Future<void> addLocation(String tripId, PlaceModel location) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.uri}/api/trips/$tripId/locations'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': auth.token ?? '',
        },
        body: jsonEncode(location.toJson()),
      );

      if (response.statusCode != 201) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to add location');
      }
    } catch (e) {
      throw Exception('Error adding location: $e');
    }
  }
}
