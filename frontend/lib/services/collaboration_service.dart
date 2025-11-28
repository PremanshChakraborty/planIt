import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:travel_app/models/user.dart';
import 'package:travel_app/providers/auth_provider.dart';

import '../config/constants.dart';

class CollaborationService {
  late Auth auth;

  CollaborationService({required this.auth}) {
    this.auth = auth;
  }

  Future<List<User>> searchUsers(String query) async {
    try {
      if (query.trim().length < 1) {
        return [];
      }

      String token = auth.token ?? '';
      http.Response res = await http.get(
        Uri.parse('${Constants.uri}/api/collaborations/search-users?query=${Uri.encodeComponent(query.trim())}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );

      if (res.statusCode != 200) {
        throw Exception(res.body);
      }

      final body = jsonDecode(res.body);
      if (body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to search users');
      }

      List<User> users = [];
      if (body['users'] != null) {
        for (var userData in body['users']) {
          // Convert _id to id for User model compatibility
          if (userData['_id'] != null) {
            userData['id'] = userData['_id'].toString();
          }
          // Add default values for missing required fields
          if (userData['emergencyContacts'] == null) {
            userData['emergencyContacts'] = [];
          }
          if (userData['phone'] == null) {
            userData['phone'] = null;
          }
          users.add(User.fromJson(userData));
        }
      }

      return users;
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

  Future<Map<String, dynamic>> addCollaborators(String tripId, List<String> userIds) async {
    try {
      if (userIds.isEmpty) {
        throw Exception('No users selected');
      }

      String token = auth.token ?? '';
      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/collaborations/trips/$tripId/collaborators/add'),
        body: jsonEncode({
          'userIds': userIds,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );

      final body = jsonDecode(res.body);

      if (res.statusCode != 200) {
        throw Exception(body['message'] ?? 'Failed to add collaborators');
      }

      if (body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to add collaborators');
      }

      return {
        'success': true,
        'message': body['message'] ?? 'Collaborators added successfully',
        'count': body['count'] ?? 0,
      };
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

  Future<Map<String, dynamic>> updateCollaborators(String tripId, List<String> collaboratorIds) async {
    try {
      String token = auth.token ?? '';
      http.Response res = await http.put(
        Uri.parse('${Constants.uri}/api/collaborations/trips/$tripId/collaborators'),
        body: jsonEncode({
          'collaboratorIds': collaboratorIds,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );

      final body = jsonDecode(res.body);

      if (res.statusCode != 200) {
        throw Exception(body['message'] ?? 'Failed to update collaborators');
      }

      if (body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to update collaborators');
      }

      return {
        'success': true,
        'message': body['message'] ?? 'Collaborators updated successfully',
      };
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
}

