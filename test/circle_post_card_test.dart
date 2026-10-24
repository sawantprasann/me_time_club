import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:me_time_club/models/circle_response.dart';
import 'package:me_time_club/theme/tokens.dart';
import 'package:me_time_club/widgets/circle_post_card.dart';

Future<void> showCard(
  WidgetTester tester, {
  Future<void> Function(CircleResponseDraft)? onSend,
  List<CircleReply> replies = const [],
  AppTokens? tokens,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: CirclePostCard(
              t: tokens ?? AppTokens.day,
              author: 'Anonymous',
              body: 'Some days I just need a moment to breathe.',
              time: '2h ago',
              replies: replies,
              onSendReply: onSend,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pump();
}

void main() {
  testWidgets('Response panels switch, close, and preserve the draft', (
    tester,
  ) async {
    await showCard(tester);
    expect(find.byType(TextField), findsNothing);
    await tapText(tester, 'Respond');
    await tester.enterText(find.byType(TextField), 'My written draft');
    await tapText(tester, 'Respond with feeling');
    expect(find.text('Holding you'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Send'), findsNothing);
    await tapText(tester, 'I understand');
    expect(find.byType(TextField), findsNothing);
    expect(
      find.textContaining('Anonymous:  I understand', findRichText: true),
      findsOneWidget,
    );
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Respond with feeling'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(
      find.textContaining('Anonymous:  I understand', findRichText: true),
      findsOneWidget,
    );
    await tapText(tester, 'Respond');
    expect(find.text('Holding you'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'My written draft',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('No reply API means sending is disabled without losing a draft', (
    tester,
  ) async {
    await showCard(tester);
    await tapText(tester, 'Respond');
    await tester.enterText(find.byType(TextField), 'Here for you');
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Send'),
    );
    expect(button.onPressed, isNull);
    expect(
      find.text('Written responses will be available soon.'),
      findsNothing,
    );
  });

  testWidgets(
    'Selected feelings appear once below the post alongside existing replies',
    (tester) async {
      await showCard(
        tester,
        replies: const [
          CircleReply(author: 'Another mother', body: 'Here for you'),
        ],
      );
      await tapText(tester, 'Respond with feeling');
      await tapText(tester, 'I understand');
      expect(find.byType(ChoiceChip), findsNothing);
      await tapText(tester, 'Respond with feeling');
      await tapText(tester, 'I understand');
      await tapText(tester, 'Respond with feeling');
      await tapText(tester, "I'm here");
      expect(
        find.textContaining('Anonymous:  I understand', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining("Anonymous:  I'm here", findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Another mother:  Here for you',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('BE THE FIRST TO RESPOND GENTLY…'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      final response = find.textContaining(
        'Anonymous:  I understand',
        findRichText: true,
      );
      expect(
        tester.getTopLeft(response).dy,
        greaterThan(
          tester
              .getTopLeft(
                find.text('Some days I just need a moment to breathe.'),
              )
              .dy,
        ),
      );
      expect(
        tester.getTopLeft(response).dy,
        lessThan(tester.getTopLeft(find.text('Respond with feeling')).dy),
      );
    },
  );

  testWidgets(
    'Feeling send waits for success and prevents duplicate submission',
    (tester) async {
      final completion = Completer<void>();
      final sent = <CircleResponseDraft>[];
      await showCard(
        tester,
        onSend: (draft) {
          sent.add(draft);
          return completion.future;
        },
      );
      await tapText(tester, 'Respond with feeling');
      await tapText(tester, "I'm here");
      expect(sent.single.toJson(), {
        'circle_response': {
          'body': "I'm here",
          'feeling_key': 'im_here',
          'anonymous': true,
        },
      });
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Send'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Respond with feeling'),
            )
            .onPressed,
        isNull,
      );
      completion.complete();
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
      await tapText(tester, 'Respond');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets('Failed replies retain the draft and can be retried', (
    tester,
  ) async {
    await showCard(
      tester,
      onSend: (_) async => throw Exception('Network failure'),
    );
    await tapText(tester, 'Respond');
    await tester.enterText(find.byType(TextField), 'You are not alone.');
    await tester.pump();
    await tapText(tester, 'Send');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'You are not alone.',
    );
    expect(
      find.text('Your response could not be sent. Please try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Replies stay visible and only the seven feeling responses are offered',
    (tester) async {
      await showCard(
        tester,
        replies: const [CircleReply(author: 'Anonymous', body: 'I understand')],
      );
      expect(
        find.textContaining('Anonymous:  I understand', findRichText: true),
        findsOneWidget,
      );
      await tapText(tester, 'Respond with feeling');
      expect(find.byType(ChoiceChip), findsNWidgets(7));
      expect(find.textContaining('Heart'), findsNothing);
      expect(find.textContaining('Hug'), findsNothing);
      expect(find.textContaining('Leaf'), findsNothing);
    },
  );

  testWidgets('Small screens and larger text fit in the night theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showCard(tester, tokens: AppTokens.night, textScale: 1.6);
    await tapText(tester, 'Respond with feeling');
    await tapText(tester, 'Take a breath');
    expect(tester.takeException(), isNull);
  });

  test(
    'Written reply payload omits a feeling key and anonymous replies hide names',
    () {
      expect(const CircleResponseDraft(body: 'Here for you').toJson(), {
        'circle_response': {'body': 'Here for you', 'anonymous': true},
      });
      expect(
        CircleReply.fromJson({
          'anonymous': true,
          'author': 'Private name',
          'body': 'Hello',
        }).author,
        'Anonymous',
      );
    },
  );
}
