import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/borrowed_money_model.dart';

class BorrowedMoneyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's borrowed money collection
  CollectionReference _getUserBorrowedMoneyCollection(String userId) {
    return _firestore
        .collection('expense_tracker')
        .doc('users')
        .collection('users')
        .doc(userId)
        .collection('borrowed_money');
  }

  // Add borrowed money transaction
  Future<void> addBorrowedMoney(BorrowedMoneyModel borrowedMoney) async {
    try {
      await _getUserBorrowedMoneyCollection(
        borrowedMoney.userId,
      ).doc(borrowedMoney.id).set(borrowedMoney.toMap());
    } catch (e) {
      throw Exception('Failed to add borrowed money: $e');
    }
  }

  // Update borrowed money transaction
  Future<void> updateBorrowedMoney(BorrowedMoneyModel borrowedMoney) async {
    try {
      await _getUserBorrowedMoneyCollection(
        borrowedMoney.userId,
      ).doc(borrowedMoney.id).update(borrowedMoney.toMap());
    } catch (e) {
      throw Exception('Failed to update borrowed money: $e');
    }
  }

  // Delete borrowed money transaction
  Future<void> deleteBorrowedMoney(String userId, String id) async {
    try {
      await _getUserBorrowedMoneyCollection(userId).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete borrowed money: $e');
    }
  }

  // Get all borrowed money transactions stream
  Stream<List<BorrowedMoneyModel>> getBorrowedMoneyStream(String userId) {
    return _getUserBorrowedMoneyCollection(
      userId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                BorrowedMoneyModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  // Get unpaid borrowed money stream
  Stream<List<BorrowedMoneyModel>> getUnpaidBorrowedMoneyStream(String userId) {
    return _getUserBorrowedMoneyCollection(userId)
        .where('isPaid', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BorrowedMoneyModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Get borrowed money by person
  Stream<List<BorrowedMoneyModel>> getBorrowedMoneyByPersonStream(
    String userId,
    String personName,
  ) {
    return _getUserBorrowedMoneyCollection(userId)
        .where('personName', isEqualTo: personName)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BorrowedMoneyModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }
}
