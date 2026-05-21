import 'package:flutter/material.dart';
import 'transaction_model.dart';
import '../services/user_service.dart';

class User with ChangeNotifier {
  String _name;
  String _phone;
  String _email;
  double _walletBalance;
  double _totalPointsEarned = 0;
  double _totalPointsUsed = 0;
  final String _tier;
  String _avatarInitial;

  User({
    String name = '',
    String phone = '',
    String email = '',
    double walletBalance = 0.0,
    String tier = 'Standard',
    String avatarInitial = '',
  })  : _name = name,
        _phone = phone,
        _email = email,
        _walletBalance = walletBalance,
        _tier = tier,
        _avatarInitial = avatarInitial;

  String get name => _name;
  String get phone => _phone;
  String get email => _email;
  double get walletBalance => _walletBalance;
  double get totalPointsEarned => _totalPointsEarned;
  double get totalPointsUsed => _totalPointsUsed;
  double get availablePoints => _totalPointsEarned - _totalPointsUsed;
  String get tier => _tier;
  String get avatarInitial => _avatarInitial;

  /// Called at startup with data loaded from UserService.
  /// When backend is live, UserService.fetch() returns the same UserData shape.
  void loadFromUserData(UserData data) {
    _name = data.name;
    _phone = data.phone;
    _email = data.email;
    _walletBalance = data.walletBalance;
    _avatarInitial = data.avatarInitial;
    notifyListeners();
  }

  void updateFromTransactions(List<TransactionModel> transactions) {
    double newPointsEarned = 0;
    double newPointsUsed = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.purchase) {
        newPointsEarned += tx.pointsDelta;
      } else if (tx.type == TransactionType.pointsEarned) {
        newPointsEarned += tx.pointsDelta;
      } else if (tx.type == TransactionType.pointsRedeemed) {
        newPointsUsed += tx.pointsDelta.abs();
      }
    }

    if (newPointsEarned != _totalPointsEarned ||
        newPointsUsed != _totalPointsUsed) {
      _totalPointsEarned = newPointsEarned;
      _totalPointsUsed = newPointsUsed;
      notifyListeners();
    }
  }

  void setName(String name) {
    if (name != _name) {
      _name = name;
      notifyListeners();
    }
  }

  void setPhone(String phone) {
    if (phone != _phone) {
      _phone = phone;
      notifyListeners();
    }
  }

  void setBalance(double balance) {
    _walletBalance = balance;
    notifyListeners();
  }

  void addTopUp(double amount) {
    _walletBalance += amount;
    notifyListeners();
  }

  void addPoints(int points) {
    _totalPointsEarned += points;
    notifyListeners();
  }

  void redeemPoints(int points) {
    if (points <= availablePoints) {
      _totalPointsUsed += points;
      notifyListeners();
    }
  }
}

// Global user instance — populated at startup in main().
final User currentUser = User();
