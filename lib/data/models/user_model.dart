import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final double monthlyIncome;
  final double savingsGoal;
  final Map<String, double> budgetLimits;
  final DateTime? lastIncomeSetMonth;
  final DateTime? lastMonthReviewCompleted;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.monthlyIncome = 0.0,
    this.savingsGoal = 0.0,
    this.budgetLimits = const {},
    this.lastIncomeSetMonth,
    this.lastMonthReviewCompleted,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'monthlyIncome': monthlyIncome,
      'savingsGoal': savingsGoal,
      'budgetLimits': budgetLimits,
      'lastIncomeSetMonth': lastIncomeSetMonth?.toIso8601String(),
      'lastMonthReviewCompleted': lastMonthReviewCompleted?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      monthlyIncome: (map['monthlyIncome'] ?? 0.0).toDouble(),
      savingsGoal: (map['savingsGoal'] ?? 0.0).toDouble(),
      budgetLimits: Map<String, double>.from(map['budgetLimits'] ?? {}),
      lastIncomeSetMonth: map['lastIncomeSetMonth'] != null
          ? DateTime.parse(map['lastIncomeSetMonth'])
          : null,
      lastMonthReviewCompleted: map['lastMonthReviewCompleted'] != null
          ? DateTime.parse(map['lastMonthReviewCompleted'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    double? monthlyIncome,
    double? savingsGoal,
    Map<String, double>? budgetLimits,
    DateTime? lastIncomeSetMonth,
    DateTime? lastMonthReviewCompleted,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      budgetLimits: budgetLimits ?? this.budgetLimits,
      lastIncomeSetMonth: lastIncomeSetMonth ?? this.lastIncomeSetMonth,
      lastMonthReviewCompleted:
          lastMonthReviewCompleted ?? this.lastMonthReviewCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    photoUrl,
    monthlyIncome,
    savingsGoal,
    budgetLimits,
    lastIncomeSetMonth,
    lastMonthReviewCompleted,
    createdAt,
  ];
}
