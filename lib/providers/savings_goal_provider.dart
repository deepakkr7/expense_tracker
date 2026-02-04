import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/savings_goal_model.dart';
import '../data/repositories/savings_goal_repository.dart';

class SavingsGoalProvider with ChangeNotifier {
  final SavingsGoalRepository _repository = SavingsGoalRepository();

  List<SavingsGoalModel> _goals = [];
  List<SavingsGoalModel> _activeGoals = [];
  List<SavingsGoalModel> _completedGoals = [];

  bool _isLoading = false;
  String? _error;

  StreamSubscription? _goalsSubscription;

  // Getters
  List<SavingsGoalModel> get goals => _goals;
  List<SavingsGoalModel> get activeGoals => _activeGoals;
  List<SavingsGoalModel> get completedGoals => _completedGoals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalSaved {
    return _goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
  }

  double get totalTarget {
    return _activeGoals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
  }

  double get totalProgress {
    if (totalTarget == 0) return 0.0;
    return (totalSaved / totalTarget).clamp(0.0, 1.0);
  }

  // Load all goals
  void loadGoals(String userId) {
    _goalsSubscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _goalsSubscription = _repository
        .getGoalsStream(userId)
        .listen(
          (goals) {
            _goals = goals;
            _activeGoals = goals.where((g) => !g.isCompleted).toList();
            _completedGoals = goals.where((g) => g.isCompleted).toList();
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

  // Add goal
  Future<void> addGoal(SavingsGoalModel goal) async {
    try {
      await _repository.addGoal(goal);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update goal
  Future<void> updateGoal(SavingsGoalModel goal) async {
    try {
      await _repository.updateGoal(goal);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete goal
  Future<void> deleteGoal(String userId, String goalId) async {
    try {
      await _repository.deleteGoal(userId, goalId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Add deposit
  Future<void> addDeposit(String userId, String goalId, double amount) async {
    try {
      await _repository.addDeposit(userId, goalId, amount);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Withdraw from goal
  Future<void> withdrawFromGoal(
    String userId,
    String goalId,
    double amount,
  ) async {
    try {
      await _repository.withdrawFromGoal(userId, goalId, amount);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get goal by ID
  SavingsGoalModel? getGoalById(String goalId) {
    try {
      return _goals.firstWhere((goal) => goal.id == goalId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _goalsSubscription?.cancel();
    super.dispose();
  }
}
