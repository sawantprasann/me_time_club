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
      expect(find.text('GENTLE READS'), findsOneWidget);
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
      await tester.tap(find.text('Read more'));
      await tester.pump();
      expect(find.text('Show less'), findsOneWidget);
      expect(tester.widget<Text>(find.text(body)).maxLines, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
