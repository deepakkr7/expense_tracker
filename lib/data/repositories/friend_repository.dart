import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/friend_model.dart';

class FriendRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Helper to get user's friends subcollection
  CollectionReference _getUserFriendsCollection(String userId) {
    return _firestore
        .collection('expense_tracker')
        .doc('users')
        .collection('users')
        .doc(userId)
        .collection('friends');
  }

  // Add friend
  Future<String> addFriend(FriendModel friend) async {
    try {
      final id = _uuid.v4();
      final friendWithId = friend.copyWith(id: id);

      await _getUserFriendsCollection(
        friend.userId,
      ).doc(id).set(friendWithId.toMap());

      return id;
    } catch (e) {
      throw Exception('Failed to add friend: $e');
    }
  }

  // Remove friend
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      await _getUserFriendsCollection(userId).doc(friendId).delete();
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }

  // Get user's friends stream
  Stream<List<FriendModel>> getFriendsStream(String userId) {
    return _getUserFriendsCollection(
      userId,
    ).orderBy('addedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FriendModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get friend by ID
  Future<FriendModel?> getFriendById(String userId, String friendId) async {
    try {
      final doc = await _getUserFriendsCollection(userId).doc(friendId).get();
      if (doc.exists) {
        return FriendModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get friend: $e');
    }
  }

  // Search for user by email (to add as friend)
  Future<FriendModel?> searchUserByEmail(String userId, String email) async {
    try {
      final userSnapshot = await _firestore
          .collection('expense_tracker')
          .doc('users')
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        return null;
      }

      final userData = userSnapshot.docs.first.data();
      return FriendModel(
        id: '', // Will be set when adding
        userId: userId,
        friendId: userData['id'],
        name: userData['name'],
        email: userData['email'],
        photoUrl: userData['photoUrl'],
        addedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to search user: $e');
    }
  }
}
