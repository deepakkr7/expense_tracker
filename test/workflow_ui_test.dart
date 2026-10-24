import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/data/models/payment_qr_data.dart';
import 'package:expense_tracker/presentation/screens/auth/password_reset_screen.dart';
import 'package:expense_tracker/presentation/widgets/bill_reminder_time_field.dart';
import 'package:expense_tracker/presentation/widgets/qr_result_dialog.dart';
import 'package:expense_tracker/presentation/screens/expense/edit_expense_screen.dart';
import 'package:expense_tracker/data/models/expense_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final dark in [false, true]) {
    final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
    testWidgets('editing preserves paise in ${dark ? 'dark' : 'light'} theme', (
      tester,
    ) async {
      final expense = ExpenseModel(
        id: 'e',
        userId: 'u',
        amount: 1234.56,
        category: 'Others',
        description: 'Purchase',
        date: DateTime.now(),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: EditExpenseScreen(expense: expense),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1234.56'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'password recovery validates, retries and confirms in ${dark ? 'dark' : 'light'} theme',
      (tester) async {
        var calls = 0;
        String? email;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: PasswordResetScreen(
              onReset: (value) async {
                calls++;
                email = value;
                if (calls == 1) throw Exception('offline');
              },
            ),
          ),
        );
        await tester.tap(find.text('Send reset link'));
        await tester.pumpAndSettle();
        expect(calls, 0);
        await tester.enterText(
          find.byType(TextFormField),
          ' user@example.com ',
        );
        await tester.tap(find.text('Send reset link'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Could not send'), findsOneWidget);
        await tester.tap(find.text('Send reset link'));
        await tester.pumpAndSettle();
        expect(email, 'user@example.com');
        expect(
          find.textContaining('If an account uses this email'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'QR launch requires explicit success confirmation in ${dark ? 'dark' : 'light'} theme',
      (tester) async {
        tester.view.physicalSize = const Size(840, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        PaymentQRData? result;
        Uri? launched;
        final qr = PaymentQRData(
          provider: PaymentProvider.upi,
          merchantName: 'Shop',
          amount: 12.50,
          originalUrl: 'upi://pay?pa=shop@upi&am=12.50',
          upiParams: const {'pa': 'shop@upi', 'am': '12.50'},
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showDialog<PaymentQRData>(
                      context: context,
                      builder: (_) => QRResultDialog(
                        qrData: qr,
                        openPayment: (uri) async {
                          launched = uri;
                          return true;
                        },
                      ),
                    );
                  },
                  child: const Text('Scan'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Scan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open UPI App'));
        await tester.pumpAndSettle();
        expect(launched?.scheme, 'upi');
        expect(launched?.queryParameters['pa'], 'shop@upi');
        expect(result, isNull);
        await tester.tap(find.textContaining('I completed payment'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();
        expect(result, isNull);
        await tester.tap(find.textContaining('I completed payment'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes, review expense'));
        await tester.pumpAndSettle();
        expect(result, same(qr));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'bill reminder shows local-time preview and opens a time picker in ${dark ? 'dark' : 'light'} theme',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: BillReminderTimeField(
                dueDate: DateTime(2030, 1, 10),
                daysBefore: 3,
                time: const TimeOfDay(hour: 18, minute: 30),
                onChanged: (_) {},
              ),
            ),
          ),
        );
        expect(find.textContaining('Jan 7, 2030'), findsOneWidget);
        expect(find.textContaining('device local time'), findsOneWidget);
        await tester.tap(find.text('Reminder time'));
        await tester.pumpAndSettle();
        expect(find.byType(TimePickerDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
