import 'dart:convert';
import 'package:flutter/material.dart';

enum TransactionType { purchase, pointsEarned, pointsRedeemed, topUp, drawdown }

class TransactionModel {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final double pointsDelta;
  final TransactionType type;
  final DateTime date;
  final String machineId;
  final IconData icon;
  final String status; // PAID, COMPLETED, FAILED, REFUNDED, or empty for ledger entries

  const TransactionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.pointsDelta,
    required this.type,
    required this.date,
    required this.machineId,
    required this.icon,
    this.status = '',
  });

  /// Parse a wallet_backend Order object.
  factory TransactionModel.fromOrderJson(Map<String, dynamic> json) {
    final orderStatus = json['status'] as String? ?? 'PAID';
    final amountCents = json['amount_paid_cents'] as int? ?? 0;
    final amount = amountCents / 100.0;
    final machineId = json['machine_id'] as String? ?? '';
    final slot = json['slot'] as String? ?? '';

    String title;
    IconData icon;
    switch (orderStatus) {
      case 'COMPLETED':
        title = 'Purchase Complete';
        icon = Icons.check_circle_rounded;
        break;
      case 'FAILED':
        title = 'Purchase Failed';
        icon = Icons.error_rounded;
        break;
      case 'REFUNDED':
        title = 'Purchase Refunded';
        icon = Icons.replay_rounded;
        break;
      case 'PAID':
        title = 'Waiting for Machine';
        icon = Icons.hourglass_top_rounded;
        break;
      default:
        title = 'Pending';
        icon = Icons.hourglass_empty_rounded;
    }

    return TransactionModel(
      id: json['device_order_id']?.toString() ?? '',
      title: title,
      subtitle: 'Machine $machineId · Slot $slot',
      amount: amount,
      pointsDelta: 0,
      type: TransactionType.purchase,
      date: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      machineId: machineId,
      icon: icon,
      status: orderStatus,
    );
  }

  /// Parse a wallet ledger entry (CREDIT/DEBIT).
  factory TransactionModel.fromBackendJson(Map<String, dynamic> json) {
    final amount = (json['amount_cents'] as int) / 100.0;
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    final reason = metadata['reason'] as String? ?? '';
    final source = metadata['source'] as String? ?? '';
    final description = metadata['description'] as String? ?? '';
    final transactionTypeStr = json['transaction_type'] as String? ?? 'CREDIT';

    String title;
    IconData icon;
    TransactionType txType = TransactionType.topUp;
    String status = 'CREDIT';
    String subtitle = 'Balance added';

    if (transactionTypeStr == 'DEBIT') {
      if (source == 'dashboard_manual_drawdown') {
        title = 'Balance Draw-down';
        icon = Icons.money_off_rounded;
        txType = TransactionType.drawdown;
        status = 'DEBIT';
        subtitle = description.isNotEmpty ? description : 'Manual deduction by Admin';
      } else {
        // Fallback for other potential DEBITs if any
        title = 'Payment';
        icon = Icons.payment_rounded;
        txType = TransactionType.purchase;
        status = 'DEBIT';
        subtitle = 'Wallet charge';
      }
    } else {
      if (reason == 'vend_failed_refund') {
        title = 'Refund';
        icon = Icons.replay_rounded;
        status = 'REFUNDED';
        subtitle = 'Vend failed — auto refund';
      } else {
        title = 'Wallet Top-up';
        icon = Icons.account_balance_wallet_rounded;
      }
    }

    return TransactionModel(
      id: json['timestamp'] as String,
      title: title,
      subtitle: subtitle,
      amount: amount,
      pointsDelta: 0,
      type: txType,
      date: DateTime.parse(json['timestamp'] as String),
      machineId: metadata['machine_id'] as String? ?? '',
      icon: icon,
      status: status,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      amount: (json['amount'] as num).toDouble(),
      pointsDelta: (json['pointsDelta'] as num).toDouble(),
      type: _parseType(json['type'] as String),
      date: DateTime.parse(json['date'] as String),
      machineId: json['machineId'] as String,
      icon: _parseIcon(json['iconType'] as String),
    );
  }

  static TransactionType _parseType(String t) {
    switch (t) {
      case 'pointsEarned':
        return TransactionType.pointsEarned;
      case 'pointsRedeemed':
        return TransactionType.pointsRedeemed;
      case 'topUp':
        return TransactionType.topUp;
      default:
        return TransactionType.purchase;
    }
  }

  static IconData _parseIcon(String key) {
    switch (key) {
      case 'snack':
        return Icons.cookie_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'stars':
        return Icons.stars_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.local_drink_rounded;
    }
  }

  static List<TransactionModel> listFromJson(String source) {
    final list = jsonDecode(source) as List;
    return list
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// Populated at startup from API. Updated on dashboard refresh.
List<TransactionModel> mockTransactions = [];
