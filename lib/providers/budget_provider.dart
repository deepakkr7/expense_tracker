import 'package:flutter/foundation.dart';
import '../data/models/budget_model.dart';
import '../data/repositories/budget_repository.dart';

class BudgetProvider with ChangeNotifier {
  final BudgetRepository _budgetRepository = BudgetRepository();

  BudgetModel? _currentBudget;
  Map<String, double> _suggestedBudget = {};
  bool _isLoading = false;
  String? _errorMessage;

  BudgetModel? get currentBudget => _currentBudget;
  Map<String, double> get suggestedBudget => _suggestedBudget;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Save budget
  Future<void> saveBudget(BudgetModel budget) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _budgetRepository.saveBudget(budget);
      _currentBudget = budget;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Load budget for specific month
  Future<void> loadBudget(String userId, DateTime month) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentBudget = await _budgetRepository.getBudgetForMonth(userId, month);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Subscribe to budget stream
  void subscribeToBudget(String userId, DateTime month) {
    _budgetRepository
        .getBudgetStream(userId, month)
        .listen(
          (budget) {
            _currentBudget = budget;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Get budget for specific month (direct call, not stream)
  Future<BudgetModel?> getBudgetForMonth(String userId, DateTime month) async {
    return await _budgetRepository.getBudgetForMonth(userId, month);
  }

  // Delete budget
  Future<void> deleteBudget(String userId, String budgetId) async {
    try {
      await _budgetRepository.deleteBudget(userId, budgetId);
      if (_currentBudget?.id == budgetId) {
        _currentBudget = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Generate suggested budget
  void generateSuggestions(double monthlyIncome, double savingsGoal) {
    _suggestedBudget = _budgetRepository.generateSuggestedBudget(
      monthlyIncome,
      savingsGoal,
    );
    notifyListeners();
  }

  // Generate suggested budget with debt awareness
  void generateSuggestionsWithDebt(
    double monthlyIncome,
    double savingsGoal,
    double unpaidDebt,
  ) {
    // If there's significant debt (>10% of income), adjust budget
    if (unpaidDebt > 0) {
      // Priority allocation: Debt -> Savings -> Expenses
      double availableForExpenses = monthlyIncome - savingsGoal - unpaidDebt;

      // If debt + savings > 70% of income, suggest reducing savings
      if (unpaidDebt + savingsGoal > monthlyIncome * 0.7) {
        savingsGoal = (monthlyIncome * 0.7 - unpaidDebt).clamp(0, savingsGoal);
        availableForExpenses = monthlyIncome - savingsGoal - unpaidDebt;
      }

      // If still not enough, spread debt over 3 months
      if (availableForExpenses < monthlyIncome * 0.3) {
        unpaidDebt = unpaidDebt / 3; // Suggest monthly payment
        availableForExpenses = monthlyIncome - savingsGoal - unpaidDebt;
      }

      // Generate budget with adjusted available amount
      _suggestedBudget = _budgetRepository.generateSuggestedBudget(
        availableForExpenses,
        0, // Savings already accounted for
      );

      // Add debt repayment to budget
      _suggestedBudget['Debt Repayment'] = unpaidDebt;
    } else {
      // No debt, use normal generation
      _suggestedBudget = _budgetRepository.generateSuggestedBudget(
        monthlyIncome,
        savingsGoal,
      );
    }

    notifyListeners();
  }

  // Check if category exceeds budget
  bool isCategoryOverBudget(String category, double spent) {
    if (_currentBudget == null) return false;

    final budgetAmount = _currentBudget!.categoryBudgets[category] ?? 0.0;
    return spent > budgetAmount;
  }

  // Get budget warning level (0-1, where 1 is at/over budget)
  double getBudgetUsagePercentage(String category, double spent) {
    if (_currentBudget == null) return 0.0;

    final budgetAmount = _currentBudget!.categoryBudgets[category] ?? 0.0;
    if (budgetAmount == 0) return 0.0;

    return spent / budgetAmount;
  }

  // Check if any category is over budget (exceeded 100%)
  Map<String, double> getOverBudgetCategories(
    Map<String, double> categoryTotals,
  ) {
    if (_currentBudget == null) return {};

    final Map<String, double> overBudget = {};

    _currentBudget!.categoryBudgets.forEach((category, budgetAmount) {
      final spent = categoryTotals[category] ?? 0.0;
      final percentage = budgetAmount > 0 ? spent / budgetAmount : 0.0;

      // Only show warnings when budget is exceeded (>100%)
      if (percentage > 1.0) {
        overBudget[category] = percentage;
      }
    });

    return overBudget;
  }

  // Check if a category has zero budget allocation
  bool isZeroBudgetCategory(String category) {
    if (_currentBudget == null) return false;

    final budgetAmount = _currentBudget!.categoryBudgets[category] ?? 0.0;
    return budgetAmount == 0.0;
  }

  // Get budget amount for a specific category
  double getCategoryBudget(String category) {
    if (_currentBudget == null) return 0.0;
    return _currentBudget!.categoryBudgets[category] ?? 0.0;
  }

  // Clear budget
  void clearBudget() {
    _currentBudget = null;
    _suggestedBudget = {};
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
