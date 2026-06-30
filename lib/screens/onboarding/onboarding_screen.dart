import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../models/user_profile.dart';
import '../../widgets/voice_text_input.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/api_service.dart';

/// 5-screen onboarding & registration flow.
/// Screen 0: Welcome · Screen 1: Name + Phase · Screen 2: Journey · Screen 3: Hardships · Screen 4: Email Register
class OnboardingScreen extends StatefulWidget {
  final Function(UserProfile) onComplete;
  final VoidCallback onNavigateToLogin;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.onNavigateToLogin,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  String _name = '';
  List<String> _phases = [];
  String? _pregnancyMonth;
  int _childCount = 0;
  List<String> _journey = [];
  String _bio = '';
  List<String> _hardships = [];
  String _hardshipsText = '';

  // Registration step form states
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 4) {
      setState(() => _step++);
    }
  }

  void _prev() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  void _complete(UserProfile user) {
    widget.onComplete(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _step == 0 ? const Color(0xFF2C2825) : AppTokens.day.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildWelcome();
      case 1:
        return SafeArea(child: _buildNamePhase());
      case 2:
        return SafeArea(child: _buildJourney());
      case 3:
        return SafeArea(child: _buildHardships());
      case 4:
        return SafeArea(child: _buildEmailRegister());
      default:
        return _buildWelcome();
    }
  }

  // ─── Screen 0: Welcome ───────────────────────────
  Widget _buildWelcome() {
    return Container(
      key: const ValueKey('welcome'),
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF1E1C1A)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset('assets/chamomile_background.png', fit: BoxFit.cover),
          // Dark overlay to match design
          Container(color: const Color(0xFF2C2825).withValues(alpha: 0.65)),
          // Gradient for soft vignette
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          // Screen contents wrapped in SafeArea
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // Brand Title
                  Text(
                    'Me Time Club',
                    style: AppTypography.playfair(38, const Color(0xFFF5F0E8)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Subtitle
                  Text(
                    'Your daily sanctuary.',
                    style: AppTypography.cormorantItalic(
                      20,
                      const Color(0xFFC4945A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Line divider
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    width: 44,
                    height: 1.5,
                    color: const Color(0xFFB8706A).withValues(alpha: 0.6),
                  ),
                  // Description
                  Text(
                    'A calm, intelligent companion for every\nseason of motherhood.',
                    style: AppTypography.lato400(
                      14.5,
                      const Color(0xFFF5F0E8).withValues(alpha: 0.8),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 2),
                  // CTA button
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8706A).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFB8706A,
                            ).withValues(alpha: 0.33),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Welcome to Me Time Club',
                          style: AppTypography.playfair(17, Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: widget.onNavigateToLogin,
                    child: Text(
                      'Already a member? Sign In',
                      style: AppTypography.lato400(
                        14,
                        const Color(0xFFC4945A),
                      ).copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Meet Chamomile ✦ She is waiting for you',
                    style: AppTypography.lato300(
                      11,
                      const Color(0xFFF5F0E8).withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Screen 1: Name + Phase ──────────────────────
  Widget _buildPhaseChip(String phase, AppTokens t) {
    final id = phase.split(' ')[0].toLowerCase();
    final sel = _phases.contains(id);
    return ChipButton(
      label: phase,
      selected: sel,
      onTap: () {
        setState(() {
          if (sel) {
            _phases.clear();
            if (id == 'expecting') _pregnancyMonth = null;
          } else {
            _phases = [id];
            if (id != 'expecting') _pregnancyMonth = null;
          }
        });
      },
      color: t.accent,
      t: t,
    );
  }

  Widget _buildNamePhase() {
    final t = AppTokens.day;
    final pregnancyMonths = [
      '1-4 weeks',
      '5-8 weeks',
      '9-12 weeks',
      '13-16 weeks',
      '17-20 weeks',
      '21-24 weeks',
      '25-28 weeks',
      '29-32 weeks',
      '33-36 weeks',
      '37-40 weeks',
    ];

    return Column(
      children: [
        _buildHeader(0),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('name'),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'What should we call you?',
                  style: AppTypography.playfair(30, t.text),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "You are more than a mother. Let's start with you.",
                  style: AppTypography.cormorantItalic(16, t.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: VoiceTextInput(
                    value: _name,
                    onChange: (v) => setState(() => _name = v),
                    placeholder: 'Your name...',
                    t: t,
                    textAlign: TextAlign.start,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Where are you in your motherhood right now?',
                  style: AppTypography.cormorantItalic(16, t.text),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Motherhood holds many seasons — choose where you are right now.',
                  style: AppTypography.lato400(13, t.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  children:
                      [
                        'Expecting',
                        'Newborn (0-6m)',
                        'Baby (6-18m)',
                        'Toddler (18m-3y)',
                        'Preschool (3-5y)',
                        'School Age (5+)',
                      ].map((phase) {
                        return _buildPhaseChip(phase, t);
                      }).toList(),
                ),
                // Pregnancy month picker
                if (_phases.contains('expecting')) ...[
                  const SizedBox(height: 20),
                  Text(
                    'How far along are you?',
                    style: AppTypography.cormorantItalic(15, t.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children:
                        pregnancyMonths.map((m) {
                          final sel = _pregnancyMonth == m;
                          return GestureDetector(
                            onTap: () => setState(() => _pregnancyMonth = m),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: sel ? t.accent : t.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel ? t.accent : t.border,
                                ),
                              ),
                              child: Text(
                                m,
                                style: AppTypography.lato400(
                                  11,
                                  sel ? Colors.white : t.muted,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
                // Child count stepper
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'How many little ones?',
                      style: AppTypography.cormorantItalic(16, t.text),
                    ),
                    const SizedBox(width: 24),
                    _stepperBtn('−', () {
                      if (_childCount > 0) setState(() => _childCount--);
                    }, t),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_childCount',
                        style: AppTypography.playfair(22, t.text),
                      ),
                    ),
                    _stepperBtn('+', () => setState(() => _childCount++), t),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: CTAButton(
            label: 'Continue →',
            disabled: _name.trim().isEmpty,
            onTap: _next,
            t: t,
          ),
        ),
      ],
    );
  }

  // ─── Screen 2: Journey ───────────────────────────
  Widget _buildJourneyChip(String option, AppTokens t) {
    final sel = _journey.contains(option);
    return ChipButton(
      label: option,
      selected: sel,
      onTap: () {
        setState(() {
          if (sel) {
            _journey.remove(option);
          } else {
            _journey = [..._journey, option];
          }
        });
      },
      color: t.gold,
      t: t,
    );
  }

  Widget _buildJourney() {
    final t = AppTokens.day;

    return Column(
      children: [
        _buildHeader(1),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('journey'),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'What makes your journey yours?',
                  style: AppTypography.playfair(30, t.text),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Chamomile listens better when she knows you a little more. Take what feels right, leave what doesn't.",
                  style: AppTypography.cormorantItalic(16, t.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  children:
                      [
                        'First-time mother',
                        'Second-time mother',
                        'Third time (or more)',
                        'Single mother',
                        "Single father — we see you, and we'd love to build something for you too",
                        'Co-parenting',
                        'Working mother',
                        'Stay-at-home mother',
                        'IVF / fertility journey',
                        'Loss and healing',
                        'Adoptive parent',
                        'Neurodivergent child',
                        'Postpartum recovery',
                        'Blended family',
                      ].map((j) {
                        return _buildJourneyChip(j, t);
                      }).toList(),
                ),
                const SizedBox(height: 20),
                VoiceTextArea(
                  value: _bio,
                  onChange: (v) => setState(() => _bio = v),
                  placeholder:
                      'Or just tell Chamomile anything about you, in your own words...',
                  t: t,
                  rows: 3,
                  micSize: 32,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CTAButton(label: 'Continue →', onTap: _next, t: t),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _next,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'I\'ll share this later',
                    style: AppTypography.lato400(
                      13,
                      t.muted,
                    ).copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Screen 3: Hardships ─────────────────────────
  Widget _buildHardships() {
    final t = AppTokens.day;
    final hardshipOptions = [
      'Overwhelm',
      'Loneliness',
      'Sleep exhaustion',
      'Burnout',
      'Mom guilt',
      'Identity loss',
      'Mental load',
      'Need calm',
      'Finding time for myself',
    ];

    return Column(
      children: [
        _buildHeader(2),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('hardships'),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'What feels heaviest right now?',
                  style: AppTypography.playfair(30, t.text),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This helps Chamomile meet you exactly where you are.\nYou can speak it, tap it, or skip it entirely.',
                  style: AppTypography.cormorantItalic(
                    16,
                    t.muted,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  children:
                      hardshipOptions.map((h) {
                        final sel = _hardships.contains(h);
                        return ChipButton(
                          label: h,
                          selected: sel,
                          onTap: () {
                            setState(() {
                              if (sel) {
                                _hardships.remove(h);
                              } else {
                                _hardships = [..._hardships, h];
                              }
                            });
                          },
                          color: t.green,
                          t: t,
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),
                VoiceTextArea(
                  value: _hardshipsText,
                  onChange: (v) => setState(() => _hardshipsText = v),
                  placeholder: 'Or speak or write what\'s on your heart…',
                  t: t,
                  rows: 3,
                  micSize: 32,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CTAButton(label: 'Enter My Sanctuary →', onTap: _next, t: t),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _next,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'I\'ll share this later',
                    style: AppTypography.lato400(
                      13,
                      t.muted,
                    ).copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────
  Widget _buildHeader(int activeIndex) {
    final t = AppTokens.day;
    return Container(
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildProgressDots(activeIndex),
          Positioned(
            left: 8,
            child: GestureDetector(
              onTap: _prev,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: t.muted,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots(int activeIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i <= activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 26,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppTokens.day.accent : AppTokens.day.border,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _stepperBtn(String label, VoidCallback onTap, AppTokens t) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: t.border, width: 1.5),
          color: t.card,
        ),
        child: Center(
          child: Text(label, style: AppTypography.lato700(18, t.text)),
        ),
      ),
    );
  }

  Widget _buildEmailRegister() {
    final t = AppTokens.day;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildHeader(2),
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('email_register'),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Me Time Club',
                    style: AppTypography.playfair(34, t.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Secure Your Sanctuary',
                    style: AppTypography.cormorantItalic(24, t.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email to complete registration and enter Me Time Club.',
                    style: AppTypography.lato400(13.5, t.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTypography.lato400(15, t.text),
                    decoration: InputDecoration(
                      hintText: 'email@example.com',
                      hintStyle: AppTypography.lato400(15, t.muted),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: t.muted,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: t.card,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: t.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: t.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: t.accent, width: 1.5),
                      ),
                      errorStyle: AppTypography.lato400(12, t.accent),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                      ).hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: AppTypography.lato400(15, t.text),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: AppTypography.lato400(15, t.muted),
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: t.muted,
                        size: 20,
                      ),
                      suffixIcon: GestureDetector(
                        onTap:
                            () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: t.muted,
                          size: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: t.card,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: t.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: t.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: t.accent, width: 1.5),
                      ),
                      errorStyle: AppTypography.lato400(12, t.accent),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: t.accent, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.lato400(12, t.accent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: CTAButton(
              label: 'Complete Registration',
              onTap: _registerUser,
              loading: _loading,
              t: t,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerUser() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    String getJourneyStage() {
      if (_phases.isEmpty) return 'expecting';
      final first = _phases.first;
      switch (first) {
        case 'expecting':
          return 'expecting';
        case 'newborn':
          return 'newborn';
        case 'baby':
          return 'baby';
        case 'toddler':
          return 'toddler';
        case 'preschool':
          return 'preschool';
        case 'school_age':
          return 'school_age';
        default:
          return 'expecting';
      }
    }

    List<String> mapHardships(List<String> rawHardships) {
      return rawHardships.map((h) {
        switch (h.toLowerCase()) {
          case 'overwhelm':
            return 'overwhelm';
          case 'loneliness':
            return 'loneliness';
          case 'sleep exhaustion':
            return 'sleep_deprivation';
          case 'burnout':
            return 'burnout';
          case 'mom guilt':
            return 'mom_guilt';
          case 'identity loss':
            return 'identity_loss';
          case 'mental load':
            return 'mental_load';
          case 'need calm':
            return 'need_calm';
          case 'finding time for myself':
            return 'finding_time_for_myself';
          default:
            return h.toLowerCase().replaceAll(' ', '_');
        }
      }).toList();
    }

    List<String> mapJourneyTags(List<String> rawJourney) {
      return rawJourney.map((j) {
        if (j.contains('First-time')) return 'first_time_mother';
        if (j.contains('Second-time')) return 'second_time_mother';
        if (j.contains('Third time')) return 'third_time_or_more';
        if (j.contains('Single mother')) return 'single_mother';
        if (j.contains('Single father')) return 'single_father';
        if (j.contains('Co-parenting')) return 'co_parenting';
        if (j.contains('Working mother')) return 'working_mother';
        if (j.contains('Stay-at-home')) return 'stay_at_home_mother';
        if (j.contains('IVF')) return 'ivf_fertility_journey';
        if (j.contains('Loss')) return 'loss_and_healing';
        if (j.contains('Adoptive')) return 'adoptive_parent';
        if (j.contains('Neurodivergent')) return 'neurodivergent_child';
        if (j.contains('Postpartum')) return 'postpartum_recovery';
        if (j.contains('Blended')) return 'blended_family';
        return j.toLowerCase().replaceAll(' ', '_');
      }).toList();
    }

    try {
      final userParams = {
        'email': _emailController.text.trim(),
        'name': _name.trim(),
        'display_name': _name.trim(),
        'password': _passwordController.text,
        'password_confirmation': _passwordController.text,
        'journey_stage': getJourneyStage(),
        'primary_phase': getJourneyStage(),
        'pregnancy_week': _pregnancyMonth?.replaceAll(' weeks', ''),
        'child_count': _childCount,
        'bio': _bio,
        'free_text': _hardshipsText,
        'hardships': mapHardships(_hardships),
        'hardships_text': _hardshipsText,
        'journey_tags': mapJourneyTags(_journey),
        'journey_text': _bio,
      };

      final userProfile = await ApiService.register(userParams: userParams);

      final completedProfile = userProfile.copyWith(
        phases: _phases,
        pregnancyMonth: _pregnancyMonth,
        childCount: _childCount,
        journey: _journey,
        bio: _bio,
        hardships: _hardships,
        hardshipsText: _hardshipsText,
      );

      _complete(completedProfile);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Registration failed. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }
}
