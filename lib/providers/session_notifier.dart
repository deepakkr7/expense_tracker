import 'dart:async';
import 'package:flutter/foundation.dart';

/// Owns stream subscriptions and ignores completions from a closed user session.
class SessionNotifier extends ChangeNotifier {
  final Map<String, StreamSubscription<dynamic>> _subscriptions = {};
  bool _disposed = false;

  void watch(String key, StreamSubscription<dynamic> subscription) {
    _subscriptions.remove(key)?.cancel();
    if (_disposed) {
      subscription.cancel();
    } else {
      _subscriptions[key] = subscription;
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
