import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/borrowed_money_model.dart';
import '../data/models/expense_model.dart';
import '../data/repositories/borrowed_money_repository.dart';
import '../data/repositories/expense_repository.dart';

class BorrowedMoneyProvider with ChangeNotifier {
  final BorrowedMoneyRepository _repository = BorrowedMoneyRepository();
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final _uuid = const Uuid();

  StreamSubscription<List<BorrowedMoneyModel>>? _subscription;

  List<BorrowedMoneyModel> _borrowedMoney = [];
  Map<String, double> _totalsByPerson = {};
  Map<String, double> _unpaidByPerson = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<BorrowedMoneyModel> get borrowedMoney => _borrowedMoney;
  Map<String, double> get totalsByPerson => _totalsByPerson;
  Map<String, double> get unpaidByPerson => _unpaidByPerson;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Add borrowed money
  Future<void> addBorrowedMoney(BorrowedMoneyModel borrowedMoney) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.addBorrowedMoney(borrowedMoney);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update borrowed money
  Future<void> updateBorrowedMoney(
    BorrowedMoneyModel borrowedMoney, {
    BorrowedMoneyModel? previousState,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Check if transaction changed from unpaid to paid
      final wasUnpaid = previousState != null && !previousState.isPaid;
      final nowPaid = borrowedMoney.isPaid;

      if (wasUnpaid && nowPaid) {
        // Create expense entry for the repayment
        final expense = ExpenseModel(
          id: _uuid.v4(),
          userId: borrowedMoney.userId,
          amount: borrowedMoney.amount,
          category: 'Borrowed Money Repayment',
          description:
              'Repayment to ${borrowedMoney.personName}${borrowedMoney.description != null && borrowedMoney.description!.isNotEmpty ? ' - ${borrowedMoney.description}' : ''}',
          date: borrowedMoney.paidDate ?? DateTime.now(),
          isSplit: false,
        );

        // Add expense before updating borrowed money
        await _expenseRepository.addExpense(expense);
      }

      await _repository.updateBorrowedMoney(borrowedMoney);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete borrowed money
  Future<void> deleteBorrowedMoney(String userId, String id) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.deleteBorrowedMoney(userId, id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Load all borrowed money
  void loadBorrowedMoney(String userId) {
    _subscription?.cancel();

    _subscription = _repository
        .getBorrowedMoneyStream(userId)
        .listen(
          (transactions) {
            _borrowedMoney = transactions;
            _calculateTotals();
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Load unpaid borrowed money
  void loadUnpaidBorrowedMoney(String userId) {
    _subscription?.cancel();

    _subscription = _repository
        .getUnpaidBorrowedMoneyStream(userId)
        .listen(
          (transactions) {
            _borrowedMoney = transactions;
            _calculateTotals();
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Calculate totals by person
  void _calculateTotals() {
    _totalsByPerson = {};
    _unpaidByPerson = {};

    for (var transaction in _borrowedMoney) {
      // Total by person (all transactions)
      _totalsByPerson[transaction.personName] =
          (_totalsByPerson[transaction.personName] ?? 0) + transaction.amount;

      // Unpaid total by person
      if (!transaction.isPaid) {
        _unpaidByPerson[transaction.personName] =
            (_unpaidByPerson[transaction.personName] ?? 0) + transaction.amount;
      }
    }
  }

  // Get transactions for a specific person
  List<BorrowedMoneyModel> getTransactionsForPerson(String personName) {
    return _borrowedMoney.where((t) => t.personName == personName).toList();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
