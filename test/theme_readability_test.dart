import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/data/models/payment_qr_data.dart';
import 'package:expense_tracker/presentation/widgets/qr_result_dialog.dart';
import 'package:expense_tracker/presentation/widgets/ocr_result_dialog.dart';
import 'package:expense_tracker/presentation/widgets/zero_budget_warning_dialog.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final dark in [false, true]) {
    final name = dark ? 'dark' : 'light';
    testWidgets('$name theme has readable text styles and dialog contents', (
      tester,
    ) async {
      final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
      tester.view.physicalSize = const Size(840, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final t = theme.textTheme;
      for (final style in [
        t.displayLarge,
        t.displayMedium,
        t.displaySmall,
        t.headlineLarge,
        t.headlineMedium,
        t.headlineSmall,
        t.titleLarge,
        t.titleMedium,
        t.titleSmall,
        t.bodyLarge,
        t.bodyMedium,
        t.bodySmall,
        t.labelLarge,
        t.labelMedium,
        t.labelSmall,
      ].whereType<TextStyle>()) {
        expect(
          contrast(style.color!, theme.colorScheme.surface),
          greaterThanOrEqualTo(4.5),
        );
      }
      var dialogIndex = 0;
      for (final dialog in <Widget>[
        QRResultDialog(
          qrData: const PaymentQRData(
            provider: PaymentProvider.upi,
            merchantName: 'Sample Merchant',
            amount: 250,
            originalUrl: 'upi://pay',
            upiParams: {},
          ),
        ),
        OCRResultDialog(
          ocrData: const {'amount': 250, 'merchant': 'Sample Merchant'},
          onApply: (_) {},
        ),
        ZeroBudgetWarningDialog(
          category: 'Food',
          amount: 250,
          onIgnoreAndContinue: () {},
        ),
        AlertDialog(
          title: const Text('Edit expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount',
                  prefixText: '₹ ',
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: 'Food',
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'Food', child: Text('Food')),
                ],
                onChanged: (_) {},
              ),
              Builder(
                builder: (context) => Text(
                  'Success notice',
                  style: TextStyle(
                    color: AppTheme.readableColor(context, Colors.green),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () {}, child: const Text('Cancel')),
            FilledButton(onPressed: () {}, child: const Text('Save')),
          ],
        ),
        Dialog(
          child: SizedBox(
            width: 500,
            child: CalendarDatePicker(
              initialDate: DateTime(2026, 10, 17),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              onDateChanged: (_) {},
            ),
          ),
        ),
      ]) {
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: RepaintBoundary(
              key: boundaryKey,
              child: Scaffold(body: dialog),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final element in find.byType(Text).evaluate()) {
          final text = element.widget as Text;
          final style = DefaultTextStyle.of(element).style.merge(text.style);
          if (style.color == null || text.data?.isEmpty == true) continue;
          Color background = theme.colorScheme.surface;
          element.visitAncestorElements((parent) {
            final widget = parent.widget;
            final Decoration? decoration = widget is DecoratedBox
                ? widget.decoration
                : widget is Ink
                ? widget.decoration
                : null;
            final fill = decoration is BoxDecoration
                ? decoration.color
                : decoration is ShapeDecoration
                ? decoration.color
                : null;
            if (fill != null && fill.a == 1) {
              background = fill;
              return false;
            }
            if (parent.widget is Material) {
              final material = parent.widget as Material;
              if (material.color != null && material.color!.a == 1) {
                background = material.color!;
                return false;
              }
            }
            return true;
          });
          expect(
            contrast(style.color!, background),
            greaterThanOrEqualTo(4.5),
            reason:
                '$name: ${text.data} foreground=${style.color} background=$background',
          );
        }
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final picture = await boundary.toImage();
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          Directory('.cache/theme-previews').createSync(recursive: true);
          File(
            '.cache/theme-previews/$name-${dialogIndex++}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          picture.dispose();
        });
      }
    });
  }
}
