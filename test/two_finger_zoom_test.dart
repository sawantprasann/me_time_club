import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:me_time_club/widgets/two_finger_zoom.dart';

void main() {
  testWidgets(
    'two-finger pinch enlarges the app and keeps the bottom tappable',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: TwoFingerZoom(
            child: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text(
                      '${MediaQuery.sizeOf(context).height}',
                      key: const Key('height'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => taps++,
                      child: const Text('Bottom'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      final before = _height(tester);
      final first = await tester.startGesture(const Offset(420, 180));
      final second = await tester.startGesture(const Offset(420, 380));
      await second.moveBy(const Offset(0, 160));
      await tester.pump();
      await first.up();
      await second.up();
      await tester.pump();

      expect(_height(tester), lessThan(before * 0.7));

      await tester.tap(find.text('Bottom'));
      await tester.pump();
      expect(taps, 1);
    },
  );

  testWidgets('one finger still scrolls and does not zoom', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: TwoFingerZoom(
          child: Column(
            children: [
              Builder(
                builder:
                    (context) => Text(
                      '${MediaQuery.sizeOf(context).height}',
                      key: const Key('height'),
                    ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: const [
                    SizedBox(height: 1400, child: Text('Top of list')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final before = _height(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();

    expect(controller.offset, greaterThan(50));
    expect(_height(tester), before);
  });
}

double _height(WidgetTester tester) {
  return double.parse(
    tester.widget<Text>(find.byKey(const Key('height'))).data!,
  );
}
