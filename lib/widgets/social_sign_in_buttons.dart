import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/firebase_auth_service.dart';
import '../theme/tokens.dart';

class SocialSignInButtons extends StatefulWidget {
  final void Function(UserProfile user, bool profileComplete) onSuccess;
  final bool enabled;

  const SocialSignInButtons({
    super.key,
    required this.onSuccess,
    this.enabled = true,
  });

  @override
  State<SocialSignInButtons> createState() => _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends State<SocialSignInButtons> {
  String? _busyProvider;
  String? _errorMessage;

  Future<void> _signIn(String provider) async {
    if (!widget.enabled || _busyProvider != null) return;
    setState(() {
      _busyProvider = provider;
      _errorMessage = null;
    });

    try {
      final identity = await FirebaseAuthService.signIn(provider);
      FirebaseLoginResult session;
      try {
        session = await ApiService.loginWithFirebase(
          idToken: identity.idToken,
          name: identity.name,
        );
      } on ApiException catch (e) {
        if (e.code != 'name_required') rethrow;
        if (!mounted) return;
        final name = await _askForName();
        if (!mounted || name == null) return;
        session = await ApiService.loginWithFirebase(
          idToken: identity.idToken,
          name: name,
        );
      }
      if (!mounted) return;
      widget.onSuccess(session.user, session.profileComplete);
    } on SocialSignInCancelled {
      // The sheet was closed. Leave the screen as it was.
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message ?? 'Sign-in failed.');
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }

  Future<String?> _askForName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2825),
          title: Text(
            'What should we call you?',
            style: AppTypography.playfair(22, const Color(0xFFF5F0E8)),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: AppTypography.lato400(15, const Color(0xFFF5F0E8)),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: AppTypography.lato400(15, const Color(0xFF8A7D76)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTypography.lato400(14, const Color(0xFFC4945A)),
              ),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(context, name);
              },
              child: Text(
                'Continue',
                style: AppTypography.lato700(14, const Color(0xFFC4945A)),
              ),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _busyProvider != null || !widget.enabled;
    return Column(
      children: [
        _button(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata,
          provider: 'google',
          background: const Color(0xFFF5F0E8),
          foreground: const Color(0xFF1E1C1A),
          busy: busy,
        ),
        const SizedBox(height: 10),
        _button(
          label: 'Continue with Apple',
          icon: Icons.apple,
          provider: 'apple',
          background: const Color(0xFF1E1C1A),
          foreground: const Color(0xFFF5F0E8),
          busy: busy,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFB8706A),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: AppTypography.lato400(12, const Color(0xFFB8706A)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _button({
    required String label,
    required IconData icon,
    required String provider,
    required Color background,
    required Color foreground,
    required bool busy,
  }) {
    final loading = _busyProvider == provider;
    return GestureDetector(
      onTap: busy ? null : () => _signIn(provider),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE8DDD5).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foreground),
                ),
              )
            else
              Icon(icon, color: foreground, size: icon == Icons.apple ? 22 : 28),
            const SizedBox(width: 8),
            Text(label, style: AppTypography.lato700(15, foreground)),
          ],
        ),
      ),
    );
  }
}
