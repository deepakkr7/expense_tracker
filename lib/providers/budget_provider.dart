import 'package:flutter/foundation.dart';
import '../data/models/budget_model.dart';
import '../data/repositories/budget_repository.dart';
import '../core/services/deepseek_service.dart';
import '../core/constants/app_constants.dart';

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
  Future<void> generateSuggestionsWithDebt(
    double actualIncome,
    double availableLimit,
    double unpaidDebt,
    Map<String, double> upcomingBillsByCategory,
    String debtStrategy,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deepSeekService = DeepSeekService();
      _suggestedBudget = await deepSeekService.generateBudgetPlan(
        income: actualIncome,
        limit: availableLimit,
        debt: unpaidDebt,
        bills: upcomingBillsByCategory,
        categories: AppConstants.expenseCategories,
        debtStrategy: debtStrategy,
      );
    } catch (e) {
      print('AI generation failed, falling back to static logic: $e');
      
      double availableForExpenses = availableLimit;
      
      // Deduct bills
      upcomingBillsByCategory.forEach((category, amount) {
        availableForExpenses -= amount;
      });
      
      if (unpaidDebt > 0) {
        availableForExpenses -= unpaidDebt;
      }

      _suggestedBudget = _budgetRepository.generateSuggestedBudget(
        availableForExpenses < 0 ? 0 : availableForExpenses,
        0, 
      );
      
      if (unpaidDebt > 0) {
        if (debtStrategy == 'aggressive') {
          _suggestedBudget['Debt Repayment'] = unpaidDebt; // Borrowed money
        } else if (debtStrategy == 'balanced') {
          _suggestedBudget['Debt Repayment'] = unpaidDebt > 0 ? (unpaidDebt * 0.5) : 0;
        } else {
          _suggestedBudget['Debt Repayment'] = unpaidDebt > 0 ? (unpaidDebt * 0.1) : 0;
        }
      }
      
      // Assign explicitly categorized bills
      upcomingBillsByCategory.forEach((category, amount) {
        _suggestedBudget[category] = amount;
      });
    }

    _isLoading = false;
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
