import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:me_time_club/screens/tabs/memories_tab.dart';
import 'package:me_time_club/theme/tokens.dart';

/// 1×1 png.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  testWidgets('a tap opens nothing but the photo, a long press opens actions', (
    tester,
  ) async {
    var opened = 0;
    var actions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemoryMomentCard(
            t: AppTokens.day,
            caption: 'Sun on the steps',
            accent: const Color(0xFFB8706A),
            photo: const ColoredBox(
              key: Key('photo'),
              color: Color(0xFFB8706A),
              child: SizedBox(width: 40, height: 80),
            ),
            onOpen: () => opened++,
            onLongPressActions: () => actions++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('photo')));
    await tester.pump();
    expect(opened, 1);
    expect(actions, 0);

    await tester.tap(find.text('Sun on the steps'));
    await tester.pump();
    expect(opened, 2);
    expect(actions, 0);

    await tester.longPress(find.text('Sun on the steps'));
    await tester.pump();
    expect(opened, 2);
    expect(actions, 1);
  });

  testWidgets('preview shows the whole photo and closes from the dark area', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    barrierColor: const Color(0xF2000000),
                    builder: (_) => MemoryPhotoPreview(
                      image: MemoryImage(_png),
                      caption: 'We sat in the sun.',
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final photo = tester.widget<Image>(find.byType(Image));
    expect(photo.fit, BoxFit.contain);
    expect(photo.width, isNotNull);
    expect(photo.height, isNotNull);
    expect(find.text('We sat in the sun.'), findsOneWidget);

    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();
    expect(find.text('We sat in the sun.'), findsOneWidget);

    await tester.tapAt(const Offset(24, 28));
    await tester.pumpAndSettle();
    expect(find.text('We sat in the sun.'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });
}
