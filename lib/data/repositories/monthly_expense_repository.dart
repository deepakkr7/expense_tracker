import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/monthly_expense_model.dart';

class MonthlyExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Helper to get user's monthly_expenses subcollection
  CollectionReference _getUserMonthlyExpensesCollection(String userId) {
    return _firestore
        .collection('expense_tracker')
        .doc('users')
        .collection('users')
        .doc(userId)
        .collection('monthly_expenses');
  }

  // Save monthly expense summary
  Future<String> saveMonthlyExpense(MonthlyExpenseModel monthlyExpense) async {
    try {
      String id = monthlyExpense.id;
      if (id.isEmpty) {
        id = _uuid.v4();
      }

      final expenseWithId = monthlyExpense.copyWith(id: id);

      await _getUserMonthlyExpensesCollection(
        monthlyExpense.userId,
      ).doc(id).set(expenseWithId.toMap());

      return id;
    } catch (e) {
      throw Exception('Failed to save monthly expense: $e');
    }
  }

  // Get monthly expense for a specific month
  Future<MonthlyExpenseModel?> getMonthlyExpense(
    String userId,
    DateTime month,
  ) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);

      final snapshot = await _getUserMonthlyExpensesCollection(
        userId,
      ).where('month', isEqualTo: startOfMonth.toIso8601String()).get();

      if (snapshot.docs.isNotEmpty) {
        return MonthlyExpenseModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get monthly expense: $e');
    }
  }

  // Get monthly expense stream
  Stream<MonthlyExpenseModel?> getMonthlyExpenseStream(
    String userId,
    DateTime month,
  ) {
    final startOfMonth = DateTime(month.year, month.month, 1);

    return _getUserMonthlyExpensesCollection(userId)
        .where('month', isEqualTo: startOfMonth.toIso8601String())
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return MonthlyExpenseModel.fromMap(
              snapshot.docs.first.data() as Map<String, dynamic>,
            );
          }
          return null;
        });
  }

  // Get all monthly expenses for user
  Stream<List<MonthlyExpenseModel>> getAllMonthlyExpensesStream(String userId) {
    return _getUserMonthlyExpensesCollection(
      userId,
    ).orderBy('month', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                MonthlyExpenseModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  // Delete monthly expense
  Future<void> deleteMonthlyExpense(String userId, String id) async {
    try {
      await _getUserMonthlyExpensesCollection(userId).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete monthly expense: $e');
    }
  }
}
