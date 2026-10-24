import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:me_time_club/main.dart';
import 'package:me_time_club/models/user_profile.dart';
import 'package:me_time_club/screens/auth/login_screen.dart';
import 'package:me_time_club/screens/tabs/home_tab.dart';
import 'package:me_time_club/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Voice controls animate continuously, so advance a bounded number of frames.
Future<void> pumpApp(WidgetTester tester) async {
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  void saveSession({String? token = 'saved-token'}) {
    SharedPreferences.setMockInitialValues({
      'user_profile': jsonEncode(
        UserProfile(name: 'Test user', token: token).toJson(),
      ),
    });
  }

  testWidgets('Expired saved session opens login and can sign in again', (
    tester,
  ) async {
    saveSession();
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MeTimeClubApp());
        await pumpApp(tester);

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeTab), findsNothing);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('user_profile'), isNull);

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'test@example.com',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'new-password',
        );
        await tester.ensureVisible(find.text('Enter Sanctuary'));
        await tester.tap(find.text('Enter Sanctuary'));
        await pumpApp(tester);
        await tester.pump(const Duration(seconds: 2));
        await pumpApp(tester);

        expect(find.byType(HomeTab), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(
          jsonDecode(prefs.getString('user_profile')!)['token'],
          'new-token',
        );
      },
      () => MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({
              'token': 'new-token',
              'user': {'name': 'Test user'},
            }),
            200,
          );
        }
        if (request.headers['Authorization'] == 'Bearer new-token') {
          return http.Response('{}', 404);
        }
        // Even an empty/non-JSON 401 must invalidate the session.
        return http.Response('', 401);
      }),
    );
  });

  testWidgets('Missing saved token opens login without an API request', (
    tester,
  ) async {
    saveSession(token: null);
    var requests = 0;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MeTimeClubApp());
        await pumpApp(tester);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(requests, 0);
        expect(
          (await SharedPreferences.getInstance()).getString('user_profile'),
          isNull,
        );
      },
      () => MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
  });

  for (final status in [404, 500]) {
    testWidgets('HTTP $status keeps the saved session', (tester) async {
      saveSession();
      await http.runWithClient(() async {
        await tester.pumpWidget(const MeTimeClubApp());
        await pumpApp(tester);
        expect(find.byType(HomeTab), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(
          (await SharedPreferences.getInstance()).getString('user_profile'),
          isNotNull,
        );
      }, () => MockClient((_) async => http.Response('{}', status)));
    });
  }

  testWidgets('Network failure keeps the saved session', (tester) async {
    saveSession();
    await http.runWithClient(() async {
      await tester.pumpWidget(const MeTimeClubApp());
      await pumpApp(tester);
      expect(find.byType(HomeTab), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getString('user_profile'),
        isNotNull,
      );
    }, () => MockClient((_) async => throw http.ClientException('Offline')));
  });

  testWidgets('Late unauthorized response for an old token is ignored', (
    tester,
  ) async {
    saveSession();
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MeTimeClubApp());
        await pumpApp(tester);
        await expectLater(
          ApiService.getProfile(token: 'old-token'),
          throwsA(isA<SessionExpiredException>()),
        );
        await pumpApp(tester);
        expect(find.byType(HomeTab), findsOneWidget);
        expect(
          (await SharedPreferences.getInstance()).getString('user_profile'),
          isNotNull,
        );
      },
      () => MockClient(
        (request) async => http.Response(
          '{}',
          request.headers['Authorization'] == 'Bearer old-token' ? 401 : 404,
        ),
      ),
    );
  });

  testWidgets('Concurrent unauthorized responses safely open login', (
    tester,
  ) async {
    saveSession();
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MeTimeClubApp());
        await pumpApp(tester);
        await Future.wait([
          expectLater(
            ApiService.getProfile(token: 'saved-token'),
            throwsA(isA<SessionExpiredException>()),
          ),
          expectLater(
            ApiService.fetchMonthTasks(token: 'saved-token', month: '2026-10'),
            throwsA(isA<SessionExpiredException>()),
          ),
        ]);
        await pumpApp(tester);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(
          (await SharedPreferences.getInstance()).getString('user_profile'),
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
      () => MockClient(
        (request) async => http.Response(
          '{}',
          request.url.path.contains('/daily_pages/') ? 404 : 401,
        ),
      ),
    );
  });

  test('Invalid login credentials do not emit session expiry', () async {
    final expiredTokens = <String>[];
    final subscription = ApiService.sessionExpired.listen(expiredTokens.add);
    try {
      await http.runWithClient(
        () async {
          await expectLater(
            ApiService.login(email: 'test@example.com', password: 'wrong'),
            throwsA(
              isA<ApiException>().having(
                (error) => error.message,
                'message',
                'Invalid credentials.',
              ),
            ),
          );
          await Future<void>.delayed(Duration.zero);
          expect(expiredTokens, isEmpty);
        },
        () => MockClient(
          (_) async => http.Response('{"error":"Invalid credentials."}', 401),
        ),
      );
    } finally {
      await subscription.cancel();
    }
  });
}
