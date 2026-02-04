import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/group_model.dart';
import '../data/repositories/group_repository.dart';

class GroupProvider with ChangeNotifier {
  final GroupRepository _repository = GroupRepository();

  List<GroupModel> _groups = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _groupsSubscription;

  // Getters
  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load groups
  void loadGroups(String userId) {
    _groupsSubscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _groupsSubscription = _repository
        .getGroupsStream(userId)
        .listen(
          (groups) {
            _groups = groups;
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

  // Add group
  Future<void> addGroup(GroupModel group) async {
    try {
      await _repository.addGroup(group);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update group
  Future<void> updateGroup(GroupModel group) async {
    try {
      await _repository.updateGroup(group);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete group
  Future<void> deleteGroup(String userId, String groupId) async {
    try {
      await _repository.deleteGroup(userId, groupId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get group by ID
  GroupModel? getGroupById(String groupId) {
    try {
      return _groups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    super.dispose();
  }
}
