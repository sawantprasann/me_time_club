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

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final userProfile = await ApiService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      widget.onLoginSuccess(userProfile);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.day;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1C1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/chamomile_background.png',
            fit: BoxFit.cover,
          ),
          // Cozy Overlay
          Container(
            color: const Color(0xFF2C2825).withValues(alpha: 0.75),
          ),
          // Soft Vignette Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          // Form Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Brand Logo Image
                      Text(
                        'Me Time Club',
                        style: AppTypography.playfair(34, const Color(0xFFF5F0E8)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your daily sanctuary.',
                        style: AppTypography.cormorantItalic(18, const Color(0xFFC4945A)),
                        textAlign: TextAlign.center,
                      ),
                      
                      // Decorative line
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        width: 40,
                        height: 1.5,
                        color: const Color(0xFFB8706A).withValues(alpha: 0.5),
                      ),

                      // Card wrapper for inputs
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2825).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE8DDD5).withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SIGN IN',
                              style: AppTypography.sectionLabel(const Color(0xFFC4945A)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Welcome back. Enter your email to step into your sanctuary.',
                              style: AppTypography.lato400(
                                13.5,
                                const Color(0xFFF5F0E8).withValues(alpha: 0.7),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Email input field
                             TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTypography.lato400(15, const Color(0xFFF5F0E8)),
                              decoration: InputDecoration(
                                hintText: 'email@example.com',
                                hintStyle: AppTypography.lato400(15, const Color(0xFF8A7D76)),
                                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF8A7D76), size: 20),
                                filled: true,
                                fillColor: const Color(0xFF1E1C1A),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: const Color(0xFFE8DDD5).withValues(alpha: 0.15),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: const Color(0xFFE8DDD5).withValues(alpha: 0.15),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFB8706A), width: 1.5),
                                ),
                                errorStyle: AppTypography.lato400(12, const Color(0xFFB8706A)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!_isValidEmail(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: AppTypography.lato400(15, const Color(0xFFF5F0E8)),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: AppTypography.lato400(15, const Color(0xFF8A7D76)),
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF8A7D76), size: 20),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                  child: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFF8A7D76),
                                    size: 20,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1E1C1A),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: const Color(0xFFE8DDD5).withValues(alpha: 0.15),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: const Color(0xFFE8DDD5).withValues(alpha: 0.15),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFB8706A), width: 1.5),
                                ),
                                errorStyle: AppTypography.lato400(12, const Color(0xFFB8706A)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),

                            // Error Display
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Color(0xFFB8706A), size: 16),
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

                            // Action button
                            CTAButton(
                              label: 'Enter Sanctuary',
                              onTap: _submit,
                              loading: _loading,
                              t: t,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Navigation to register
                      GestureDetector(
                        onTap: _loading ? null : widget.onNavigateToRegister,
                        child: Text(
                          "New here? Create an account",
                          style: AppTypography.lato400(14, const Color(0xFFF5F0E8)).copyWith(
                            decoration: TextDecoration.underline,
                            color: const Color(0xFFC4945A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
