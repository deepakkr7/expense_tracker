import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/split_expense_model.dart';
import '../data/repositories/split_expense_repository.dart';

class SplitExpenseProvider with ChangeNotifier {
  final SplitExpenseRepository _repository = SplitExpenseRepository();

  List<SplitExpenseModel> _splitExpenses = [];
  List<SplitExpenseModel> _pendingSplitExpenses = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _splitExpensesSubscription;

  // Getters
  List<SplitExpenseModel> get splitExpenses => _splitExpenses;
  List<SplitExpenseModel> get pendingSplitExpenses => _pendingSplitExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load split expenses
  void loadSplitExpenses(String userId) {
    _splitExpensesSubscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _splitExpensesSubscription = _repository
        .getSplitExpensesStream(userId)
        .listen(
          (expenses) {
            _splitExpenses = expenses;
            _pendingSplitExpenses = expenses.where((exp) {
              return exp.settled.values.any((settled) => !settled);
            }).toList();
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Add split expense
  Future<void> addSplitExpense(SplitExpenseModel splitExpense) async {
    try {
      await _repository.addSplitExpense(splitExpense);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update split expense
  Future<void> updateSplitExpense(SplitExpenseModel splitExpense) async {
    try {
      await _repository.updateSplitExpense(splitExpense);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete split expense
  Future<void> deleteSplitExpense(String userId, String splitExpenseId) async {
    try {
      await _repository.deleteSplitExpense(userId, splitExpenseId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Mark as settled
  Future<void> markAsSettled(
    String userId,
    String splitExpenseId,
    String friendId,
  ) async {
    try {
      await _repository.markAsSettled(userId, splitExpenseId, friendId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Calculate balances (who owes whom)
  Map<String, double> calculateBalances(String userId) {
    final balances = <String, double>{};

    for (final expense in _pendingSplitExpenses) {
      for (final entry in expense.splits.entries) {
        final friendId = entry.key;
        final amount = entry.value;
        final isSettled = expense.settled[friendId] ?? false;

        if (!isSettled) {
          balances[friendId] = (balances[friendId] ?? 0) + amount;
        }
      }
    }

    return balances;
  }

  // Get total owed to user
  double getTotalOwed(String userId) {
    return calculateBalances(userId).values.fold(0.0, (sum, amt) => sum + amt);
  }

  @override
  void dispose() {
    _splitExpensesSubscription?.cancel();
    super.dispose();
  }
}
