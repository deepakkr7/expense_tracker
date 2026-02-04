import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/bill_reminder_model.dart';
import '../data/models/expense_model.dart';
import '../data/repositories/bill_reminder_repository.dart';
import 'expense_provider.dart';

class BillReminderProvider with ChangeNotifier {
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

      // Mark bill as paid
      final updatedBill = bill.copyWith(isPaid: true, paidDate: DateTime.now());
      await updateBillReminder(updatedBill);

      // Create expense if enabled
      if (createExpense && bill.autoCreateExpense) {
        final expense = ExpenseModel(
          id: const Uuid().v4(),
          userId: userId,
          amount: bill.amount,
          category: bill.category,
          description: '${bill.billName} (Bill Payment)',
          date: DateTime.now(),
        );
        await expenseProvider.addExpense(expense);
      }

      // Create next recurring bill if applicable
      if (bill.recurrenceType != RecurrenceType.none) {
        final nextDueDate = bill.getNextDueDate();
        if (nextDueDate != null) {
          final nextBill = bill.copyWith(
            id: const Uuid().v4(),
            dueDate: nextDueDate,
            isPaid: false,
            paidDate: null,
          );
          await addBillReminder(nextBill);
        }
      }

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
      dueDate: bill.dueDate.add(Duration(days: days)),
    );
    await updateBillReminder(snoozedBill);
  }

  // Load all bills
  void loadBills(String userId) {
    _repository
        .getBillRemindersStream(userId)
        .listen(
          (bills) {
            _bills = bills;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Load unpaid bills
  void loadUnpaidBills(String userId) {
    _repository
        .getUnpaidBillsStream(userId)
        .listen(
          (bills) {
            _bills = bills;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Load upcoming bills
  void loadUpcomingBills(String userId) {
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
        );
  }

  // Load overdue bills
  void loadOverdueBills(String userId) {
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

    return {'upcoming': upcoming, 'overdue': overdue, 'paid': paid};
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
