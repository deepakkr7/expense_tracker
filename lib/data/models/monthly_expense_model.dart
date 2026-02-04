import 'package:equatable/equatable.dart';

class MonthlyExpenseModel extends Equatable {
  final String id;
  final String userId;
  final DateTime month; // First day of the month
  final Map<String, double> categoryExpenses; // category -> amount
  final DateTime createdAt;

  const MonthlyExpenseModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.categoryExpenses,
    required this.createdAt,
  });

  // Calculate total expenses
  double get totalExpenses {
    return categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'month': month.toIso8601String(),
      'categoryExpenses': categoryExpenses,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore Map
  factory MonthlyExpenseModel.fromMap(Map<String, dynamic> map) {
    return MonthlyExpenseModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      month: DateTime.parse(map['month']),
      categoryExpenses: Map<String, double>.from(map['categoryExpenses'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Copy with method
  MonthlyExpenseModel copyWith({
    String? id,
    String? userId,
    DateTime? month,
    Map<String, double>? categoryExpenses,
    DateTime? createdAt,
  }) {
    return MonthlyExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      categoryExpenses: categoryExpenses ?? this.categoryExpenses,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, month, categoryExpenses, createdAt];
}
