import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialSignInCancelled implements Exception {}

class FirebaseIdentity {
  final String idToken;
  final String? name;

  const FirebaseIdentity({required this.idToken, this.name});
}

/// Signs in with Google or Apple through Firebase and returns an ID token
/// for `POST /api/v1/auth/firebase`.
class FirebaseAuthService {
  static bool _googleReady = false;

  static Future<FirebaseIdentity> signIn(String provider) async {
    await _ensureInitialized();
    switch (provider) {
      case 'google':
        return _google();
      case 'apple':
        return _apple();
      default:
        throw FirebaseAuthException(
          code: 'unsupported',
          message: 'Use Google or Apple to sign in.',
        );
    }
  }

  static Future<void> _ensureInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    try {
      await Firebase.initializeApp();
    } on FirebaseException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message:
            'Google and Apple sign-in need the iOS and Android apps added in the Firebase project.',
      );
    }
  }

  static Future<FirebaseIdentity> _google() async {
    final clientId = await _iosGoogleClientId();
    if (defaultTargetPlatform == TargetPlatform.iOS && clientId == null) {
      throw FirebaseAuthException(
        code: 'missing-client-id',
        message:
            'Google sign-in is missing its iOS client ID. In Firebase, turn on Google under Authentication, download GoogleService-Info.plist again, and rebuild.',
      );
    }

    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS ? clientId : null,
      );
      _googleReady = true;
    }

    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw SocialSignInCancelled();
      }
      throw FirebaseAuthException(
        code: e.code.name,
        message: e.description ?? 'Google sign-in failed.',
      );
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-token',
        message: 'Google did not return a sign-in token.',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    return _identity(userCredential.user, fallbackName: account.displayName);
  }

  static Future<FirebaseIdentity> _apple() async {
    final rawNonce = _randomNonce();
    final nonce = _sha256(rawNonce);
    final AuthorizationCredentialAppleID apple;
    try {
      apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw SocialSignInCancelled();
      }
      rethrow;
    }

    final credential = OAuthProvider(
      'apple.com',
    ).credential(idToken: apple.identityToken, rawNonce: rawNonce);
    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final appleName = [
      apple.givenName,
      apple.familyName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
    return _identity(userCredential.user, fallbackName: appleName);
  }

  static Future<FirebaseIdentity> _identity(
    User? user, {
    String? fallbackName,
  }) async {
    final idToken = await user?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-token',
        message: 'Could not complete sign-in. Please try again.',
      );
    }
    final name = (user?.displayName ?? fallbackName)?.trim();
    return FirebaseIdentity(
      idToken: idToken,
      name: (name == null || name.isEmpty) ? null : name,
    );
  }

  static Future<String?> _iosGoogleClientId() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    try {
      final raw = await rootBundle.loadString(
        'ios/Runner/GoogleService-Info.plist',
      );
      return RegExp(
        r'<key>CLIENT_ID</key>\s*<string>([^<]+)</string>',
      ).firstMatch(raw)?.group(1);
    } catch (_) {
      return null;
    }
  }

  static String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
