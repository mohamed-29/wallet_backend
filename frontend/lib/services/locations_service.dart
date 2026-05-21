import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/vending_location.dart';
import 'user_service.dart';

class LocationsService {
  static Future<List<VendingLocation>> fetch() async {
    try {
      final response = await UserService.authGet('/machine-locations/');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Fetched ${data.length} machines from backend');
        return data.map((json) => VendingLocation.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        debugPrint('Failed to fetch locations: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load locations (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Locations Fetch Error: $e');
      rethrow;
    }
  }
}
