import 'package:equatable/equatable.dart';

class ExpenseModel extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final bool isSplit;
  final Map<String, dynamic>? splitDetails;
  final Map<String, dynamic>? ocrData; // OCR extracted data (for reference)

  const ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.isSplit = false,
    this.splitDetails,
    this.ocrData,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'isSplit': isSplit,
      'splitDetails': splitDetails,
      'ocrData': ocrData,
    };
  }

  // Create from Firestore Map
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      isSplit: map['isSplit'] ?? false,
      splitDetails: map['splitDetails'] != null
          ? Map<String, dynamic>.from(map['splitDetails'])
          : null,
      ocrData: map['ocrData'] != null
          ? Map<String, dynamic>.from(map['ocrData'])
          : null,
    );
  }

  // Copy with method
  ExpenseModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    bool? isSplit,
    Map<String, dynamic>? splitDetails,
    Map<String, dynamic>? ocrData,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      isSplit: isSplit ?? this.isSplit,
      splitDetails: splitDetails ?? this.splitDetails,
      ocrData: ocrData ?? this.ocrData,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    amount,
    category,
    description,
    date,
    isSplit,
    splitDetails,
    ocrData,
  ];
}
