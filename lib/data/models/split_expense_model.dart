import 'package:equatable/equatable.dart';

class SplitExpenseModel extends Equatable {
  final String id;
  final String expenseId;
  final String creatorId;
  final double totalAmount;
  final String category;
  final String description;
  final DateTime date;
  final Map<String, double> splits; // friendId -> amount
  final Map<String, bool> settled; // friendId -> isSettled

  const SplitExpenseModel({
    required this.id,
    required this.expenseId,
    required this.creatorId,
    required this.totalAmount,
    required this.category,
    required this.description,
    required this.date,
    required this.splits,
    required this.settled,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expenseId': expenseId,
      'creatorId': creatorId,
      'totalAmount': totalAmount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'splits': splits,
      'settled': settled,
    };
  }

  // Create from Firestore Map
  factory SplitExpenseModel.fromMap(Map<String, dynamic> map) {
    return SplitExpenseModel(
      id: map['id'] ?? '',
      expenseId: map['expenseId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      splits: Map<String, double>.from(map['splits'] ?? {}),
      settled: Map<String, bool>.from(map['settled'] ?? {}),
    );
  }

  // Copy with method
  SplitExpenseModel copyWith({
    String? id,
    String? expenseId,
    String? creatorId,
    double? totalAmount,
    String? category,
    String? description,
    DateTime? date,
    Map<String, double>? splits,
    Map<String, bool>? settled,
  }) {
    return SplitExpenseModel(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      creatorId: creatorId ?? this.creatorId,
      totalAmount: totalAmount ?? this.totalAmount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      splits: splits ?? this.splits,
      settled: settled ?? this.settled,
    );
  }

  @override
  List<Object?> get props => [
    id,
    expenseId,
    creatorId,
    totalAmount,
    category,
    description,
    date,
    splits,
    settled,
  ];
}
