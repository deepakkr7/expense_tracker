import 'package:equatable/equatable.dart';

class BudgetModel extends Equatable {
  final String id;
  final String userId;
  final double monthlyIncome;
  final double savingsGoal;
  final Map<String, double> categoryBudgets; // category -> budget amount
  final DateTime month; // First day of the month

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.monthlyIncome,
    required this.savingsGoal,
    required this.categoryBudgets,
    required this.month,
  });

  // Calculate total budget (income - savings)
  double get totalBudget => monthlyIncome - savingsGoal;

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'monthlyIncome': monthlyIncome,
      'savingsGoal': savingsGoal,
      'categoryBudgets': categoryBudgets,
      'month': month.toIso8601String(),
    };
  }

  // Create from Firestore Map
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      monthlyIncome: (map['monthlyIncome'] ?? 0.0).toDouble(),
      savingsGoal: (map['savingsGoal'] ?? 0.0).toDouble(),
      categoryBudgets: Map<String, double>.from(map['categoryBudgets'] ?? {}),
      month: DateTime.parse(map['month']),
    );
  }

  // Copy with method
  BudgetModel copyWith({
    String? id,
    String? userId,
    double? monthlyIncome,
    double? savingsGoal,
    Map<String, double>? categoryBudgets,
    DateTime? month,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      month: month ?? this.month,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    monthlyIncome,
    savingsGoal,
    categoryBudgets,
    month,
  ];
}
