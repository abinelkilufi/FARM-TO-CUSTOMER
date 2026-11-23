import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Farm to Table';
  static const String appTagline =
      'Fresh green vegetables, straight from the farm to you.';

  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color secondaryColor = Color(0xFF66BB6A);
  static const Color accentColor = Color(0xFFFFA000);
  static const Color backgroundColor = Color(0xFFF5F7F3);
  static const Color textDark = Color(0xFF1B1B1B);
  static const Color textLight = Color(0xFF6B6B6B);
  static const Color errorColor = Color(0xFFD32F2F);

  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';

  static const List<String> productUnits = ['kg', 'bunch', 'piece', 'crate'];

  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
}
