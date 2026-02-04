import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Helper to get user's expenses subcollection
  CollectionReference _getUserExpensesCollection(String userId) {
    return _firestore
        .collection('expense_tracker')
        .doc('users')
        .collection('users')
        .doc(userId)
        .collection('expenses');
  }

  // Add expense
  Future<String> addExpense(ExpenseModel expense) async {
    try {
      final id = _uuid.v4();
      final expenseWithId = expense.copyWith(id: id);

      await _getUserExpensesCollection(
        expense.userId,
      ).doc(id).set(expenseWithId.toMap());

      return id;
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  // Update expense
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _getUserExpensesCollection(
        expense.userId,
      ).doc(expense.id).update(expense.toMap());
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  // Delete expense
  Future<void> deleteExpense(String userId, String expenseId) async {
    try {
      await _getUserExpensesCollection(userId).doc(expenseId).delete();
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // Get user's expenses stream
  Stream<List<ExpenseModel>> getUserExpensesStream(String userId) {
    return _getUserExpensesCollection(
      userId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  // Get expenses for a specific month
  Stream<List<ExpenseModel>> getMonthlyExpensesStream(
    String userId,
    DateTime month,
  ) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _getUserExpensesCollection(userId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('date', isLessThanOrEqualTo: endOfMonth.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    ExpenseModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  // Get expenses by category
  Stream<List<ExpenseModel>> getExpensesByCategoryStream(
    String userId,
    String category,
  ) {
    return _getUserExpensesCollection(userId)
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    ExpenseModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  // Get category totals for a month
  Future<Map<String, double>> getCategoryTotals(
    String userId,
    DateTime month,
  ) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final snapshot = await _getUserExpensesCollection(userId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('date', isLessThanOrEqualTo: endOfMonth.toIso8601String())
        .get();

    final Map<String, double> categoryTotals = {};

    for (var doc in snapshot.docs) {
      final expense = ExpenseModel.fromMap(doc.data() as Map<String, dynamic>);
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return categoryTotals;
  }

  // Get total expenses for a month
  Future<double> getMonthlyTotal(String userId, DateTime month) async {
    final categoryTotals = await getCategoryTotals(userId, month);
    return categoryTotals.values.fold<double>(
      0.0,
      (sum, amount) => sum + amount,
    );
  }
}
