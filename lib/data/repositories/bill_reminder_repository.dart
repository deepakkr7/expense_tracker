import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_reminder_model.dart';
import '../models/expense_model.dart';

class BillReminderRepository {
  final FirebaseFirestore _firestore;
  BillReminderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // The paid flag, expense and next occurrence commit together. The stored
  // paid flag and stable document IDs make retries and concurrent taps safe.
  Future<BillReminderModel?> payBill(
    String userId,
    String billId, {
    bool createExpense = true,
  }) async {
    final ref = _getUserBillsCollection(userId).doc(billId);
    final now = DateTime.now();
    return _firestore.runTransaction<BillReminderModel?>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('Bill no longer exists');
      final bill = BillReminderModel.fromMap(
        snapshot.data() as Map<String, dynamic>,
      );
      if (bill.isPaid) return null;
      final expenseId = 'bill_payment_$billId';
      final expenseRef = ref.parent.parent!
          .collection('expenses')
          .doc(expenseId);
      final nextRef = ref.parent.doc('bill_next_$billId');
      final expenseSnapshot = await transaction.get(expenseRef);
      final nextSnapshot = await transaction.get(nextRef);
      transaction.update(
        ref,
        bill.copyWith(isPaid: true, paidDate: now).toMap(),
      );
      if (createExpense && bill.autoCreateExpense && !expenseSnapshot.exists) {
        transaction.set(
          expenseRef,
          ExpenseModel(
            id: expenseId,
            userId: userId,
            amount: bill.amount,
            category: bill.category,
            description: '${bill.billName} (Bill Payment)',
            date: now,
          ).toMap(),
        );
      }
      final nextDate = bill.getNextDueDate();
      if (nextDate == null || nextSnapshot.exists) return null;
      final next = bill.copyWith(
        id: nextRef.id,
        dueDate: nextDate,
        isPaid: false,
        paidDate: null,
      );
      transaction.set(nextRef, next.toMap());
      return next;
    });
  }

  // Get user's bill reminders collection
  CollectionReference _getUserBillsCollection(String userId) {
    return _firestore
        .collection('expense_tracker')
        .doc('users')
        .collection('users')
        .doc(userId)
        .collection('bill_reminders');
  }

  // Add bill reminder
  Future<void> addBillReminder(BillReminderModel bill) async {
    try {
      await _getUserBillsCollection(bill.userId).doc(bill.id).set(bill.toMap());
    } catch (e) {
      throw Exception('Failed to add bill reminder: $e');
    }
  }

  // Update bill reminder
  Future<void> updateBillReminder(BillReminderModel bill) async {
    try {
      await _getUserBillsCollection(
        bill.userId,
      ).doc(bill.id).update(bill.toMap());
    } catch (e) {
      throw Exception('Failed to update bill reminder: $e');
    }
  }

  // Delete bill reminder
  Future<void> deleteBillReminder(String userId, String billId) async {
    try {
      await _getUserBillsCollection(userId).doc(billId).delete();
    } catch (e) {
      throw Exception('Failed to delete bill reminder: $e');
    }
  }

  // Get all bill reminders stream
  Stream<List<BillReminderModel>> getBillRemindersStream(String userId) {
    return _getUserBillsCollection(
      userId,
    ).orderBy('dueDate', descending: false).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                BillReminderModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  // Get unpaid bill reminders
  Stream<List<BillReminderModel>> getUnpaidBillsStream(String userId) {
    return _getUserBillsCollection(userId)
        .where('isPaid', isEqualTo: false)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BillReminderModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Get bills for current month
  Stream<List<BillReminderModel>> getCurrentMonthBillsStream(String userId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _getUserBillsCollection(userId)
        .where(
          'dueDate',
          isGreaterThanOrEqualTo: startOfMonth.toIso8601String(),
        )
        .where('dueDate', isLessThanOrEqualTo: endOfMonth.toIso8601String())
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BillReminderModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Get upcoming bills (next 7 days)
  Stream<List<BillReminderModel>> getUpcomingBillsStream(String userId) {
    final today = DateTime.now();
    final now = DateTime(today.year, today.month, today.day);
    final nextWeek = now.add(const Duration(days: 7));

    return _getUserBillsCollection(userId)
        .where('isPaid', isEqualTo: false)
        .where('dueDate', isGreaterThanOrEqualTo: now.toIso8601String())
        .where('dueDate', isLessThanOrEqualTo: nextWeek.toIso8601String())
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BillReminderModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Get overdue bills
  Stream<List<BillReminderModel>> getOverdueBillsStream(String userId) {
    final today = DateTime.now();
    final now = DateTime(today.year, today.month, today.day);

    return _getUserBillsCollection(userId)
        .where('isPaid', isEqualTo: false)
        .where('dueDate', isLessThan: now.toIso8601String())
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BillReminderModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }
}
