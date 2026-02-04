import 'package:equatable/equatable.dart';

class BorrowedMoneyModel extends Equatable {
  final String id;
  final String userId;
  final String personName;
  final double amount;
  final DateTime date;
  final String? description;
  final bool isPaid;
  final DateTime? paidDate;

  const BorrowedMoneyModel({
    required this.id,
    required this.userId,
    required this.personName,
    required this.amount,
    required this.date,
    this.description,
    this.isPaid = false,
    this.paidDate,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'personName': personName,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'isPaid': isPaid,
      'paidDate': paidDate?.toIso8601String(),
    };
  }

  // Create from Firestore map
  factory BorrowedMoneyModel.fromMap(Map<String, dynamic> map) {
    return BorrowedMoneyModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      personName: map['personName'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      isPaid: map['isPaid'] as bool? ?? false,
      paidDate: map['paidDate'] != null
          ? DateTime.parse(map['paidDate'] as String)
          : null,
    );
  }

  // Copy with method
  BorrowedMoneyModel copyWith({
    String? id,
    String? userId,
    String? personName,
    double? amount,
    DateTime? date,
    String? description,
    bool? isPaid,
    DateTime? paidDate,
  }) {
    return BorrowedMoneyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    personName,
    amount,
    date,
    description,
    isPaid,
    paidDate,
  ];
}
