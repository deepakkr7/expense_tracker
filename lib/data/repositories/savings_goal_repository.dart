import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/savings_goal_model.dart';

class SavingsGoalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's savings goals collection
  CollectionReference _getUserGoalsCollection(String userId) {
    return _firestore
        .collection('expense_tracker')
        .doc('users')
        .collection('users')
        .doc(userId)
        .collection('savings_goals');
  }

  // Add savings goal
  Future<void> addGoal(SavingsGoalModel goal) async {
    try {
      await _getUserGoalsCollection(goal.userId).doc(goal.id).set(goal.toMap());
    } catch (e) {
      throw Exception('Failed to add savings goal: $e');
    }
  }

  // Update savings goal
  Future<void> updateGoal(SavingsGoalModel goal) async {
    try {
      await _getUserGoalsCollection(
        goal.userId,
      ).doc(goal.id).update(goal.toMap());
    } catch (e) {
      throw Exception('Failed to update savings goal: $e');
    }
  }

  // Delete savings goal
  Future<void> deleteGoal(String userId, String goalId) async {
    try {
      await _getUserGoalsCollection(userId).doc(goalId).delete();
    } catch (e) {
      throw Exception('Failed to delete savings goal: $e');
    }
  }

  // Get all savings goals stream
  Stream<List<SavingsGoalModel>> getGoalsStream(String userId) {
    return _getUserGoalsCollection(
      userId,
    ).orderBy('createdDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                SavingsGoalModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  // Get active (incomplete) goals stream
  Stream<List<SavingsGoalModel>> getActiveGoalsStream(String userId) {
    return _getUserGoalsCollection(userId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => SavingsGoalModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Get completed goals stream
  Stream<List<SavingsGoalModel>> getCompletedGoalsStream(String userId) {
    return _getUserGoalsCollection(userId)
        .where('isCompleted', isEqualTo: true)
        .orderBy('completedDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => SavingsGoalModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Add deposit to goal
  Future<void> addDeposit(String userId, String goalId, double amount) async {
    try {
      final goalDoc = _getUserGoalsCollection(userId).doc(goalId);
      final goalSnapshot = await goalDoc.get();

      if (!goalSnapshot.exists) {
        throw Exception('Goal not found');
      }

      final goal = SavingsGoalModel.fromMap(
        goalSnapshot.data() as Map<String, dynamic>,
      );

      final newAmount = goal.currentAmount + amount;
      final isNowCompleted = newAmount >= goal.targetAmount;

      await goalDoc.update({
        'currentAmount': newAmount,
        if (isNowCompleted && !goal.isCompleted) ...{
          'isCompleted': true,
          'completedDate': DateTime.now().toIso8601String(),
        },
      });
    } catch (e) {
      throw Exception('Failed to add deposit: $e');
    }
  }

  // Withdraw from goal
  Future<void> withdrawFromGoal(
    String userId,
    String goalId,
    double amount,
  ) async {
    try {
      final goalDoc = _getUserGoalsCollection(userId).doc(goalId);
      final goalSnapshot = await goalDoc.get();

      if (!goalSnapshot.exists) {
        throw Exception('Goal not found');
      }

      final goal = SavingsGoalModel.fromMap(
        goalSnapshot.data() as Map<String, dynamic>,
      );

      final newAmount = (goal.currentAmount - amount).clamp(
        0.0,
        double.infinity,
      );

      await goalDoc.update({
        'currentAmount': newAmount,
        if (goal.isCompleted && newAmount < goal.targetAmount) ...{
          'isCompleted': false,
          'completedDate': null,
        },
      });
    } catch (e) {
      throw Exception('Failed to withdraw from goal: $e');
    }
  }
}
