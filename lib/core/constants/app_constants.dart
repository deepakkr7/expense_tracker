import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'SpendWise';
  static const String appVersion = '1.0.0';

  // Expense Categories
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Travel & Transport',
    'Rent/EMI',
    'Entertainment',
    'Loans',
    'Recharge & Bills',
    'Shopping',
    'Healthcare',
    'Education',
    'Others',
  ];

  // Category Icons
  static const Map<String, IconData> categoryIcons = {
    'Food & Dining': Icons.restaurant,
    'Travel & Transport': Icons.directions_car,
    'Rent/EMI': Icons.home,
    'Entertainment': Icons.movie,
    'Loans': Icons.account_balance,
    'Recharge & Bills': Icons.receipt,
    'Shopping': Icons.shopping_bag,
    'Healthcare': Icons.local_hospital,
    'Education': Icons.school,
    'Others': Icons.category,
  };

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'Food & Dining': Color(0xFFFF6B6B),
    'Travel & Transport': Color(0xFF4ECDC4),
    'Rent/EMI': Color(0xFF95E1D3),
    'Entertainment': Color(0xFFF38181),
    'Loans': Color(0xFFAA96DA),
    'Recharge & Bills': Color(0xFFFCBF49),
    'Shopping': Color(0xFFEE6C4D),
    'Healthcare': Color(0xFF06FFA5),
    'Education': Color(0xFF118AB2),
    'Others': Color(0xFF9E9E9E),
  };

  // Budget Allocation Percentages (50/30/20 rule)
  static const double needsPercentage = 0.50; // 50%
  static const double wantsPercentage = 0.30; // 30%
  static const double savingsPercentage = 0.20; // 20%

  // Alert Thresholds
  static const double budgetWarningThreshold = 0.80; // 80%
  static const double budgetDangerThreshold = 0.90; // 90%

  // Firestore Collections
  static const String mainCollection = 'expense_tracker';
  static const String usersCollection = 'users';

  // User Subcollections
  static const String expensesSubcollection = 'expenses';
  static const String budgetsSubcollection = 'budgets';
  static const String friendsSubcollection = 'friends';
  static const String monthlyExpensesSubcollection = 'monthly_expenses';
  static const String splitExpensesSubcollection = 'split_expenses';

  // Shared Preferences Keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserId = 'user_id';
  static const String keyThemeMode = 'theme_mode';
}
