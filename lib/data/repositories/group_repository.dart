import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's groups collection
  CollectionReference _getUserGroupsCollection(String userId) {
    return _firestore
        .collection('expense_tracker')
        .doc('users')
        .collection('users')
        .doc(userId)
        .collection('groups');
  }

  // Add group
  Future<void> addGroup(GroupModel group) async {
    try {
      await _getUserGroupsCollection(
        group.userId,
      ).doc(group.id).set(group.toMap());
    } catch (e) {
      throw Exception('Failed to add group: $e');
    }
  }

  // Update group
  Future<void> updateGroup(GroupModel group) async {
    try {
      await _getUserGroupsCollection(
        group.userId,
      ).doc(group.id).update(group.toMap());
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  // Delete group
  Future<void> deleteGroup(String userId, String groupId) async {
    try {
      await _getUserGroupsCollection(userId).doc(groupId).delete();
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  // Get groups stream
  Stream<List<GroupModel>> getGroupsStream(String userId) {
    return _getUserGroupsCollection(userId).orderBy('name').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get group by ID
  Future<GroupModel?> getGroupById(String userId, String groupId) async {
    try {
      final doc = await _getUserGroupsCollection(userId).doc(groupId).get();
      if (doc.exists) {
        return GroupModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get group: $e');
    }
  }
}
