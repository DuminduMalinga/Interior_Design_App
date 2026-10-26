import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/app_theme.dart';
import 'package:interior_design/main.dart';

import 'test_utils.dart';

typedef _Sent = ({String subject, String message, bool testOnly});

/// Opens the dialog from a button, as the admin screen does, and collects
/// what it closes with.
class _Harness {
  _Harness({
    Future<int> Function()? countReaders,
    Future<int> Function({
      required String subject,
      required String message,
      required bool testOnly,
    })?
    send,
  }) : _countReaders = countReaders,
       _send = send;

  final Future<int> Function()? _countReaders;
  final Future<int> Function({
    required String subject,
    required String message,
    required bool testOnly,
  })?
  _send;

  int? closedWith;
  bool closed = false;

  Future<void> open(WidgetTester tester, {Size? size}) async {
    tester.view.physicalSize = size ?? const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  closedWith = await showDialog<int>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => ProductNewsDialog(
                      countReaders: _countReaders,
                      send: _send,
                    ),
                  );
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
}

Future<void> _fill(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextField, 'Subject'), ' Hello ');
  await tester.enterText(
    find.widgetWithText(TextField, 'Message'),
    ' New layouts! ',
  );
  await tester.pump();
}

bool _enabled(WidgetTester tester, String label) {
  final button = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  return tester.widget<ButtonStyleButton>(button).onPressed != null;
}

/// The admin's form for emailing product news (the web's `NewsDialog`).
void main() {
  setUpAll(loadRoboto);

  testWidgets('says who will get it, once it knows', (tester) async {
    final count = Completer<int>();
    await _Harness(countReaders: () => count.future).open(tester);
    expect(find.textContaining('everyone who turned on'), findsOneWidget);

    count.complete(3);
    // one frame for the count to arrive, one to draw it
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('3 people who turned on'), findsOneWidget);
  });

  testWidgets('keeps the general note if the count fails', (tester) async {
    await _Harness(
      countReaders: () async => throw Exception('no'),
    ).open(tester);
    expect(find.textContaining('everyone who turned on'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nothing can be sent until subject and message are filled', (
    tester,
  ) async {
    await _Harness(countReaders: () async => 5).open(tester);
    expect(_enabled(tester, 'Send to everyone'), isFalse);
    expect(_enabled(tester, 'Send me a test'), isFalse);

    await tester.enterText(find.widgetWithText(TextField, 'Subject'), 'Hi');
    await tester.pump();
    expect(_enabled(tester, 'Send to everyone'), isFalse);

    await tester.enterText(find.widgetWithText(TextField, 'Message'), '   ');
    await tester.pump();
    expect(_enabled(tester, 'Send to everyone'), isFalse, reason: 'blank');

    await _fill(tester);
    expect(_enabled(tester, 'Send to everyone'), isTrue);
    expect(_enabled(tester, 'Send me a test'), isTrue);
  });

  testWidgets('with no readers it can only be tested, not sent', (
    tester,
  ) async {
    await _Harness(countReaders: () async => 0).open(tester);
    await _fill(tester);
    expect(find.textContaining('Nobody has Product news'), findsOneWidget);
    expect(_enabled(tester, 'Send to everyone'), isFalse);
    expect(_enabled(tester, 'Send me a test'), isTrue);
  });

  testWidgets('sends the trimmed text to everyone and closes with the count', (
    tester,
  ) async {
    final sent = <_Sent>[];
    final harness = _Harness(
      countReaders: () async => 4,
      send: ({required subject, required message, required testOnly}) async {
        sent.add((subject: subject, message: message, testOnly: testOnly));
        return 4;
      },
    );
    await harness.open(tester);
    await _fill(tester);
    await tester.tap(find.text('Send to everyone'));
    await tester.pumpAndSettle();

    expect(sent, [
      (subject: 'Hello', message: 'New layouts!', testOnly: false),
    ]);
    expect(harness.closed, isTrue);
    expect(harness.closedWith, 4);
    expect(find.byType(ProductNewsDialog), findsNothing);
  });

  testWidgets('a test goes to the admin alone and leaves the form open', (
    tester,
  ) async {
    final sent = <_Sent>[];
    final harness = _Harness(
      countReaders: () async => 4,
      send: ({required subject, required message, required testOnly}) async {
        sent.add((subject: subject, message: message, testOnly: testOnly));
        return 1;
      },
    );
    await harness.open(tester);
    await _fill(tester);
    await tester.tap(find.text('Send me a test'));
    await tester.pumpAndSettle();

    expect(sent.single.testOnly, isTrue);
    expect(
      find.text('Test sent to your own address. Check your inbox.'),
      findsOneWidget,
    );
    expect(harness.closed, isFalse);
    expect(find.byType(ProductNewsDialog), findsOneWidget);
  });

  testWidgets('shows why it failed and stays open to try again', (
    tester,
  ) async {
    var fail = true;
    final harness = _Harness(
      countReaders: () async => 2,
      send: ({required subject, required message, required testOnly}) async {
        if (fail) throw Exception("You've reached today's email limit.");
        return 2;
      },
    );
    await harness.open(tester);
    await _fill(tester);
    await tester.tap(find.text('Send to everyone'));
    await tester.pumpAndSettle();

    expect(find.text("You've reached today's email limit."), findsOneWidget);
    expect(harness.closed, isFalse);
    expect(_enabled(tester, 'Send to everyone'), isTrue);

    fail = false;
    await tester.tap(find.text('Send to everyone'));
    await tester.pumpAndSettle();
    expect(harness.closedWith, 2);
  });

  testWidgets('cannot be sent twice or closed while it is sending', (
    tester,
  ) async {
    final pending = Completer<int>();
    var calls = 0;
    final harness = _Harness(
      countReaders: () async => 2,
      send: ({required subject, required message, required testOnly}) {
        calls++;
        return pending.future;
      },
    );
    await harness.open(tester);
    await _fill(tester);
    await tester.tap(find.text('Send to everyone'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_enabled(tester, 'Cancel'), isFalse);
    expect(_enabled(tester, 'Send me a test'), isFalse);
    // the send button now shows progress, and does nothing if pressed
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);

    pending.complete(2);
    await tester.pumpAndSettle();
    expect(harness.closedWith, 2);
  });

  testWidgets('cancel closes it without sending', (tester) async {
    var calls = 0;
    final harness = _Harness(
      countReaders: () async => 2,
      send: ({required subject, required message, required testOnly}) async {
        calls++;
        return 0;
      },
    );
    await harness.open(tester);
    await _fill(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(harness.closed, isTrue);
    expect(harness.closedWith, isNull);
    expect(calls, 0);
  });

  for (final (name, size) in const [
    ('mobile', Size(360, 640)),
    ('tablet', Size(800, 900)),
    ('desktop', Size(1440, 900)),
  ]) {
    testWidgets('fits a $name screen, even with an error showing', (
      tester,
    ) async {
      await _Harness(
        countReaders: () async => 120,
        send: ({required subject, required message, required testOnly}) async =>
            throw Exception(
              'Resend only delivers to your own address until you verify a '
              'domain there. Use "Send me a test", or verify a domain in '
              'Resend and set MAIL_FROM to an address on it.',
            ),
      ).open(tester, size: size);
      await _fill(tester);
      await tester.tap(find.text('Send to everyone'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Resend only delivers'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
