import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../icons/app_icons.dart';
import '../../models/user_profile.dart';
import '../../data/fallback_database.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/voice_text_input.dart';

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
    final days = [
      'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY',
      'FRIDAY', 'SATURDAY', 'SUNDAY'
    ];
    final months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${days[now.weekday - 1]}  ${now.day}  ${months[now.month - 1]}';
  }

  void _generate() {
    setState(() => _loading = true);
    // Fallback mode — use the offline database
    Future.delayed(const Duration(milliseconds: 800), () {
      final phase = widget.user.phases.isNotEmpty
          ? widget.user.phases.first
          : 'baby';
      final page = getFallback(phase);
      if (mounted) {
        setState(() {
          _page = page;
          _loading = false;
          _fromFallback = true;
        });
        widget.onSavePage(DateTime.now().day, page);
      }
    });
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
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          _buildDateHeader(),
          const SizedBox(height: 20),
          // Mood selector
          _buildMoodSelector(),
          const SizedBox(height: 16),
          // Free text box
          _buildFreeTextBox(),
          const SizedBox(height: 4),
          Text(
            'Tap the mic — one hand is enough ✦',
            style: AppTypography.lato400(11, t.muted),
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
            const SizedBox(height: 16),
            // New check-in button
            Center(
              child: GestureDetector(
                onTap: _newCheckIn,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dateString,
            style: AppTypography.lato700(10, t.muted, letterSpacing: 2.2),
          ),
          const SizedBox(height: 4),
          Text(
            '$_greeting, ${widget.user.name}.',
            style: AppTypography.cormorantItalic(19, t.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you arriving today?',
          style: AppTypography.cormorantItalic(16, t.muted),
        ),
        const SizedBox(height: 12),
        Wrap(
          children: moodOptions.map((m) {
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
    );
  }

  Widget _buildFreeTextBox() {
    return VoiceTextArea(
      value: _freeText,
      onChange: (v) => setState(() => _freeText = v),
      placeholder: 'Or tell Chamomile how you\'re really feeling… type or speak.',
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

  const _DailyPageView({
    required this.page,
    required this.t,
    this.mood,
  });

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
                style: AppTypography.lato400(12, t.muted).copyWith(
                  fontStyle: FontStyle.italic,
                ),
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
              Text(page.emotionalFeeling,
                  style: AppTypography.lato400(14, t.text, height: 1.5)),
              const SizedBox(height: 10),
              _label('NEED', t.green),
              Text(page.emotionalNeed,
                  style: AppTypography.lato400(14, t.text, height: 1.5)),
              Divider(color: t.border, height: 24),
              Text(page.emotionalResponse,
                  style: AppTypography.lato400(15, t.text, height: 1.6)),
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
              Text(
                'MICRO RITUAL',
                style: AppTypography.sectionLabel(t.gold),
              ),
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
        border: Border.all(
          color: const Color(0xFF302C28),
        ),
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
