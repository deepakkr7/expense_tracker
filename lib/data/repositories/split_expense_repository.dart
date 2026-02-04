import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/split_expense_model.dart';

class SplitExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's split expenses collection
  CollectionReference _getUserSplitExpensesCollection(String userId) {
    return _firestore
        .collection('expense_tracker')
        .doc('users')
        .collection('users')
        .doc(userId)
        .collection('split_expenses');
  }

  // Add split expense
  Future<void> addSplitExpense(SplitExpenseModel splitExpense) async {
    try {
      await _getUserSplitExpensesCollection(
        splitExpense.creatorId,
      ).doc(splitExpense.id).set(splitExpense.toMap());
    } catch (e) {
      throw Exception('Failed to add split expense: $e');
    }
  }

  // Update split expense
  Future<void> updateSplitExpense(SplitExpenseModel splitExpense) async {
    try {
      await _getUserSplitExpensesCollection(
        splitExpense.creatorId,
      ).doc(splitExpense.id).update(splitExpense.toMap());
    } catch (e) {
      throw Exception('Failed to update split expense: $e');
    }
  }

  // Delete split expense
  Future<void> deleteSplitExpense(String userId, String splitExpenseId) async {
    try {
      await _getUserSplitExpensesCollection(
        userId,
      ).doc(splitExpenseId).delete();
    } catch (e) {
      throw Exception('Failed to delete split expense: $e');
    }
  }

  // Get split expenses stream
  Stream<List<SplitExpenseModel>> getSplitExpensesStream(String userId) {
    return _getUserSplitExpensesCollection(
      userId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                SplitExpenseModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  // Mark friend's split as settled
  Future<void> markAsSettled(
    String userId,
    String splitExpenseId,
    String friendId,
  ) async {
    try {
      final doc = await _getUserSplitExpensesCollection(
        userId,
      ).doc(splitExpenseId).get();

      if (!doc.exists) {
        throw Exception('Split expense not found');
      }

      final splitExpense = SplitExpenseModel.fromMap(
        doc.data() as Map<String, dynamic>,
      );

      final updatedSettled = Map<String, bool>.from(splitExpense.settled);
      updatedSettled[friendId] = true;

      await _getUserSplitExpensesCollection(
        userId,
      ).doc(splitExpenseId).update({'settled': updatedSettled});
    } catch (e) {
      throw Exception('Failed to mark as settled: $e');
    }
  }

  // Get pending split expenses (not fully settled)
  Stream<List<SplitExpenseModel>> getPendingSplitExpensesStream(String userId) {
    return _getUserSplitExpensesCollection(
      userId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                SplitExpenseModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .where((split) {
            // Check if not all settled
            return split.settled.values.any((isSettled) => !isSettled);
          })
          .toList();
    });
  }
}
