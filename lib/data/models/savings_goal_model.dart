import 'package:equatable/equatable.dart';

class SavingsGoalModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final DateTime createdDate;
  final DateTime? completedDate;
  final bool isCompleted;
  final String category;
  final String? emoji;

  const SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    required this.createdDate,
    this.completedDate,
    this.isCompleted = false,
    required this.category,
    this.emoji,
  });

  // Computed properties
  double get progress {
    if (targetAmount == 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0.0, double.infinity);
  }

  int? get daysRemaining {
    if (targetDate == null) return null;
    final now = DateTime.now();
    return targetDate!.difference(now).inDays;
  }

  double? get suggestedMonthlySaving {
    if (targetDate == null || remainingAmount <= 0) return null;

    final now = DateTime.now();
    final monthsRemaining =
        ((targetDate!.year - now.year) * 12 + targetDate!.month - now.month)
            .clamp(1, double.infinity);

    return remainingAmount / monthsRemaining;
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate?.toIso8601String(),
      'createdDate': createdDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'category': category,
      'emoji': emoji,
    };
  }

  // Create from Firestore map
  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: map['targetDate'] != null
          ? DateTime.parse(map['targetDate'] as String)
          : null,
      createdDate: DateTime.parse(map['createdDate'] as String),
      completedDate: map['completedDate'] != null
          ? DateTime.parse(map['completedDate'] as String)
          : null,
      isCompleted: map['isCompleted'] as bool? ?? false,
      category: map['category'] as String,
      emoji: map['emoji'] as String?,
    );
  }

  // Copy with method
  SavingsGoalModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdDate,
    DateTime? completedDate,
    bool? isCompleted,
    String? category,
    String? emoji,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdDate: createdDate ?? this.createdDate,
      completedDate: completedDate ?? this.completedDate,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    description,
    targetAmount,
    currentAmount,
    targetDate,
    createdDate,
    completedDate,
    isCompleted,
    category,
    emoji,
  ];
}

// Savings goal categories
class SavingsGoalCategories {
  static const String vacation = 'Vacation';
  static const String vehicle = 'Vehicle';
  static const String house = 'House';
  static const String wedding = 'Wedding';
  static const String education = 'Education';
  static const String emergency = 'Emergency Fund';
  static const String gadget = 'Gadget';
  static const String other = 'Other';

  static const List<String> all = [
    vacation,
    vehicle,
    house,
    wedding,
    education,
    emergency,
    gadget,
    other,
  ];

  static const Map<String, String> emojis = {
    vacation: '🏖️',
    vehicle: '🚗',
    house: '🏠',
    wedding: '💍',
    education: '📚',
    emergency: '🚨',
    gadget: '💻',
    other: '🎯',
  };
}
