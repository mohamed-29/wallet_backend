import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'user_service.dart';

class ApiService {
  static const String baseUrl = 'https://fridge.ivend.cloud/api/v1';

  static Future<bool> payQR({
    required String machineId,
    required String slot,
    required int priceCents,
    String? orderId,
  }) async {
    try {
      debugPrint('payQR: machine=$machineId slot=$slot price=$priceCents orderId=$orderId');

      final response = await UserService.authPost('/payment/pay-qr/', {
        'machine_id': machineId,
        'slot': slot,
        'price_cents': priceCents,
        if (orderId != null && orderId.isNotEmpty) 'device_order_id': orderId,
      });

      debugPrint('payQR response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final body = jsonDecode(response.body);
        debugPrint('payQR error: ${body['error']} | detail: ${body['detail'] ?? 'none'}');
        return false;
      }
    } catch (e) {
      debugPrint('payQR exception: $e');
      return false;
    }
  }
}
