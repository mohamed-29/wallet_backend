import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final Color accent;
  final String time;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    required this.time,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      icon: _parseIcon(json['iconType'] as String),
      accent: _parseAccent(json['accentType'] as String),
      time: json['time'] as String,
      isRead: json['isRead'] as bool,
    );
  }

  factory NotificationModel.fromBackendJson(Map<String, dynamic> json) {
    final title = json['title'] as String;
    final titleLower = title.toLowerCase();

    IconData icon;
    Color accent;

    if (titleLower.contains('payment') || titleLower.contains('paid')) {
      icon = Icons.check_circle_rounded;
      accent = AppColors.success;
    } else if (titleLower.contains('refund')) {
      icon = Icons.replay_rounded;
      accent = AppColors.warning;
    } else if (titleLower.contains('fail')) {
      icon = Icons.error_rounded;
      accent = AppColors.error;
    } else if (titleLower.contains('wallet') || titleLower.contains('top')) {
      icon = Icons.account_balance_wallet_rounded;
      accent = AppColors.success;
    } else {
      icon = Icons.notifications_rounded;
      accent = AppColors.orange;
    }

    // Format time as relative
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    String time;
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inMinutes < 1) {
        time = 'Just now';
      } else if (diff.inMinutes < 60) {
        time = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        time = '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        time = '${diff.inDays}d ago';
      } else {
        time = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
      }
    } else {
      time = '';
    }

    return NotificationModel(
      id: json['id'].toString(),
      title: title,
      body: json['body'] as String,
      icon: icon,
      accent: accent,
      time: time,
      isRead: json['is_read'] as bool,
    );
  }

  static IconData _parseIcon(String key) {
    switch (key) {
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'stars':
        return Icons.stars_rounded;
      case 'local_offer':
        return Icons.local_offer_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'storefront':
        return Icons.storefront_rounded;
      case 'redeem':
        return Icons.redeem_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static Color _parseAccent(String key) {
    switch (key) {
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'error':
        return AppColors.error;
      case 'navy':
        return AppColors.navy;
      default:
        return AppColors.orange;
    }
  }

  static List<NotificationModel> listFromJson(String source) {
    final list = jsonDecode(source) as List;
    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
