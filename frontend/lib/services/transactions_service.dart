import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import 'user_service.dart';

class TransactionsService {
  /// Fetches the user's orders and wallet ledger, merges them into a
  /// single activity feed sorted newest-first.
  static Future<List<TransactionModel>> fetch() async {
    if (UserService.token == null) return [];

    try {
      final results = await Future.wait([
        UserService.authGet('/payment/my-orders/'),
        UserService.authGet('/wallet/history/'),
      ]);

      final List<TransactionModel> items = [];

      // Orders (purchases with status)
      if (results[0].statusCode == 200) {
        final List<dynamic> orders = jsonDecode(results[0].body);
        for (final o in orders) {
          items.add(TransactionModel.fromOrderJson(o));
        }
      }

      // Ledger (top-ups / refunds — skip DEBITs since orders cover those)
      if (results[1].statusCode == 200) {
        final List<dynamic> ledger = jsonDecode(results[1].body);
        for (final l in ledger) {
          if (l['transaction_type'] == 'CREDIT') {
            items.add(TransactionModel.fromBackendJson(l));
          }
        }
      }

      // Sort newest first
      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    } catch (e) {
      debugPrint('Transactions Fetch Error: $e');
    }

    return [];
  }
}
