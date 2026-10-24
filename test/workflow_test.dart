import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/money.dart';
import 'package:expense_tracker/core/utils/validators.dart';
import 'package:expense_tracker/data/models/bill_reminder_model.dart';
import 'package:expense_tracker/data/models/expense_model.dart';
import 'package:expense_tracker/data/models/user_model.dart';
import 'package:expense_tracker/data/repositories/bill_reminder_repository.dart';
import 'package:expense_tracker/data/repositories/expense_repository.dart';
import 'package:expense_tracker/data/services/qr_processor_service.dart';
import 'package:expense_tracker/core/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test(
    'daily reminders retain 10 PM across daylight saving and region changes',
    () {
      tzdata.initializeTimeZones();
      for (final region in [
        'Asia/Kolkata',
        'America/New_York',
        'Europe/London',
      ]) {
        final location = tz.getLocation(region);
        for (final date in [DateTime(2027, 3, 13), DateTime(2027, 11, 6)]) {
          final now = tz.TZDateTime(
            location,
            date.year,
            date.month,
            date.day,
            23,
          );
          final next = NotificationService.nextDailyReminder(now);
          expect(next.hour, 22);
          expect(next.day, date.day + 1);
          expect(next.location.name, region);
          expect(next.isAfter(now), isTrue);
        }
      }
    },
  );
  BillReminderModel bill({
    DateTime? date,
    RecurrenceType recurrence = RecurrenceType.monthly,
  }) => BillReminderModel(
    id: 'rent',
    userId: 'u',
    billName: 'Rent',
    amount: 1234.56,
    category: 'Rent/EMI',
    dueDate: date ?? DateTime(2027, 1, 31),
    recurrenceType: recurrence,
    reminderHour: 18,
    reminderMinute: 30,
  );

  test('money preserves paise, rejects invalid input and splits exactly', () {
    expect(Money.parseMinor('1234.56'), 123456);
    for (final invalid in [
      'NaN',
      'Infinity',
      '1e5',
      '1.001',
      '-1',
      '9999999999999',
    ]) {
      expect(Validators.validateAmount(invalid), isNotNull);
    }
    expect(Validators.validateAmount('0'), isNotNull);
    expect(Validators.validateAmount('0.01'), isNull);
    final shares = Money.split(100, 3);
    expect(shares, [33.34, 33.33, 33.33]);
    expect(shares.map(Money.minor).reduce((a, b) => a + b), 10000);
    final expense = ExpenseModel(
      id: 'e',
      userId: 'u',
      amount: 1234.56,
      category: 'Others',
      description: '',
      date: DateTime(2027),
    );
    expect(ExpenseModel.fromMap(expense.toMap()).amount, 1234.56);
    expect(expense.toMap()['amountMinor'], 123456);
  });

  test(
    'monthly recurrence clamps February and restores original day in March',
    () {
      final january = bill();
      final february = january.copyWith(dueDate: january.getNextDueDate());
      expect(february.dueDate, DateTime(2027, 2, 28));
      expect(february.getNextDueDate(), DateTime(2027, 3, 31));
      expect(
        bill(date: DateTime(2028, 1, 31)).getNextDueDate(),
        DateTime(2028, 2, 29),
      );
      final paid = january.copyWith(isPaid: true, paidDate: DateTime(2027));
      expect(paid.copyWith(isPaid: false, paidDate: null).paidDate, isNull);
    },
  );

  test('due today is not overdue and reminder time survives serialization', () {
    final now = DateTime.now();
    final today = bill(date: DateTime(now.year, now.month, now.day));
    expect(today.isOverdue, isFalse);
    expect(
      bill(date: DateTime(now.year, now.month, now.day - 1)).isOverdue,
      isTrue,
    );
    final restored = BillReminderModel.fromMap(today.toMap());
    expect(
      restored.reminderDateTime,
      DateTime(now.year, now.month, now.day - 3, 18, 30),
    );
    final legacy = today.toMap()
      ..remove('reminderHour')
      ..remove('reminderMinute');
    expect(BillReminderModel.fromMap(legacy).reminderHour, 9);
  });

  test(
    'bill payment retries create exactly one expense and next bill',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = BillReminderRepository(firestore: db);
      await repo.addBillReminder(bill());
      await repo.payBill('u', 'rent');
      await repo.payBill('u', 'rent');
      final user = db
          .collection('expense_tracker')
          .doc('users')
          .collection('users')
          .doc('u');
      final bills = await user.collection('bill_reminders').get();
      final expenses = await user.collection('expenses').get();
      expect(bills.docs.length, 2);
      expect(expenses.docs.length, 1);
      expect(expenses.docs.single.data()['amountMinor'], 123456);
      expect(
        (await user.collection('bill_reminders').doc('rent').get())
            .data()!['isPaid'],
        isTrue,
      );
      final next = BillReminderModel.fromMap(
        (await user.collection('bill_reminders').doc('bill_next_rent').get())
            .data()!,
      );
      expect(next.isPaid, isFalse);
      expect(next.paidDate, isNull);
      expect(next.dueDate, DateTime(2027, 2, 28));
    },
  );

  test(
    'bill with expense disabled creates no expense; missing bill writes nothing',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = BillReminderRepository(firestore: db);
      await repo.addBillReminder(bill(recurrence: RecurrenceType.none));
      await repo.payBill('u', 'rent', createExpense: false);
      await expectLater(repo.payBill('u', 'missing'), throwsStateError);
      final user = db
          .collection('expense_tracker')
          .doc('users')
          .collection('users')
          .doc('u');
      expect((await user.collection('bill_reminders').get()).docs.length, 1);
      expect((await user.collection('expenses').get()).docs, isEmpty);
    },
  );

  test(
    'income creation, editing and deletion update balance once with the record',
    () async {
      final db = FakeFirebaseFirestore();
      final user = db
          .collection('expense_tracker')
          .doc('users')
          .collection('users')
          .doc('u');
      await user.set({'monthlyIncome': 1000.0});
      final repo = ExpenseRepository(firestore: db);
      final income = ExpenseModel(
        id: 'salary',
        userId: 'u',
        amount: 100.25,
        category: 'Salary',
        description: '',
        date: DateTime.now(),
        isIncome: true,
      );
      await repo.addExpense(income);
      await repo.addExpense(income);
      expect((await user.get()).data()!['monthlyIncome'], 1100.25);
      await repo.updateExpense(income.copyWith(amount: 120.50));
      expect((await user.get()).data()!['monthlyIncome'], 1120.50);
      await repo.deleteExpense('u', income.id);
      await repo.deleteExpense('u', income.id);
      expect((await user.get()).data()!['monthlyIncome'], 1000);
      expect((await user.collection('expenses').get()).docs, isEmpty);
    },
  );

  test(
    'skip choice persists and existing users retain completed income setup',
    () {
      final user = UserModel(
        id: 'u',
        email: 'a@b.com',
        name: 'A',
        createdAt: DateTime(2027),
      );
      expect(user.incomeSetupCompleted, isFalse);
      expect(
        UserModel.fromMap(
          user.copyWith(incomeSetupCompleted: true).toMap(),
        ).incomeSetupCompleted,
        isTrue,
      );
      final legacy = user.toMap()..remove('incomeSetupCompleted');
      legacy['lastIncomeSetMonth'] = DateTime(2026).toIso8601String();
      expect(UserModel.fromMap(legacy).incomeSetupCompleted, isTrue);
    },
  );

  test('UPI parsing preserves encoded merchant names and notes', () {
    final qr = QRProcessorService().processQR(
      'upi://pay?pa=shop%40upi&pn=My+Shop&am=12.50&tn=Order%3D42',
    );
    expect(qr.merchantName, 'My Shop');
    expect(qr.amount, 12.50);
    expect(qr.transactionNote, 'Order=42');
    expect(qr.upiParams['pa'], 'shop@upi');
  });
}
