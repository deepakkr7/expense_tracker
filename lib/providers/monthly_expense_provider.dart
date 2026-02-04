import 'package:flutter/foundation.dart';
import '../data/models/monthly_expense_model.dart';
import '../data/repositories/monthly_expense_repository.dart';

class MonthlyExpenseProvider with ChangeNotifier {
  final MonthlyExpenseRepository _repository = MonthlyExpenseRepository();

  MonthlyExpenseModel? _currentMonthlyExpense;
  List<MonthlyExpenseModel> _allMonthlyExpenses = [];
  Map<String, double> _categoryExpenses = {};
  bool _isLoading = false;
  String? _errorMessage;

  MonthlyExpenseModel? get currentMonthlyExpense => _currentMonthlyExpense;
  List<MonthlyExpenseModel> get allMonthlyExpenses => _allMonthlyExpenses;
  Map<String, double> get categoryExpenses => _categoryExpenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Calculate total from category expenses
  double get totalExpenses {
    return _categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);
  }

  // Update category amount
  void updateCategoryAmount(String category, double amount) {
    _categoryExpenses[category] = amount;
    notifyListeners();
  }

  // Save monthly expense
  Future<void> saveMonthlyExpense(String userId, DateTime month) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final monthlyExpense = MonthlyExpenseModel(
        id: _currentMonthlyExpense?.id ?? '',
        userId: userId,
        month: DateTime(month.year, month.month, 1),
        categoryExpenses: Map.from(_categoryExpenses),
        createdAt: DateTime.now(),
      );

      await _repository.saveMonthlyExpense(monthlyExpense);
      _currentMonthlyExpense = monthlyExpense;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Load monthly expense for specific month
  Future<void> loadMonthlyExpense(String userId, DateTime month) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentMonthlyExpense = await _repository.getMonthlyExpense(
        userId,
        month,
      );

      if (_currentMonthlyExpense != null) {
        _categoryExpenses = Map.from(_currentMonthlyExpense!.categoryExpenses);
      } else {
        _categoryExpenses = {};
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Subscribe to monthly expense stream
  void subscribeToMonthlyExpense(String userId, DateTime month) {
    _repository
        .getMonthlyExpenseStream(userId, month)
        .listen(
          (monthlyExpense) {
            _currentMonthlyExpense = monthlyExpense;
            if (monthlyExpense != null) {
              _categoryExpenses = Map.from(monthlyExpense.categoryExpenses);
            }
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Load all monthly expenses
  void loadAllMonthlyExpenses(String userId) {
    _repository
        .getAllMonthlyExpensesStream(userId)
        .listen(
          (expenses) {
            _allMonthlyExpenses = expenses;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Clear category expenses
  void clearCategoryExpenses() {
    _categoryExpenses = {};
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
