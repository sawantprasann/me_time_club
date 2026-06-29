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

  void _next() {
    if (_step < 4) setState(() => _step++);
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  void _complete(UserProfile user) => widget.onComplete(user);

  // ── Warm background decoration for steps 1-4 ────────────────────────────
  static const _stepBg = Color(0xFFF8F3EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _step == 0 ? const Color(0xFF1E1C1A) : _stepBg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: _buildStep(),
        ),
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

  // ─── Screen 0: Welcome ───────────────────────────────────────────────────
  Widget _buildWelcome() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF1E1C1A)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/chamomile_background.png', fit: BoxFit.cover),
          // Cinematic dark gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.25, 0.6, 1.0],
                colors: [
                  Color(0xCC1A1714),
                  Color(0x552C2825),
                  Color(0x882C2825),
                  Color(0xF01A1714),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC4945A).withValues(alpha: 0.4),
                        width: 1,
                      ),
                      color: const Color(0xFF2C2825).withValues(alpha: 0.5),
                    ),
                    child: Center(
                      child: Text(
                        'M',
                        style: AppTypography.playfair(
                          24,
                          const Color(0xFFC4945A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Me Time Club',
                    style: AppTypography.playfair(40, const Color(0xFFF5F0E8)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your daily sanctuary.',
                    style: AppTypography.cormorantItalic(
                      21,
                      const Color(0xFFC4945A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Decorative dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final sizes = [4.0, 6.0, 4.0];
                      return Container(
                        width: sizes[i],
                        height: sizes[i],
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFC4945A)
                              .withValues(alpha: i == 1 ? 0.7 : 0.3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'A calm, intelligent companion for every\nseason of motherhood.',
                    style: AppTypography.lato400(
                      15,
                      const Color(0xFFF5F0E8).withValues(alpha: 0.72),
                      height: 1.65,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 3),

                  // Primary CTA
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB8706A), Color(0xFFC4945A)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB8706A)
                                .withValues(alpha: 0.38),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Begin Your Journey',
                          style: AppTypography.playfair(17, Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap: widget.onNavigateToLogin,
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.lato400(
                          14,
                          const Color(0xFFF5F0E8).withValues(alpha: 0.5),
                        ),
                        children: [
                          const TextSpan(text: 'Already a member?   '),
                          TextSpan(
                            text: 'Sign In',
                            style: AppTypography.lato700(
                              14,
                              const Color(0xFFC4945A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Meet Chamomile ✦ She is waiting for you',
                    style: AppTypography.lato300(
                      11,
                      const Color(0xFFF5F0E8).withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Steps header with linear progress ───────────────────────────────────
  Widget _buildStepHeader(int activeIndex, {String? subtitle}) {
    final t = AppTokens.day;
    final totalSteps = 3; // steps 1-3 (step 4 is register)
    return Container(
      color: _stepBg,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _prev,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: t.muted,
                    size: 18,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: List.generate(totalSteps, (i) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        height: 3,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: i < activeIndex
                              ? t.accent
                              : i == activeIndex
                                  ? t.accent.withValues(alpha: 0.5)
                                  : t.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${activeIndex + 1} of $totalSteps',
                style: AppTypography.lato400(12, t.muted),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle.toUpperCase(),
              style: AppTypography.sectionLabel(
                t.accent.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Screen 1: Name + Phase ───────────────────────────────────────────────
  Widget _buildPhaseChip(String phase, AppTokens t) {
    final id = phase.split(' ')[0].toLowerCase();
    final sel = _phases.contains(id);
    return _SelectChip(
      label: phase,
      selected: sel,
      color: t.accent,
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
    );
  }

  Widget _buildNamePhase() {
    final t = AppTokens.day;
    final pregnancyMonths = [
      '1-4 weeks', '5-8 weeks', '9-12 weeks', '13-16 weeks',
      '17-20 weeks', '21-24 weeks', '25-28 weeks', '29-32 weeks',
      '33-36 weeks', '37-40 weeks',
    ];

    return Column(
      children: [
        _buildStepHeader(0, subtitle: 'About you'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What should\nwe call you?',
                  style: AppTypography.playfair(34, t.text),
                ),
                const SizedBox(height: 8),
                Text(
                  "You are more than a mother. Let's start with you.",
                  style: AppTypography.cormorantItalic(17, t.muted),
                ),
                const SizedBox(height: 24),
                VoiceTextInput(
                  value: _name,
                  onChange: (v) => setState(() => _name = v),
                  placeholder: 'Your name…',
                  t: t,
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 36),

                Text(
                  'Where are you in your motherhood?',
                  style: AppTypography.playfair(22, t.text),
                ),
                const SizedBox(height: 6),
                Text(
                  'Motherhood holds many seasons — choose where you are right now.',
                  style: AppTypography.lato400(13.5, t.muted, height: 1.5),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.start,
                  children: [
                    'Expecting', 'Newborn (0-6m)', 'Baby (6-18m)',
                    'Toddler (18m-3y)', 'Preschool (3-5y)', 'School Age (5+)',
                  ].map((p) => _buildPhaseChip(p, t)).toList(),
                ),

                if (_phases.contains('expecting')) ...[
                  const SizedBox(height: 24),
                  Text(
                    'How far along are you?',
                    style: AppTypography.cormorantItalic(17, t.muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: pregnancyMonths.map((m) {
                      final sel = _pregnancyMonth == m;
                      return GestureDetector(
                        onTap: () => setState(() => _pregnancyMonth = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          margin: const EdgeInsets.only(right: 8, bottom: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? t.accent.withValues(alpha: 0.15)
                                : t.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? t.accent : t.border,
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            m,
                            style: AppTypography.lato400(
                              12,
                              sel ? t.accent : t.muted,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'How many little ones?',
                        style: AppTypography.cormorantItalic(17, t.text),
                      ),
                    ),
                    _StepperControl(
                      value: _childCount,
                      onDecrement: () {
                        if (_childCount > 0) setState(() => _childCount--);
                      },
                      onIncrement: () => setState(() => _childCount++),
                      t: t,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _BottomBar(
          onTap: _name.trim().isEmpty ? null : _next,
          label: 'Continue',
          t: t,
        ),
      ],
    );
  }

  // ─── Screen 2: Journey ────────────────────────────────────────────────────
  Widget _buildJourney() {
    final t = AppTokens.day;
    final journeyOptions = [
      'First-time mother', 'Second-time mother', 'Third time (or more)',
      'Single mother', "Single father — we see you, and we'd love to build something for you too",
      'Co-parenting', 'Working mother', 'Stay-at-home mother',
      'IVF / fertility journey', 'Loss and healing', 'Adoptive parent',
      'Neurodivergent child', 'Postpartum recovery', 'Blended family',
    ];

    return Column(
      children: [
        _buildStepHeader(1, subtitle: 'Your journey'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What makes\nyour journey yours?',
                  style: AppTypography.playfair(34, t.text),
                ),
                const SizedBox(height: 8),
                Text(
                  "Chamomile listens better when she knows you a little more.",
                  style: AppTypography.cormorantItalic(17, t.muted),
                ),
                const SizedBox(height: 24),
                Wrap(
                  children: journeyOptions.map((j) {
                    final sel = _journey.contains(j);
                    return _SelectChip(
                      label: j,
                      selected: sel,
                      color: t.gold,
                      onTap: () {
                        setState(() {
                          if (sel) {
                            _journey.remove(j);
                          } else {
                            _journey = [..._journey, j];
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                VoiceTextArea(
                  value: _bio,
                  onChange: (v) => setState(() => _bio = v),
                  placeholder:
                      'Or just tell Chamomile anything about you, in your own words…',
                  t: t,
                  rows: 3,
                  micSize: 32,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _BottomBar(
          onTap: _next,
          label: 'Continue',
          t: t,
          skipLabel: "I'll share this later",
          onSkip: _next,
        ),
      ],
    );
  }

  // ─── Screen 3: Hardships ──────────────────────────────────────────────────
  Widget _buildHardships() {
    final t = AppTokens.day;
    final hardshipOptions = [
      'Overwhelm', 'Loneliness', 'Sleep exhaustion', 'Burnout',
      'Mom guilt', 'Identity loss', 'Mental load', 'Need calm',
      'Finding time for myself',
    ];

    return Column(
      children: [
        _buildStepHeader(2, subtitle: 'What feels heavy'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What feels heaviest\nright now?',
                  style: AppTypography.playfair(34, t.text),
                ),
                const SizedBox(height: 8),
                Text(
                  'This helps Chamomile meet you exactly where you are.',
                  style: AppTypography.cormorantItalic(17, t.muted),
                ),
                const SizedBox(height: 24),
                Wrap(
                  children: hardshipOptions.map((h) {
                    final sel = _hardships.contains(h);
                    return _SelectChip(
                      label: h,
                      selected: sel,
                      color: t.green,
                      onTap: () {
                        setState(() {
                          if (sel) {
                            _hardships.remove(h);
                          } else {
                            _hardships = [..._hardships, h];
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                VoiceTextArea(
                  value: _hardshipsText,
                  onChange: (v) => setState(() => _hardshipsText = v),
                  placeholder: "Or speak or write what's on your heart…",
                  t: t,
                  rows: 3,
                  micSize: 32,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _BottomBar(
          onTap: _next,
          label: 'Enter My Sanctuary',
          t: t,
          skipLabel: "I'll share this later",
          onSkip: _next,
        ),
      ],
    );
  }

  // ─── Screen 4: Email + Register ───────────────────────────────────────────
  Widget _buildEmailRegister() {
    final t = AppTokens.day;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Minimal header — back only
          Container(
            color: _stepBg,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _prev,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: t.muted,
                      size: 18,
                    ),
                  ),
                ),
                Text(
                  'Almost there',
                  style: AppTypography.cormorantItalic(18, t.muted),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secure your\nsanctuary',
                    style: AppTypography.playfair(34, t.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account to save your journey and meet Chamomile.',
                    style: AppTypography.lato400(14, t.muted, height: 1.55),
                  ),
                  const SizedBox(height: 32),

                  // Email
                  _StepField(
                    controller: _emailController,
                    hint: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    t: t,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+\.[a-zA-Z]+",
                      ).hasMatch(v.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password
                  _StepField(
                    controller: _passwordController,
                    hint: 'Password',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    t: t,
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
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
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: t.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: t.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.lato400(13, t.accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Text(
                    'By creating an account you agree to our terms of service.',
                    style: AppTypography.lato400(
                      11,
                      t.muted.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _BottomBar(
            onTap: _registerUser,
            label: 'Complete Registration',
            loading: _loading,
            t: t,
          ),
        ],
      ),
    );
  }

  // ─── Register logic (unchanged) ────────────────────────────────────────
  Future<void> _registerUser() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    String getJourneyStage() {
      if (_phases.isEmpty) return 'expecting';
      switch (_phases.first) {
        case 'expecting': return 'expecting';
        case 'newborn': return 'newborn';
        case 'baby': return 'baby';
        case 'toddler': return 'toddler';
        case 'preschool': return 'preschool';
        case 'school_age': return 'school_age';
        default: return 'expecting';
      }
    }

    List<String> mapHardships(List<String> raw) => raw.map((h) {
      switch (h.toLowerCase()) {
        case 'overwhelm': return 'overwhelm';
        case 'loneliness': return 'loneliness';
        case 'sleep exhaustion': return 'sleep_deprivation';
        case 'burnout': return 'burnout';
        case 'mom guilt': return 'mom_guilt';
        case 'identity loss': return 'identity_loss';
        case 'mental load': return 'mental_load';
        case 'need calm': return 'need_calm';
        case 'finding time for myself': return 'finding_time_for_myself';
        default: return h.toLowerCase().replaceAll(' ', '_');
      }
    }).toList();

    List<String> mapJourneyTags(List<String> raw) => raw.map((j) {
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

    try {
      final userParams = {
        'email': _emailController.text.trim(),
        'name': _name.trim(),
        'display_name': _name.trim(),
        'password': _passwordController.text,
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
    } catch (_) {
      setState(() => _errorMessage = 'Registration failed. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

/// Pill chip used in phase / journey / hardship selectors
class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? color : const Color(0xFFE8DDD5),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? color : const Color(0xFF8A7D76),
          ),
        ),
      ),
    );
  }
}

/// Stepper +/- control with value display
class _StepperControl extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final AppTokens t;

  const _StepperControl({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn('−', onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('$value', style: AppTypography.playfair(24, t.text)),
        ),
        _btn('+', onIncrement),
      ],
    );
  }

  Widget _btn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8DDD5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.lato700(20, const Color(0xFF2C2825)),
          ),
        ),
      ),
    );
  }
}

/// Pinned bottom action bar with primary CTA and optional skip
class _BottomBar extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final bool loading;
  final AppTokens t;
  final String? skipLabel;
  final VoidCallback? onSkip;

  const _BottomBar({
    required this.onTap,
    required this.label,
    required this.t,
    this.loading = false,
    this.skipLabel,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F3EC),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: loading ? null : onTap,
            child: AnimatedOpacity(
              opacity: (onTap == null && !loading) ? 0.45 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [t.accent, t.gold],
                  ),
                  boxShadow: onTap != null
                      ? [
                          BoxShadow(
                            color: t.accent.withValues(alpha: 0.32),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
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
          ),
          if (skipLabel != null && onSkip != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onSkip,
              child: Text(
                skipLabel!,
                style: AppTypography.lato400(13, t.muted).copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Light text field for step 4 (on warm cream background)
class _StepField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final AppTokens t;

  const _StepField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.t,
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
      style: AppTypography.lato400(15, t.text),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.lato400(15, t.muted),
        prefixIcon: Icon(prefixIcon, color: t.muted, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.accent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.accent, width: 1.5),
        ),
        errorStyle: AppTypography.lato400(12, t.accent),
      ),
    );
  }
}
