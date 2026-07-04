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
  final Function(int dayNum, DailyPageContent? page) onSavePage;
  final DailyPageContent? initialPage;
  final bool hasCheckedToday;
  final VoidCallback onCheckedToday;

  const HomeTab({
    super.key,
    required this.user,
    required this.t,
    required this.onSavePage,
    this.initialPage,
    required this.hasCheckedToday,
    required this.onCheckedToday,
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
  bool _checkingExisting = false;

  AppTokens get t => widget.t;

  @override
  void initState() {
    super.initState();
    _mood = null;
    _freeText = '';
    _page = widget.initialPage;
    _checkingExisting = false;

    if (!widget.hasCheckedToday && _page == null) {
      _checkExistingPage();
    }
  }

  void _checkExistingPage() async {
    setState(() => _checkingExisting = true);
    try {
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final page = await ApiService.getDailyPageByDate(
        token: widget.user.token ?? '',
        dateKey: dateKey,
      );
      if (mounted) {
        setState(() {
          _page = page;
          _checkingExisting = false;
        });
        widget.onCheckedToday();
        if (page != null) {
          widget.onSavePage(now.day, page);
        }
      }
    } catch (e) {
      debugPrint('[CHECK EXISTING PAGE ERROR] $e');
      if (mounted) {
        setState(() {
          _checkingExisting = false;
        });
        widget.onCheckedToday();
      }
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateString {
    final now = DateTime.now();
    final days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    final months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${days[now.weekday - 1]}  ${now.day}  ${months[now.month - 1]}';
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
      // On backend error or network timeout, silently load from offline fallback database
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
    widget.onSavePage(DateTime.now().day, null);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          _buildDateHeader(),
          const SizedBox(height: 20),
          if (_checkingExisting)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(t.accent),
                ),
              ),
            )
          else ...[
            if (_page == null) ...[
              // Mood selector
              _buildMoodSelector(),
              const SizedBox(height: 16),
              // Free text box
              _buildFreeTextBox(),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Tap the mic — one hand is enough ✦',
                  style: AppTypography.lato400(11, t.muted),
                ),
              ),
              // Open Daily Page button
              CTAButton(
                label: 'Open My Daily Page',
                loading: _loading,
                disabled: _loading,
                onTap: _generate,
                t: t,
                icon: AppIcons.bloom(c: Colors.white, s: 20),
              ),
              const SizedBox(height: 24),
            ],
            // Daily page content
            if (_page != null) ...[
              if (_fromFallback)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '✦ From our library',
                    style: AppTypography.lato400(10, t.muted),
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
              const SizedBox(height: 16),
              // New check-in button
              Center(
                child: GestureDetector(
                  onTap: _newCheckIn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcons.refresh(c: t.muted, s: 14),
                        const SizedBox(width: 8),
                        Text(
                          'New check-in',
                          style: AppTypography.lato400(13, t.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _dateString,
            style: AppTypography.lato700(10, t.muted, letterSpacing: 2.2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$_greeting, ${widget.user.name}.',
            style: AppTypography.cormorantItalic(19, t.accent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'How are you arriving today?',
            style: AppTypography.cormorantItalic(16, t.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children:
                moodOptions.map((m) {
                  final sel = _mood == m.id;
                  return ChipButton(
                    label: m.label,
                    selected: sel,
                    onTap: () => setState(() => _mood = sel ? null : m.id),
                    color: m.color,
                    t: t,
                    iconBuilder: m.icon,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeTextBox() {
    return VoiceTextArea(
      value: _freeText,
      onChange: (v) => setState(() => _freeText = v),
      placeholder:
          'Or tell Chamomile how you\'re really feeling… type or speak.',
      t: t,
      rows: 3,
    );
  }
}

/// Renders all 9 sections of a Chamomile daily page
class _DailyPageView extends StatelessWidget {
  final DailyPageContent page;
  final AppTokens t;
  final String? mood;

  const _DailyPageView({required this.page, required this.t, this.mood});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Opening Thought — gradient card
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
                style: AppTypography.lato400(
                  12,
                  t.muted,
                ).copyWith(fontStyle: FontStyle.italic),
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
        // 5. Micro Ritual — gradient card
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
        // 8. Night Reflection — dark card
        _buildNightReflection(),
      ],
    );
  }

  Widget _buildOpeningThought() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            t.accent.withValues(alpha: 0.18),
            t.gold.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: t.accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        '❝ ${page.openingThought} ❞',
        style: AppTypography.dmSerifItalic(19, t.accent, height: 1.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMicroRitual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: t.gold.withValues(alpha: 0.14),
        border: Border.all(color: t.gold.withValues(alpha: 0.25)),
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
            style: AppTypography.cormorantItalic(15, t.text, height: 1.6),
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
          AppIcons.bloom(c: t.accent, s: 28),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2825), Color(0xFF1E1C1A)],
        ),
        border: Border.all(color: const Color(0xFF302C28)),
      ),
      child: Column(
        children: [
          AppIcons.moon(c: const Color(0xFFC4878A), s: 20),
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
              height: 1.5,
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
    setState(() {
      _submitting = true;
    });

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Thank you for helping Chamomile learn. ✦',
            style: AppTypography.cormorantItalic(14, t.muted),
          ),
        ),
      );
    }

    if (_vote == 'down') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.all(16),
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
              style: AppTypography.cormorantItalic(15, t.accent),
            ),
            const SizedBox(height: 10),
            VoiceTextArea(
              value: _comment,
              onChange: (v) => setState(() => _comment = v),
              placeholder:
                  'Tell Chamomile what didn\'t resonate… type or speak.',
              t: t,
              rows: 2,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _submitting ? null : () => setState(() => _vote = null),
                  child: Text(
                    'Cancel',
                    style: AppTypography.lato400(13, t.muted),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap:
                      _submitting
                          ? null
                          : () => _submitFeedback('down', comment: _comment),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        _submitting
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: t.border),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            "DID TODAY'S PAGE FEEL RIGHT FOR YOU?",
            style: AppTypography.lato700(10, t.muted, letterSpacing: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // This felt right
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
              const SizedBox(width: 14),
              // Not quite
              FeedbackPillButton(
                label: 'Not quite',
                icon: Icons.thumb_down_alt_outlined,
                t: t,
                onTap: () {
                  setState(() => _vote = 'down');
                },
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: t.card,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
