import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Helper to get user's budgets subcollection
  CollectionReference _getUserBudgetsCollection(String userId) {
    return _firestore
        .collection('expense_tracker')
        .doc('users')
        .collection('users')
        .doc(userId)
        .collection('budgets');
  }

  // Create or update budget
  Future<String> saveBudget(BudgetModel budget) async {
    try {
      String id = budget.id;
      if (id.isEmpty) {
        id = _uuid.v4();
      }

      final budgetWithId = budget.copyWith(id: id);

      await _getUserBudgetsCollection(
        budget.userId,
      ).doc(id).set(budgetWithId.toMap());

      return id;
    } catch (e) {
      throw Exception('Failed to save budget: $e');
    }
  }

  // Get budget for a specific month
  Future<BudgetModel?> getBudgetForMonth(String userId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);

      final snapshot = await _getUserBudgetsCollection(
        userId,
      ).where('month', isEqualTo: startOfMonth.toIso8601String()).get();

      if (snapshot.docs.isNotEmpty) {
        return BudgetModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get budget: $e');
    }
  }

  // Get budget stream
  Stream<BudgetModel?> getBudgetStream(String userId, DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);

    return _getUserBudgetsCollection(userId)
        .where('month', isEqualTo: startOfMonth.toIso8601String())
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return BudgetModel.fromMap(
              snapshot.docs.first.data() as Map<String, dynamic>,
            );
          }
          return null;
        });
  }

  // Generate suggested budget based on income
  Map<String, double> generateSuggestedBudget(
    double monthlyIncome,
    double savingsGoal,
  ) {
    final budgetAmount = monthlyIncome - savingsGoal;

    // Using a simplified 55/45-inspired distribution
    final needs = budgetAmount * 0.55; // 55% for needs
    final wants = budgetAmount * 0.45; // 45% for wants

    return {
      // Needs (55%)
      'Food & Dining': needs * 0.35,
      'Rent/EMI': needs * 0.40,
      'Recharge & Bills': needs * 0.15,
      'Healthcare': needs * 0.10,

      // Wants (45%)
      'Travel & Transport': wants * 0.30,
      'Entertainment': wants * 0.25,
      'Shopping': wants * 0.30,
      'Education': wants * 0.10,
      'Loans': 0.0,
      'Others': wants * 0.05,
    };
  }

  // Delete budget
  Future<void> deleteBudget(String userId, String budgetId) async {
    try {
      await _getUserBudgetsCollection(userId).doc(budgetId).delete();
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }
}
