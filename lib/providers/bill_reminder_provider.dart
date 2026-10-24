import 'session_notifier.dart';
import '../data/models/bill_reminder_model.dart';
import '../data/repositories/bill_reminder_repository.dart';
import '../core/services/notification_service.dart';
import 'expense_provider.dart';

class BillReminderProvider extends SessionNotifier {
  final BillReminderRepository _repository = BillReminderRepository();

  List<BillReminderModel> _bills = [];
  List<BillReminderModel> _upcomingBills = [];
  List<BillReminderModel> _overdueBills = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BillReminderModel> get bills => _bills;
  List<BillReminderModel> get upcomingBills => _upcomingBills;
  List<BillReminderModel> get overdueBills => _overdueBills;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get unpaid bills count
  int get unpaidBillsCount => _bills.where((b) => !b.isPaid).length;

  // Get total upcoming bills amount
  double get totalUpcomingAmount =>
      _upcomingBills.fold(0.0, (sum, bill) => sum + bill.amount);

  // Get total overdue amount
  double get totalOverdueAmount =>
      _overdueBills.fold(0.0, (sum, bill) => sum + bill.amount);

  // Add bill reminder
  Future<void> addBillReminder(BillReminderModel bill) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.addBillReminder(bill);
      await _scheduleNotification(bill);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update bill reminder
  Future<void> updateBillReminder(BillReminderModel bill) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.updateBillReminder(bill);
      await _scheduleNotification(bill);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete bill reminder
  Future<void> deleteBillReminder(String userId, String billId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.deleteBillReminder(userId, billId);
      NotificationService().cancelNotification(notificationId(billId));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Mark bill as paid and optionally create expense
  Future<void> markBillAsPaid(
    BillReminderModel bill,
    ExpenseProvider expenseProvider,
    String userId, {
    bool createExpense = true,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final next = await _repository.payBill(
        userId,
        bill.id,
        createExpense: createExpense,
      );
      await _scheduleNotification(bill.copyWith(isPaid: true));
      if (next != null) await _scheduleNotification(next);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Snooze bill (move due date forward)
  Future<void> snoozeBill(BillReminderModel bill, int days) async {
    final snoozedBill = bill.copyWith(
      dueDate: DateTime(
        bill.dueDate.year,
        bill.dueDate.month,
        bill.dueDate.day + days,
      ),
    );
    await updateBillReminder(snoozedBill);
  }

  // Handle notification scheduling
  Future<void> _scheduleNotification(
    BillReminderModel bill, {
    bool requestPermission = true,
  }) async {
    try {
      if (bill.isPaid) {
        await NotificationService().cancelNotification(notificationId(bill.id));
        return;
      }

      final reminderDate = bill.reminderDateTime;
      await NotificationService().cancelNotification(notificationId(bill.id));

      if (reminderDate.isAfter(DateTime.now())) {
        await NotificationService().scheduleBillReminder(
          requestPermission: requestPermission,
          id: notificationId(bill.id),
          title: 'Reminder: ${bill.billName}',
          body:
              '₹${bill.amount.toStringAsFixed(0)} due on ${bill.dueDate.day}/${bill.dueDate.month}/${bill.dueDate.year}',
          scheduledDate: reminderDate,
        );
      } else if (DateTime(
        bill.dueDate.year,
        bill.dueDate.month,
        bill.dueDate.day,
        bill.reminderHour,
        bill.reminderMinute,
      ).isAfter(DateTime.now())) {
        await NotificationService().scheduleBillReminder(
          requestPermission: requestPermission,
          id: notificationId(bill.id),
          title: 'Bill Due: ${bill.billName}',
          body:
              '₹${bill.amount.toStringAsFixed(0)} is due on ${bill.dueDate.day}/${bill.dueDate.month}',
          scheduledDate: DateTime(
            bill.dueDate.year,
            bill.dueDate.month,
            bill.dueDate.day,
            bill.reminderHour,
            bill.reminderMinute,
          ),
        );
      }
    } catch (_) {
      /* Keep a successful data save successful. */
    }
  }

  // Stable IDs survive app restarts.
  static int notificationId(String value) {
    var hash = 2166136261;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 16777619) & 0x7fffffff;
    }
    return hash < 1000 ? hash + 1000 : hash;
  }

  Future<void> refreshReminders() async {
    for (final bill in _bills) {
      await _scheduleNotification(bill, requestPermission: false);
    }
  }

  // Load all bills
  void loadBills(String userId) {
    watch(
      'stream0',
      _repository
          .getBillRemindersStream(userId)
          .listen(
            (bills) {
              _bills = bills;
              refreshReminders();
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = error.toString();
              notifyListeners();
            },
          ),
    );
  }

  // Load unpaid bills
  void loadUnpaidBills(String userId) {
    watch(
      'stream1',
      _repository
          .getUnpaidBillsStream(userId)
          .listen(
            (bills) {
              _bills = bills;
              refreshReminders();
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = error.toString();
              notifyListeners();
            },
          ),
    );
  }

  // Load upcoming bills
  void loadUpcomingBills(String userId) {
    watch(
      'stream2',
      _repository
          .getUpcomingBillsStream(userId)
          .listen(
            (bills) {
              _upcomingBills = bills;
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = error.toString();
              notifyListeners();
            },
          ),
    );
  }

  // Load overdue bills
  void loadOverdueBills(String userId) {
    watch(
      'stream3',
      _repository
          .getOverdueBillsStream(userId)
          .listen(
            (bills) {
              _overdueBills = bills;
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = error.toString();
              notifyListeners();
            },
          ),
    );
  }

  // Get bills grouped by status
  Map<String, List<BillReminderModel>> getBillsByStatus() {
    final upcoming = <BillReminderModel>[];
    final overdue = <BillReminderModel>[];
    final paid = <BillReminderModel>[];

    for (var bill in _bills) {
      if (bill.isPaid) {
        paid.add(bill);
      } else if (bill.isOverdue) {
        overdue.add(bill);
      } else {
        upcoming.add(bill);
      }
    }

    paid.sort((a, b) {
      final dateA = a.paidDate ?? a.dueDate;
      final dateB = b.paidDate ?? b.dueDate;
      return dateB.compareTo(dateA);
    });

    return {'upcoming': upcoming, 'overdue': overdue, 'paid': paid};
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
