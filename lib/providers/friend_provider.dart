import 'session_notifier.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../data/models/friend_model.dart';
import '../data/repositories/friend_repository.dart';

class FriendProvider extends SessionNotifier {
  final FriendRepository _friendRepository = FriendRepository();

  List<FriendModel> _friends = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FriendModel> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Add friend by email
  Future<void> addFriendByEmail(String userId, String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final friend = await _friendRepository.searchUserByEmail(userId, email);

      if (friend == null) {
        _isLoading = false;
        _errorMessage = 'No user found with this email';
        notifyListeners();
        throw Exception('No user found with this email');
      }

      await _friendRepository.addFriend(friend);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Remove friend
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _friendRepository.removeFriend(userId, friendId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Load friends (subscribe to stream)
  void loadFriends(String userId) {
    watch(
      'stream0',
      _friendRepository
          .getFriendsStream(userId)
          .listen(
            (friends) {
              _friends = friends;
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = error.toString();
              notifyListeners();
            },
          ),
    );
  }

  // Import contacts from phone
  Future<List<Contact>> importContacts() async {
    try {
      // Request permission (will show dialog if not granted)
      await FlutterContacts.requestPermission();

      // Try to get contacts - if permission is granted, this will work
      // If not granted, it will throw an error
      final contacts = await FlutterContacts.getContacts(withProperties: true);

      return contacts;
    } catch (e) {
      // Check if it's a permission error
      if (e.toString().contains('permission') ||
          e.toString().contains('denied') ||
          e.toString().contains('PERMISSION')) {
        _errorMessage = 'Contacts permission denied';
        notifyListeners();
        throw Exception('Contacts permission denied');
      }

      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Add friend from contact
  Future<FriendModel> addFriendFromContact(
    String userId,
    Contact contact,
  ) async {
    try {
      final friend = FriendModel(
        id: '',
        userId: userId,
        friendId: '',
        name: contact.displayName,
        email: contact.emails.isNotEmpty ? contact.emails.first.address : '',
        photoUrl: null,
        addedAt: DateTime.now(),
      );
      await _friendRepository.addFriend(friend);
      return friend;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Clear friends
  void clearFriends() {
    _friends = [];
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
