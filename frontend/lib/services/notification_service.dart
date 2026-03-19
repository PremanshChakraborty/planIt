import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travel_app/config/constants.dart';
import 'package:travel_app/models/notification.dart';
import 'package:travel_app/providers/auth_provider.dart';

class NotificationService {
  final Auth auth;

  NotificationService({required this.auth});

  Future<List<NotificationModel>> fetchNotifications(
      {int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/notifications?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': auth.token ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notificationsJson = data['notifications'] ?? [];
        return notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      throw Exception('Error fetching notifications: $e');
    }
  }
}
