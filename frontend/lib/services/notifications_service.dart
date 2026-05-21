import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'user_service.dart';

class NotificationsService {
  static Future<List<NotificationModel>> fetch() async {
    if (UserService.token == null) return [];

    try {
      final response = await UserService.authGet('/notifications/');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotificationModel.fromBackendJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Notifications Fetch Error: $e');
    }

    return [];
  }

  static Future<void> markRead(int id) async {
    if (UserService.token == null) return;

    try {
      await UserService.authPost('/notifications/$id/mark_read/', {});
    } catch (e) {
      debugPrint('Mark Read Error: $e');
    }
  }
}
