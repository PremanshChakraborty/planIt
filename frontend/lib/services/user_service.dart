import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travel_app/config/constants.dart';
import 'package:travel_app/models/user.dart';
import 'package:travel_app/providers/auth_provider.dart';

class UserService {
  final Auth auth;

  UserService({required this.auth});

  Future<User> getUserById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': auth.token ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return User.fromJson(data['user']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch user');
        }
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to fetch user details');
      }
    } catch (e, stackTrace) {
      print(stackTrace);
      throw Exception('Error fetching user: $e');
    }
  }
}
