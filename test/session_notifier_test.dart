import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/providers/session_notifier.dart';

void main() {
  test(
    'replacing subscriptions and closing a session stops old events',
    () async {
      final oldStream = StreamController<int>(sync: true);
      final newStream = StreamController<int>(sync: true);
      final notifier = SessionNotifier();
      final received = <int>[];
      notifier.watch('records', oldStream.stream.listen(received.add));
      oldStream.add(1);
      notifier.watch('records', newStream.stream.listen(received.add));
      oldStream.add(2);
      newStream.add(3);
      expect(received, [1, 3]);
      notifier.dispose();
      newStream.add(4);
      notifier
          .notifyListeners(); // Async completions after sign-out are harmless.
      expect(received, [1, 3]);
      await oldStream.close();
      await newStream.close();
    },
  );
}
