import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:me_time_club/models/user_profile.dart';
import 'package:me_time_club/screens/tabs/calendar_tab.dart';
import 'package:me_time_club/theme/tokens.dart';

String Function(String method, Uri url) cycleHttpBody = (method, url) => '[]';

int Function(String method, Uri url) cycleHttpStatus = (method, url) {
  if (method == 'GET' && url.path.contains('/daily_pages/')) return 404;
  return 200;
};

void main() {
  setUp(() {
    cycleHttpBody = (method, url) => '[]';
    cycleHttpStatus = (method, url) {
      if (method == 'GET' && url.path.contains('/daily_pages/')) return 404;
      return 200;
    };
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  testWidgets('add confirmation asks before marking today and the next 2 days', (
    tester,
  ) async {
    await _pumpCalendar(tester);

    expect(find.text('CYCLE TRACKER'), findsOneWidget);
    expect(
      find.text('No cycle days tracked yet. Tap + to begin.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('cycle-header-action')));
    await tester.pump();

    final today = DateTime.now();
    final label = '${today.day} ${_shortMonths[today.month - 1]}';
    expect(find.text('Mark $label as start of cycle?'), findsOneWidget);
    expect(
      find.text(
        'This will mark today and the following 2 days. Your full history stays safe.',
      ),
      findsOneWidget,
    );
    expect(find.text('Yes, confirm'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(
      find.text('No cycle days tracked yet. Tap + to begin.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(find.text('Mark $label as start of cycle?'), findsNothing);
    expect(
      find.text('No cycle days tracked yet. Tap + to begin.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'remove confirmation names the period and keeps history visible',
    (tester) async {
      final today = DateTime.now();
      cycleHttpBody = (method, url) {
        if (method == 'GET' && url.path.endsWith('/cycle_days')) {
          return _cycleJson(today);
        }
        return '[]';
      };

      await _pumpCalendar(tester);
      await _waitFor(tester, find.text('YOUR CYCLE HISTORY'));

      expect(find.text(_label(today)), findsOneWidget);
      expect(
        find.text(_label(today.add(const Duration(days: 1)))),
        findsOneWidget,
      );
      expect(
        find.text(_label(today.add(const Duration(days: 2)))),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('cycle-header-action')),
      );
      await tester.tap(find.byKey(const ValueKey('cycle-header-action')));
      await tester.pump();

      expect(
        find.text('Remove cycle days from ${_label(today)}?'),
        findsOneWidget,
      );
      expect(
        find.text('This will unmark the selected days from your tracker.'),
        findsOneWidget,
      );
      expect(find.text('YOUR CYCLE HISTORY'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(
        find.text('Remove cycle days from ${_label(today)}?'),
        findsNothing,
      );
      expect(find.text('YOUR CYCLE HISTORY'), findsOneWidget);
      expect(find.text(_label(today)), findsOneWidget);
    },
  );
}

Future<void> _pumpCalendar(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CalendarTab(
          user: UserProfile(name: 'Ava'),
          t: AppTokens.day,
          dailyPages: const {},
          isActive: true,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.ensureVisible(find.text('CYCLE TRACKER'));
  await tester.pump();
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _label(DateTime d) => '${d.day} ${_shortMonths[d.month - 1]}';

String _cycleJson(DateTime start) {
  final rows = List.generate(3, (i) {
    final d = start.add(Duration(days: i));
    final key =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '{"id":${i + 1},"date_key":"$key"}';
  });
  return '[${rows.join(',')}]';
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _TestHttpClient();
}

class _TestHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _TestRequest(method, url);
}

class _TestRequest extends Fake implements HttpClientRequest {
  _TestRequest(this.method, this.url);

  final String method;
  final Uri url;
  final _headers = _TestHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  set followRedirects(bool value) {}

  @override
  set maxRedirects(int value) {}

  @override
  set contentLength(int value) {}

  @override
  set persistentConnection(bool value) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  Future<HttpClientResponse> close() async {
    final body = cycleHttpBody(method, url);
    return _TestResponse(cycleHttpStatus(method, url), body);
  }
}

class _TestHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _TestResponse extends Fake implements HttpClientResponse {
  _TestResponse(this.statusCode, this._body);

  @override
  final int statusCode;
  final String _body;

  @override
  int get contentLength => utf8.encode(_body).length;

  @override
  HttpHeaders get headers => _TestHeaders();

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(utf8.encode(_body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
