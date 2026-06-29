import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../icons/app_icons.dart';
import '../../models/user_profile.dart';
import '../../data/fallback_database.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/voice_text_input.dart';
import '../../services/api_service.dart';

class HomeTab extends StatefulWidget {
  final UserProfile user;
  final AppTokens t;
  final Function(int dayNum, DailyPageContent page) onSavePage;

  const HomeTab({
    super.key,
    required this.user,
    required this.t,
    required this.onSavePage,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String? _mood;
  String _freeText = '';
  DailyPageContent? _page;
  bool _loading = false;
  bool _fromFallback = false;

  AppTokens get t => widget.t;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateString {
    final now = DateTime.now();
    const days = [
      'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY',
      'FRIDAY', 'SATURDAY', 'SUNDAY',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${days[now.weekday - 1]}  ·  ${now.day} ${months[now.month - 1]}';
  }

  void _generate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _loading = true);
    try {
      final result = await ApiService.generateDailyPage(
        token: widget.user.token ?? '',
        mood: _mood,
        freeText: _freeText,
      );
      if (mounted) {
        setState(() {
          _page = result['content'] as DailyPageContent;
          _fromFallback = result['from_fallback'] as bool? ?? false;
          _loading = false;
        });
        widget.onSavePage(DateTime.now().day, _page!);
      }
    } catch (e) {
      debugPrint('[CHAMOMILE API ERROR] $e');
      final phase =
          widget.user.phases.isNotEmpty ? widget.user.phases.first : 'baby';
      final page = getFallback(phase);
      if (mounted) {
        setState(() {
          _page = page;
          _loading = false;
          _fromFallback = true;
        });
        widget.onSavePage(DateTime.now().day, page);
      }
    }
  }

  void _newCheckIn() {
    setState(() {
      _mood = null;
      _freeText = '';
      _page = null;
      _fromFallback = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Rich date + greeting header
          _buildDateHeader(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                if (_page == null) ...[
                  _buildCheckinSection(),
                ],

                if (_page != null) ...[
                  if (_fromFallback)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: t.gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: t.gold.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            color: t.gold,
                            size: 14,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'From our library',
                            style: AppTypography.lato400(12, t.gold),
                          ),
                        ],
                      ),
                    ),
                  _DailyPageView(page: _page!, t: t, mood: _mood),
                  const SizedBox(height: 8),
                  DailyPageFeedback(
                    user: widget.user,
                    page: _page!,
                    t: t,
                    mood: _mood,
                  ),
                  const SizedBox(height: 20),
                  // New check-in
                  Center(
                    child: GestureDetector(
                      onTap: _newCheckIn,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: t.border),
                          color: t.card,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcons.refresh(c: t.muted, s: 15),
                            const SizedBox(width: 8),
                            Text(
                              'New check-in',
                              style: AppTypography.lato400(14, t.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Rich gradient header ─────────────────────────────────────────────────
  Widget _buildDateHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.accent.withValues(alpha: 0.12),
            t.gold.withValues(alpha: 0.07),
            t.bg,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: t.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _dateString,
              style: AppTypography.lato700(
                10,
                t.accent,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Greeting
          RichText(
            text: TextSpan(
              style: AppTypography.playfair(28, t.text),
              children: [
                TextSpan(text: '$_greeting, '),
                TextSpan(
                  text: '${widget.user.name}.',
                  style: AppTypography.playfair(28, t.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your sanctuary is ready.',
            style: AppTypography.cormorantItalic(16, t.muted),
          ),
        ],
      ),
    );
  }

  // ── Check-in section (mood + text + generate) ─────────────────────────────
  Widget _buildCheckinSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Text(
          'HOW ARE YOU ARRIVING TODAY?',
          style: AppTypography.sectionLabel(t.muted),
        ),
        const SizedBox(height: 14),

        // Mood chips — 2 per row via Wrap
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: moodOptions.map((m) {
            final sel = _mood == m.id;
            return GestureDetector(
              onTap: () => setState(() => _mood = sel ? null : m.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: sel ? m.color.withValues(alpha: 0.14) : t.card,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: sel ? m.color : t.border,
                    width: sel ? 1.5 : 1,
                  ),
                  boxShadow: sel
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    m.icon(
                      c: sel ? m.color : t.muted,
                      s: 15,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      m.label,
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 13.5,
                        fontWeight:
                            sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? m.color : t.muted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Text area
        VoiceTextArea(
          value: _freeText,
          onChange: (v) => setState(() => _freeText = v),
          placeholder:
              'Or tell Chamomile how you\'re really feeling… type or speak.',
          t: t,
          rows: 3,
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Tap the mic — one hand is enough ✦',
            style: AppTypography.lato300(11, t.muted),
          ),
        ),
        const SizedBox(height: 22),

        // Generate CTA — gradient button
        GestureDetector(
          onTap: _loading ? null : _generate,
          child: AnimatedOpacity(
            opacity: _loading ? 0.7 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [t.accent, t.gold],
                ),
                boxShadow: [
                  BoxShadow(
                    color: t.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Preparing your page…',
                      style: AppTypography.lato400(15, Colors.white),
                    ),
                  ] else ...[
                    AppIcons.bloom(c: Colors.white, s: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Open My Daily Page',
                      style: AppTypography.playfair(17, Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ─── Daily page sections renderer ─────────────────────────────────────────────
class _DailyPageView extends StatelessWidget {
  final DailyPageContent page;
  final AppTokens t;
  final String? mood;

  const _DailyPageView({required this.page, required this.t, this.mood});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Opening Thought
        _buildOpeningThought(),
        const SizedBox(height: 14),
        // 2. Reflection
        SectionCard(
          title: 'Reflection',
          accentColor: t.accent,
          icon: AppIcons.pen(c: t.accent, s: 16),
          t: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                page.reflection,
                style: AppTypography.cormorantItalic(17, t.text, height: 1.6),
              ),
              const SizedBox(height: 10),
              Text(
                page.reflectionFollowup,
                style: AppTypography.lato400(12, t.muted)
                    .copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        // 3. Emotional Alignment
        SectionCard(
          title: 'Emotional Alignment',
          accentColor: t.green,
          icon: AppIcons.heart(c: t.green, s: 16),
          t: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('FEELING', t.green),
              Text(
                page.emotionalFeeling,
                style: AppTypography.lato400(14, t.text, height: 1.5),
              ),
              const SizedBox(height: 10),
              _label('NEED', t.green),
              Text(
                page.emotionalNeed,
                style: AppTypography.lato400(14, t.text, height: 1.5),
              ),
              Divider(color: t.border, height: 24),
              Text(
                page.emotionalResponse,
                style: AppTypography.lato400(15, t.text, height: 1.6),
              ),
            ],
          ),
        ),
        // 4. Insight
        SectionCard(
          title: 'Insight',
          accentColor: t.gold,
          icon: AppIcons.star(c: t.gold, s: 16),
          t: t,
          child: Text(
            page.insight,
            style: AppTypography.lato400(15, t.text, height: 1.6),
          ),
        ),
        // 5. Micro Ritual
        _buildMicroRitual(),
        const SizedBox(height: 14),
        // 6. Gentle Read
        SectionCard(
          title: 'Gentle Read',
          accentColor: t.muted,
          icon: AppIcons.book(c: t.muted, s: 16),
          t: t,
          child: Text(
            page.gentleRead,
            style: AppTypography.lato400(14, t.text, height: 1.6),
          ),
        ),
        // 7. Fun Moment
        _buildFunMoment(),
        const SizedBox(height: 14),
        // 8. Night Reflection
        _buildNightReflection(),
      ],
    );
  }

  Widget _buildOpeningThought() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.accent.withValues(alpha: 0.15),
            t.gold.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: t.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote_rounded, color: t.accent.withValues(alpha: 0.4), size: 28),
          const SizedBox(height: 8),
          Text(
            page.openingThought,
            style: AppTypography.dmSerifItalic(19, t.accent, height: 1.55),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMicroRitual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: t.gold.withValues(alpha: 0.1),
        border: Border.all(color: t.gold.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcons.ritual(c: t.gold, s: 16),
              const SizedBox(width: 8),
              Text('MICRO RITUAL', style: AppTypography.sectionLabel(t.gold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            page.microSkill,
            style: AppTypography.cormorantItalic(16, t.text, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildFunMoment() {
    return AppCard(
      t: t,
      child: Column(
        children: [
          AppIcons.bloom(c: t.accent, s: 26),
          const SizedBox(height: 12),
          Text(
            page.funMoment,
            style: AppTypography.cormorantItalic(17, t.text, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNightReflection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2825), Color(0xFF1A1614)],
        ),
        border: Border.all(color: const Color(0xFF302C28)),
      ),
      child: Column(
        children: [
          AppIcons.moon2(c: const Color(0xFFC4878A), s: 20),
          const SizedBox(height: 8),
          Text(
            'NIGHT REFLECTION',
            style: AppTypography.sectionLabel(const Color(0xFF8A8078)),
          ),
          const SizedBox(height: 14),
          Text(
            page.nightReflection,
            style: AppTypography.dmSerifItalic(
              19,
              const Color(0xFFF0EBE3),
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _label(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: AppTypography.lato700(10, color, letterSpacing: 1.2),
      ),
    );
  }
}

// ─── Feedback widget ──────────────────────────────────────────────────────────
class DailyPageFeedback extends StatefulWidget {
  final UserProfile user;
  final DailyPageContent page;
  final AppTokens t;
  final String? mood;

  const DailyPageFeedback({
    super.key,
    required this.user,
    required this.page,
    required this.t,
    required this.mood,
  });

  @override
  State<DailyPageFeedback> createState() => _DailyPageFeedbackState();
}

class _DailyPageFeedbackState extends State<DailyPageFeedback> {
  String? _vote;
  bool _submitted = false;
  bool _submitting = false;
  String _comment = '';

  void _submitFeedback(String vote, {String? comment}) async {
    setState(() => _submitting = true);
    try {
      await ApiService.submitFeedback(
        token: widget.user.token ?? '',
        pageId: widget.page.id ?? '',
        vote: vote,
        feedbackText: comment,
        mood: widget.mood,
        openingThought: widget.page.openingThought,
      );
    } catch (e) {
      debugPrint('[FEEDBACK SUBMIT ERROR] $e');
    } finally {
      if (mounted) {
        setState(() {
          _submitted = true;
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

    if (_submitted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Thank you for helping Chamomile learn. ✦',
            style: AppTypography.cormorantItalic(15, t.muted),
          ),
        ),
      );
    }

    if (_vote == 'down') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: t.border),
          boxShadow: t.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What missed?',
              style: AppTypography.cormorantItalic(16, t.accent),
            ),
            const SizedBox(height: 10),
            VoiceTextArea(
              value: _comment,
              onChange: (v) => setState(() => _comment = v),
              placeholder:
                  "Tell Chamomile what didn't resonate… type or speak.",
              t: t,
              rows: 2,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _vote = null),
                  child: Text(
                    'Cancel',
                    style: AppTypography.lato400(13, t.muted),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitting
                      ? null
                      : () => _submitFeedback('down', comment: _comment),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Submit',
                            style: AppTypography.lato700(13, Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default: thumb up/down row
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: t.border),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            "DID TODAY'S PAGE FEEL RIGHT?",
            style: AppTypography.sectionLabel(t.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FeedbackPillButton(
                label: 'This felt right',
                icon: Icons.thumb_up_alt_outlined,
                loading: _submitting && _vote == 'up',
                t: t,
                onTap: () {
                  setState(() => _vote = 'up');
                  _submitFeedback('up');
                },
              ),
              const SizedBox(width: 12),
              FeedbackPillButton(
                label: 'Not quite',
                icon: Icons.thumb_down_alt_outlined,
                t: t,
                onTap: () => setState(() => _vote = 'down'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FeedbackPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final AppTokens t;
  final bool loading;

  const FeedbackPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.t,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: t.border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey,
                ),
              )
            else
              Icon(icon, size: 16, color: t.text),
            const SizedBox(width: 8),
            Text(label, style: AppTypography.lato700(13, t.text)),
          ],
        ),
      ),
    );
  }
}
