import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  final Function(dynamic) onLoginSuccess;
  final VoidCallback onNavigateToRegister;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onNavigateToRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) =>
      RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+\.[a-zA-Z]+")
          .hasMatch(email);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final userProfile = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      widget.onLoginSuccess(userProfile);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'An error occurred. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1C1A),
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image
          Image.asset('assets/chamomile_background.png', fit: BoxFit.cover),

          // ── Layered gradient: dark top + dark bottom, clear mid
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.3, 0.65, 1.0],
                colors: [
                  Color(0xDD1A1714),
                  Color(0x771E1C1A),
                  Color(0xAA2C2825),
                  Color(0xF01A1714),
                ],
              ),
            ),
          ),

          // ── Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Form(
                key: _formKey,
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            const Spacer(flex: 3),

                            // ── Monogram badge
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFC4945A)
                                      .withValues(alpha: 0.45),
                                  width: 1.5,
                                ),
                                color: const Color(0xFF2C2825)
                                    .withValues(alpha: 0.65),
                              ),
                              child: Center(
                                child: Text(
                                  'M',
                                  style: AppTypography.playfair(
                                    30,
                                    const Color(0xFFC4945A),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Brand title
                            Text(
                              'Me Time Club',
                              style: AppTypography.playfair(
                                38,
                                const Color(0xFFF5F0E8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your daily sanctuary.',
                              style: AppTypography.cormorantItalic(
                                20,
                                const Color(0xFFC4945A),
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const Spacer(flex: 2),

                            // ── Labelled divider
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFFE8DDD5)
                                        .withValues(alpha: 0.12),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'WELCOME BACK',
                                    style: AppTypography.sectionLabel(
                                      const Color(0xFFC4945A)
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFFE8DDD5)
                                        .withValues(alpha: 0.12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // ── Email field
                            _FrostedField(
                              controller: _emailController,
                              hint: 'Email address',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.mail_outline_rounded,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!_isValidEmail(v.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // ── Password field
                            _FrostedField(
                              controller: _passwordController,
                              hint: 'Password',
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                  () =>
                                      _obscurePassword = !_obscurePassword,
                                ),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF8A7D76),
                                  size: 20,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),

                            // ── Error banner
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB8706A)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFB8706A)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: Color(0xFFB8706A),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: AppTypography.lato400(
                                          13,
                                          const Color(0xFFB8706A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 28),

                            // ── Primary CTA
                            _GradientButton(
                              label: 'Enter Sanctuary',
                              loading: _loading,
                              onTap: _submit,
                            ),

                            const Spacer(flex: 2),

                            // ── Footer links
                            GestureDetector(
                              onTap:
                                  _loading
                                      ? null
                                      : widget.onNavigateToRegister,
                              child: RichText(
                                text: TextSpan(
                                  style: AppTypography.lato400(
                                    14,
                                    const Color(0xFFF5F0E8)
                                        .withValues(alpha: 0.55),
                                  ),
                                  children: [
                                    const TextSpan(text: 'New here?   '),
                                    TextSpan(
                                      text: 'Create an account',
                                      style: AppTypography.lato700(
                                        14,
                                        const Color(0xFFC4945A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Meet Chamomile ✦ She is waiting for you',
                              style: AppTypography.lato300(
                                11,
                                const Color(0xFFF5F0E8).withValues(alpha: 0.3),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Frosted glass input field ────────────────────────────────────────────────
class _FrostedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _FrostedField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTypography.lato400(15, const Color(0xFFF5F0E8)),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.lato400(15, const Color(0xFF6E635D)),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF8A7D76),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF2C2825).withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFFE8DDD5).withValues(alpha: 0.13),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFFE8DDD5).withValues(alpha: 0.13),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFC4945A),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB8706A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFB8706A),
            width: 1.5,
          ),
        ),
        errorStyle: AppTypography.lato400(12, const Color(0xFFB8706A)),
      ),
    );
  }
}

// ─── Gradient CTA button ──────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedOpacity(
        opacity: loading ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFB8706A), Color(0xFFC4945A)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB8706A).withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    label,
                    style: AppTypography.playfair(17, Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
