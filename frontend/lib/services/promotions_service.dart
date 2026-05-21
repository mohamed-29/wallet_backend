import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class PromotionModel {
  final String code;
  final String type;
  final int value;
  final DateTime validUntil;

  PromotionModel({
    required this.code,
    required this.type,
    required this.value,
    required this.validUntil,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      code: json['code'],
      type: json['promo_type'],
      value: json['value'],
      validUntil: DateTime.parse(json['valid_until']),
    );
  }
}

class PromotionsService {
  static const String baseUrl = 'https://fridge.ivend.cloud/api/v1';

  static Future<List<PromotionModel>> fetch() async {
    final token = UserService.token;
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/promotions/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PromotionModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Promotions Fetch Error: $e');
    }
    
    return [];
  }
}
