import '../../core/utils/money.dart';
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
  final int reminderHour;
  final int reminderMinute;
  final int? recurrenceDay;
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
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.recurrenceDay,
    this.isPaid = false,
    this.paidDate,
    this.notes,
    this.autoCreateExpense = true,
  });

  // Check if bill is overdue
  bool get isOverdue {
    if (isPaid) return false;
    return !DateTime.now().isBefore(
      DateTime(dueDate.year, dueDate.month, dueDate.day + 1),
    );
  }

  // Check if reminder should be shown
  bool get shouldRemind {
    if (isPaid) return false;
    final reminderDate = reminderDateTime;
    final now = DateTime.now();
    return !now.isBefore(reminderDate) &&
        now.isBefore(DateTime(dueDate.year, dueDate.month, dueDate.day + 1));
  }

  DateTime get reminderDateTime => DateTime(
    dueDate.year,
    dueDate.month,
    dueDate.day - reminderDaysBefore,
    reminderHour,
    reminderMinute,
  );

  DateTime _monthDate(int months) {
    final month = DateTime(dueDate.year, dueDate.month + months);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final day = recurrenceDay ?? dueDate.day;
    return DateTime(month.year, month.month, day > lastDay ? lastDay : day);
  }

  // Get next due date for recurring bills
  DateTime? getNextDueDate() {
    if (recurrenceType == RecurrenceType.none) return null;

    switch (recurrenceType) {
      case RecurrenceType.weekly:
        return DateTime(dueDate.year, dueDate.month, dueDate.day + 7);
      case RecurrenceType.monthly:
        return _monthDate(1);
      case RecurrenceType.quarterly:
        return _monthDate(3);
      case RecurrenceType.yearly:
        return _monthDate(12);
      case RecurrenceType.custom:
        if (customIntervalDays != null) {
          return DateTime(
            dueDate.year,
            dueDate.month,
            dueDate.day + customIntervalDays!,
          );
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
      'amount': Money.normalize(amount),
      'amountMinor': Money.minor(amount),
      'category': category,
      'dueDate': dueDate.toIso8601String(),
      'recurrenceType': recurrenceType.toString(),
      'customIntervalDays': customIntervalDays,
      'reminderDaysBefore': reminderDaysBefore,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'recurrenceDay': recurrenceDay ?? dueDate.day,
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
      amount: map['amountMinor'] is int
          ? (map['amountMinor'] as int) / 100
          : Money.normalize(map['amount'] as num),
      category: map['category'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.toString() == map['recurrenceType'],
        orElse: () => RecurrenceType.none,
      ),
      customIntervalDays: map['customIntervalDays'] as int?,
      reminderDaysBefore: map['reminderDaysBefore'] as int? ?? 3,
      reminderHour: map['reminderHour'] as int? ?? 9,
      reminderMinute: map['reminderMinute'] as int? ?? 0,
      recurrenceDay: map['recurrenceDay'] as int?,
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
    int? reminderHour,
    int? reminderMinute,
    int? recurrenceDay,
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
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      recurrenceDay: recurrenceDay ?? this.recurrenceDay ?? this.dueDate.day,
      isPaid: isPaid ?? this.isPaid,
      paidDate: isPaid == false ? null : paidDate ?? this.paidDate,
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
    reminderHour,
    reminderMinute,
    recurrenceDay,
    isPaid,
    paidDate,
    notes,
    autoCreateExpense,
  ];
}
