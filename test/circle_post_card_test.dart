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
  List<CircleFeelingCount> feelings = const [],
  List<String> myMoods = const [],
  int? mamaCount,
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
              feelings: feelings,
              myMoods: myMoods,
              mamaCount: mamaCount,
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

Future<void> tapChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(ChoiceChip, label);
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pump();
}

String hintText(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField)).decoration!.hintText!;
}

bool chipSelected(WidgetTester tester, String label) {
  return tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label)).selected;
}

void main() {
  testWidgets('Response panels are exclusive and keep a written draft', (
    tester,
  ) async {
    await showCard(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);

    await tapText(tester, 'Respond');
    expect(hintText(tester), 'Write a gentle response…');
    await tester.enterText(find.byType(TextField), 'My written draft');
    await tester.pump();

    await tapText(tester, 'Respond with feeling');
    expect(find.byType(ChoiceChip), findsNWidgets(7));
    expect(hintText(tester), 'Or write a gentle response…');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'My written draft',
    );
    expect(find.text('Respond'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    await tapChip(tester, 'I understand');
    expect(
      find.text('1 mama is here with you — mostly i understand.'),
      findsOneWidget,
    );
    expect(chipSelected(tester, 'I understand'), isTrue);
    expect(find.text('Close'), findsOneWidget);

    await tapChip(tester, 'I understand');
    expect(find.text('1'), findsOneWidget);

    await tapText(tester, 'Close');
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(TextField), findsNothing);

    await tapText(tester, 'Respond');
    expect(hintText(tester), 'Write a gentle response…');
    expect(find.byType(ChoiceChip), findsNothing);
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
    'Selected feelings stay unique and sit above written comments',
    (tester) async {
      await showCard(
        tester,
        replies: const [
          CircleReply(author: 'Another mother', body: 'Here for you'),
        ],
      );
      await tapText(tester, 'Respond with feeling');
      await tapChip(tester, 'I understand');
      await tapChip(tester, 'I understand');
      await tapChip(tester, "I'm here");

      expect(find.text('Another mother'), findsOneWidget);
      expect(find.text('Here for you'), findsOneWidget);
      expect(
        find.text(
          "1 mama is here with you — mostly i understand and i'm here.",
        ),
        findsOneWidget,
      );
      expect(find.text('1'), findsNWidgets(2));
      expect(find.textContaining('Anonymous:'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Here for you')).dy,
        greaterThan(
          tester
              .getTopLeft(
                find.text('Some days I just need a moment to breathe.'),
              )
              .dy,
        ),
      );
      expect(
        tester.getTopLeft(find.text('Here for you')).dy,
        lessThan(tester.getTopLeft(find.text('Respond')).dy),
      );
      expect(
        tester.getTopLeft(find.text('I understand').first).dy,
        lessThan(tester.getTopLeft(find.text('Here for you')).dy),
      );
    },
  );

  testWidgets(
    'Feeling send waits for success and does not send a feeling twice',
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
      await tapChip(tester, "I'm here");
      expect(sent.single.toJson(), {
        'circle_response': {
          'body': "I'm here",
          'feeling_key': 'im_here',
          'anonymous': true,
        },
      });
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Close'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Holding you')).onSelected,
        isNull,
      );

      completion.complete();
      await tester.pump();
      expect(chipSelected(tester, "I'm here"), isTrue);

      await tapChip(tester, "I'm here");
      expect(sent, hasLength(1));

      await tapText(tester, 'Respond');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets('A feeling the user already sent starts selected', (tester) async {
    final sent = <CircleResponseDraft>[];
    await showCard(
      tester,
      myMoods: const ['holding_you'],
      feelings: const [
        CircleFeelingCount(key: 'holding_you', label: 'Holding you', count: 3),
        CircleFeelingCount(key: 'i_understand', label: 'I understand', count: 2),
      ],
      mamaCount: 9,
      onSend: (draft) async {
        sent.add(draft);
      },
    );

    expect(
      find.text('9 mamas are here with you — mostly holding you and i understand.'),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tapText(tester, 'Respond with feeling');
    expect(chipSelected(tester, 'Holding you'), isTrue);
    expect(chipSelected(tester, 'I understand'), isFalse);

    await tapChip(tester, 'Holding you');
    await tester.pump();
    expect(sent, isEmpty);

    await tapChip(tester, 'This feels heavy');
    await tester.pump();
    expect(sent.single.feelingKey, 'this_feels_heavy');
    expect(chipSelected(tester, 'This feels heavy'), isTrue);
  });

  testWidgets('More than four feelings collapse behind + more', (tester) async {
    await showCard(
      tester,
      mamaCount: 9,
      feelings: const [
        CircleFeelingCount(key: 'holding_you', label: 'Holding you', count: 3),
        CircleFeelingCount(key: 'i_understand', label: 'I understand', count: 2),
        CircleFeelingCount(key: 'youre_doing_okay', label: "You're doing okay", count: 2),
        CircleFeelingCount(key: 'im_here', label: "I'm here", count: 1),
        CircleFeelingCount(key: 'take_a_breath', label: 'Take a breath', count: 1),
      ],
    );

    expect(find.text('Take a breath'), findsNothing);
    expect(find.text('+1 more'), findsOneWidget);
    await tapText(tester, '+1 more');
    expect(find.text('Take a breath'), findsOneWidget);
    expect(find.text('+1 more'), findsNothing);
  });

  testWidgets('Comments show 10 at a time, then load more', (tester) async {
    await showCard(
      tester,
      replies: [
        for (var i = 0; i < 12; i++)
          CircleReply(author: 'A Mum', body: 'Comment $i'),
      ],
    );

    expect(find.text('Comment 0'), findsNothing);
    expect(find.text('Comment 1'), findsNothing);
    expect(find.text('Comment 2'), findsOneWidget);
    expect(find.text('Comment 11'), findsOneWidget);
    expect(find.text('Load more'), findsOneWidget);

    await tapText(tester, 'Load more');
    expect(find.text('Comment 0'), findsOneWidget);
    expect(find.text('Comment 1'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
  });

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
    'Written comments stay visible and only the seven feelings are offered',
    (tester) async {
      await showCard(
        tester,
        replies: const [CircleReply(author: 'Anonymous', body: 'I understand')],
      );
      expect(find.text('I understand'), findsOneWidget);
      await tapText(tester, 'Respond with feeling');
      expect(find.byType(ChoiceChip), findsNWidgets(7));
      expect(find.text('I understand'), findsNWidgets(2));
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
    await tapChip(tester, 'Take a breath');
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

  test('post payload keeps feelings out of the comment list', () {
    final payload = CirclePostPayload.fromJson({
      'mama_count': 2,
      'my_moods': ['holding_you', 'im_here'],
      'feelings': [
        {'key': 'holding_you', 'label': 'Holding you', 'count': 2},
      ],
      'comments': [
        {'author': 'A Mum', 'text': 'You are held.', 'kind': 'text'},
      ],
      'responses': [
        {
          'kind': 'mood',
          'mood_key': 'holding_you',
          'text': 'Holding you',
          'mine': true,
        },
        {'kind': 'text', 'text': 'You are held.', 'author': 'A Mum'},
      ],
    });

    expect(payload.comments.map((comment) => comment.body), ['You are held.']);
    expect(payload.myMoods, ['holding_you', 'im_here']);
    expect(payload.feelings.single.count, 2);
    expect(payload.mamaCount, 2);
  });
}
