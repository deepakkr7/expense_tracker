import 'session_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../core/services/notification_service.dart';
import 'dart:async';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthProvider extends SessionNotifier {
  final AuthRepository _authRepository = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  int _authEpoch = 0;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  // Initialize and listen to auth state changes
  void _init() {
    watch(
      'auth',
      _authRepository.authStateChanges.listen((User? firebaseUser) async {
        final epoch = ++_authEpoch;
        if (firebaseUser != null) {
          try {
            final profile = await _authRepository.getUserData(firebaseUser.uid);
            if (epoch != _authEpoch) return;
            _currentUser = profile;
            _status = AuthStatus.authenticated;
            unawaited(_restoreReminders());
          } catch (e) {
            if (epoch != _authEpoch) return;
            _status = AuthStatus.error;
            _errorMessage = e.toString();
          }
        } else {
          _currentUser = null;
          _status = AuthStatus.unauthenticated;
        }
        notifyListeners();
      }),
    );
  }

  Future<void> _restoreReminders() async {
    try {
      if (await NotificationService().dailyEnabled() &&
          _authRepository.currentUser != null) {
        await NotificationService().scheduleDailyTenPMReminder();
      }
    } catch (_) {
      // Optional reminders must not block sign-in.
    }
  }

  // Register with email and password
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authRepository.registerWithEmail(
        email: email,
        password: password,
        name: name,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Login with email and password
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authRepository.loginWithEmail(
        email: email,
        password: password,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authRepository.signInWithGoogle();

      if (_currentUser != null) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUser(UserModel user) async {
    try {
      await _authRepository.updateUserData(user);
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Could not save changes. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    final id = _currentUser?.id;
    if (id == null) return;
    try {
      final user = await _authRepository.getUserData(id);
      if (_currentUser?.id == id && user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (_) {
      /* A committed transaction must not be reported as failed. */
    }
  }

  Future<void> resetPassword(String email) =>
      _authRepository.resetPassword(email);

  // Logout
  Future<void> logout() async {
    try {
      await _authRepository.logout();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
