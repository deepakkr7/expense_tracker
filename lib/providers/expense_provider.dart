import 'package:flutter/foundation.dart';
import '../data/models/expense_model.dart';
import '../data/repositories/expense_repository.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseRepository _expenseRepository = ExpenseRepository();

  List<ExpenseModel> _expenses = [];
  Map<String, double> _categoryTotals = {};
  double _monthlyTotal = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  List<ExpenseModel> get expenses => _expenses;
  Map<String, double> get categoryTotals => _categoryTotals;
  double get monthlyTotal => _monthlyTotal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Add expense
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _expenseRepository.addExpense(expense);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update expense
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _expenseRepository.updateExpense(expense);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete expense
  Future<void> deleteExpense(String userId, String expenseId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _expenseRepository.deleteExpense(userId, expenseId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Load user expenses (subscribe to stream)
  void loadUserExpenses(String userId) {
    _expenseRepository
        .getUserExpensesStream(userId)
        .listen(
          (expenses) {
            _expenses = expenses;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Load monthly expenses
  void loadMonthlyExpenses(String userId, DateTime month) {
    _expenseRepository
        .getMonthlyExpensesStream(userId, month)
        .listen(
          (expenses) {
            _expenses = expenses;

            // Calculate category totals
            _categoryTotals = {};
            for (var expense in expenses) {
              _categoryTotals[expense.category] =
                  (_categoryTotals[expense.category] ?? 0) + expense.amount;
            }

            // Calculate monthly total
            _monthlyTotal = expenses.fold(
              0.0,
              (sum, expense) => sum + expense.amount,
            );

            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Load category totals for current month
  Future<void> loadCategoryTotals(String userId, DateTime month) async {
    try {
      _categoryTotals = await _expenseRepository.getCategoryTotals(
        userId,
        month,
      );
      _monthlyTotal = _categoryTotals.values.fold(
        0.0,
        (sum, amount) => sum + amount,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Get expenses for a specific category
  void loadExpensesByCategory(String userId, String category) {
    _expenseRepository
        .getExpensesByCategoryStream(userId, category)
        .listen(
          (expenses) {
            _expenses = expenses;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear expenses
  void clearExpenses() {
    _expenses = [];
    _categoryTotals = {};
    _monthlyTotal = 0.0;
    notifyListeners();
  }
}
