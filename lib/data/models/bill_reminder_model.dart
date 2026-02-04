import 'package:equatable/equatable.dart';

enum RecurrenceType { none, weekly, monthly, quarterly, yearly, custom }

class BillReminderModel extends Equatable {
  final String id;
  final String userId;
  final String billName;
  final double amount;
  final String category;
  final DateTime dueDate;
  final RecurrenceType recurrenceType;
  final int? customIntervalDays; // For custom recurrence
  final int reminderDaysBefore; // Days before due date to remind
  final bool isPaid;
  final DateTime? paidDate;
  final String? notes;
  final bool autoCreateExpense; // Auto-create expense when marked paid

  const BillReminderModel({
    required this.id,
    required this.userId,
    required this.billName,
    required this.amount,
    required this.category,
    required this.dueDate,
    this.recurrenceType = RecurrenceType.none,
    this.customIntervalDays,
    this.reminderDaysBefore = 3,
    this.isPaid = false,
    this.paidDate,
    this.notes,
    this.autoCreateExpense = true,
  });

  // Check if bill is overdue
  bool get isOverdue {
    if (isPaid) return false;
    return DateTime.now().isAfter(dueDate);
  }

  // Check if reminder should be shown
  bool get shouldRemind {
    if (isPaid) return false;
    final reminderDate = dueDate.subtract(Duration(days: reminderDaysBefore));
    final now = DateTime.now();
    return now.isAfter(reminderDate) && now.isBefore(dueDate);
  }

  // Get next due date for recurring bills
  DateTime? getNextDueDate() {
    if (recurrenceType == RecurrenceType.none) return null;

    switch (recurrenceType) {
      case RecurrenceType.weekly:
        return dueDate.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        return DateTime(dueDate.year, dueDate.month + 1, dueDate.day);
      case RecurrenceType.quarterly:
        return DateTime(dueDate.year, dueDate.month + 3, dueDate.day);
      case RecurrenceType.yearly:
        return DateTime(dueDate.year + 1, dueDate.month, dueDate.day);
      case RecurrenceType.custom:
        if (customIntervalDays != null) {
          return dueDate.add(Duration(days: customIntervalDays!));
        }
        return null;
      default:
        return null;
    }
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'billName': billName,
      'amount': amount,
      'category': category,
      'dueDate': dueDate.toIso8601String(),
      'recurrenceType': recurrenceType.toString(),
      'customIntervalDays': customIntervalDays,
      'reminderDaysBefore': reminderDaysBefore,
      'isPaid': isPaid,
      'paidDate': paidDate?.toIso8601String(),
      'notes': notes,
      'autoCreateExpense': autoCreateExpense,
    };
  }

  // Create from Firestore map
  factory BillReminderModel.fromMap(Map<String, dynamic> map) {
    return BillReminderModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      billName: map['billName'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.toString() == map['recurrenceType'],
        orElse: () => RecurrenceType.none,
      ),
      customIntervalDays: map['customIntervalDays'] as int?,
      reminderDaysBefore: map['reminderDaysBefore'] as int? ?? 3,
      isPaid: map['isPaid'] as bool? ?? false,
      paidDate: map['paidDate'] != null
          ? DateTime.parse(map['paidDate'] as String)
          : null,
      notes: map['notes'] as String?,
      autoCreateExpense: map['autoCreateExpense'] as bool? ?? true,
    );
  }

  // Copy with method
  BillReminderModel copyWith({
    String? id,
    String? userId,
    String? billName,
    double? amount,
    String? category,
    DateTime? dueDate,
    RecurrenceType? recurrenceType,
    int? customIntervalDays,
    int? reminderDaysBefore,
    bool? isPaid,
    DateTime? paidDate,
    String? notes,
    bool? autoCreateExpense,
  }) {
    return BillReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      billName: billName ?? this.billName,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      notes: notes ?? this.notes,
      autoCreateExpense: autoCreateExpense ?? this.autoCreateExpense,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    billName,
    amount,
    category,
    dueDate,
    recurrenceType,
    customIntervalDays,
    reminderDaysBefore,
    isPaid,
    paidDate,
    notes,
    autoCreateExpense,
  ];
}
