import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:me_time_club/models/gentle_read.dart';
import 'package:me_time_club/theme/tokens.dart';
import 'package:me_time_club/widgets/gentle_read_post.dart';

void main() {
  for (var combination = 0; combination < 8; combination++) {
    final hasImage = combination & 1 != 0;
    final hasText = combination & 2 != 0;
    final hasLink = combination & 4 != 0;

    test('Parses optional content combination $combination', () {
      final read = GentleRead.fromJson({
        'id': 1,
        if (hasImage) 'image_url': '/uploads/read.png',
        if (hasText) 'body': 'A short moment of calm.',
        if (hasLink) 'link_url': 'https://example.com/read',
      });
      expect(read.title, isEmpty);
      expect(read.body, hasText ? 'A short moment of calm.' : '');
      expect(read.imageUrl, hasImage ? '/uploads/read.png' : null);
      expect(read.linkUrl, hasLink ? 'https://example.com/read' : null);
    });

    testWidgets('Renders optional content combination $combination', (
      tester,
    ) async {
      final opened = <Uri>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GentleReadPost(
                read: GentleRead(
                  id: 1,
                  body: hasText ? 'A short moment of calm.' : '',
                  imageUrl: hasImage ? '/uploads/read.png' : null,
                  linkUrl: hasLink ? 'https://example.com/read' : null,
                ),
                t: AppTokens.day,
                baseUri: Uri.parse('https://api.example.com'),
                onOpenLink: opened.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('GENTLE READ'), findsOneWidget);
      expect(
        find.text('A short moment of calm.'),
        hasText ? findsOneWidget : findsNothing,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is NetworkImage &&
              (widget.image as NetworkImage).url ==
                  'https://api.example.com/uploads/read.png',
        ),
        hasImage ? findsOneWidget : findsNothing,
      );
      expect(find.text('example.com'), hasLink ? findsOneWidget : findsNothing);
      if (hasLink) {
        await tester.ensureVisible(find.text('example.com'));
        await tester.tap(find.text('example.com'));
        expect(opened, [Uri.parse('https://example.com/read')]);
      }
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'Accepts nulls, blank fields, and the alternative text/image/link payload',
    () {
      final blank = GentleRead.fromJson({
        'id': 2,
        'body': null,
        'image_url': '  ',
        'link_url': null,
      });
      expect(blank.body, isEmpty);
      expect(blank.imageUrl, isNull);
      expect(blank.linkUrl, isNull);
      final read = GentleRead.fromJson({
        'id': 3,
        'text': 'One word.',
        'image': {'url': '/photo.jpg'},
        'link': 'https://example.com',
        'link_label': 'Read the story',
      });
      expect(read.body, 'One word.');
      expect(read.imageUrl, '/photo.jpg');
      expect(read.linkUrl, 'https://example.com');
      expect(read.linkLabel, 'Read the story');
    },
  );

  testWidgets(
    'Unsafe link schemes are omitted and long captions remain expandable',
    (tester) async {
      final body = List.filled(
        40,
        'A little kindness goes a long way.',
      ).join(' ');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GentleReadPost(
                read: GentleRead(
                  id: 4,
                  body: body,
                  linkUrl: 'javascript:alert(1)',
                ),
                t: AppTokens.night,
                baseUri: Uri.parse('https://api.example.com'),
                onOpenLink: (_) => fail('The unsafe link must not be opened.'),
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.link_rounded), findsNothing);
      expect(find.text('Read more'), findsOneWidget);
      await tester.ensureVisible(find.text('Read more'));
      await tester.tap(find.text('Read more'));
      await tester.pump();
      expect(find.text('Show less'), findsOneWidget);
      expect(tester.widget<Text>(find.text(body)).maxLines, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A story without a photo uses the text card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GentleReadPost(
              read: const GentleRead(
                id: 6,
                title: 'The cup that waited',
                body: 'She made tea at seven.\n\nShe drank it slowly.',
              ),
              t: AppTokens.day,
              baseUri: Uri.parse('https://api.example.com'),
              onOpenLink: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('10-WORD STORY'), findsOneWidget);
    expect(find.text('The cup that waited'), findsOneWidget);
    expect(find.text('She made tea at seven.'), findsOneWidget);
    expect(find.text('She drank it slowly.'), findsOneWidget);
    expect(find.textContaining('Me Time Club'), findsOneWidget);
    expect(find.byType(AspectRatio), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A photo uses the Instagram portrait shape', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GentleReadPost(
              read: const GentleRead(
                id: 5,
                body: 'A quiet line.',
                imageUrl: '/uploads/read.png',
              ),
              t: AppTokens.day,
              baseUri: Uri.parse('https://api.example.com'),
              onOpenLink: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio,
      4 / 5,
    );
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dots slide between the three reads', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GentleReadPost(
              read: const GentleRead(id: 5, title: 'First', body: 'One.'),
              reads: const [
                GentleRead(id: 5, title: 'First', body: 'One.'),
                GentleRead(id: 6, title: 'Second', body: 'Two.'),
                GentleRead(id: 7, title: 'Third', body: 'Three.'),
              ],
              t: AppTokens.day,
              baseUri: Uri.parse('https://api.example.com'),
              onOpenLink: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('GENTLE READ'), findsOneWidget);
    expect(find.text('1 of 3 · tap dots to browse'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    await tester.tap(find.byKey(const ValueKey('gentle-read-dot-2')));
    await tester.pumpAndSettle();
    expect(find.text('3 of 3 · tap dots to browse'), findsOneWidget);
    expect(find.text('Third'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
