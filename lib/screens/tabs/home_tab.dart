import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/tokens.dart';
import '../../icons/app_icons.dart';
import '../../models/gentle_read.dart';
import '../../models/user_profile.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/gentle_read_post.dart';
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
  bool _checkingExisting = false;
  final List<GentleRead> _gentleReadHistory = [];
  int _gentleReadIndex = 0;
  bool _gentleReadLoading = false;
  GentleRead? get _currentGentleRead {
    if (_gentleReadHistory.isEmpty) return null;
    final index = _gentleReadIndex.clamp(0, _gentleReadHistory.length - 1);
    return _gentleReadHistory[index];
  }

  // Answer fields — loaded from page, saved on change
  final _reflectionAnswerCtrl = TextEditingController();
  final _reflectionFollowupAnswerCtrl = TextEditingController();
  final _nightReflectionAnswerCtrl = TextEditingController();

  AppTokens get t => widget.t;

  @override
  void initState() {
    super.initState();
    _mood = null;
    _freeText = '';
    _page = widget.initialPage;
    _checkingExisting = false;
    _syncAnswerControllers();

    if (!widget.hasCheckedToday && _page == null) {
      _checkExistingPage();
    }
    _loadGentleRead();
  }

  @override
  void dispose() {
    _reflectionAnswerCtrl.dispose();
    _reflectionFollowupAnswerCtrl.dispose();
    _nightReflectionAnswerCtrl.dispose();
    super.dispose();
  }

  void _syncAnswerControllers() {
    final p = _page;
    if (p == null) return;
    _reflectionAnswerCtrl.text = p.reflectionAnswer;
    _reflectionFollowupAnswerCtrl.text = p.reflectionFollowupAnswer;
    _nightReflectionAnswerCtrl.text = p.nightReflectionAnswer;
  }

  void _saveAnswers() {
    final p = _page;
    if (p == null || p.id == null) return;
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    ApiService.saveDailyPageAnswers(
      token: widget.user.token ?? '',
      dateKey: dateKey,
      reflectionAnswer: _reflectionAnswerCtrl.text,
      reflectionFollowupAnswer: _reflectionFollowupAnswerCtrl.text,
      nightReflectionAnswer: _nightReflectionAnswerCtrl.text,
    ).then((json) {
      if (json == null || !mounted) return;
      // Use the server's response to keep _page + _dailyPages in sync
      final updated = DailyPageContent.fromJson(json);
      _page = updated;
      widget.onSavePage(now.day, updated);
    });
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
          if (page?.mood != null && page!.mood!.isNotEmpty) {
            _mood = page.mood;
          }
          if (page?.freeText != null && page!.freeText!.isNotEmpty) {
            _freeText = page.freeText!;
          }
          _checkingExisting = false;
        });
        _syncAnswerControllers();
        widget.onCheckedToday();
        if (page != null) {
          widget.onSavePage(now.day, page);
        }
      }
    } on SessionExpiredException {
      // AppRoot clears the session and opens the login screen.
      return;
    } catch (e) {
      if (e is UnauthorizedException) return;
      debugPrint('[CHECK EXISTING PAGE ERROR] $e');
      if (mounted) {
        setState(() {
          _checkingExisting = false;
        });
        widget.onCheckedToday();
      }
    }
  }

  Future<void> _loadGentleRead({bool another = false}) async {
    setState(() => _gentleReadLoading = true);
    try {
      final read = await ApiService.randomGentleRead(
        token: widget.user.token ?? '',
        excludeIds:
            another
                ? _gentleReadHistory.map((item) => item.id).toList()
                : const [],
      );
      if (!mounted) return;
      setState(() {
        _gentleReadLoading = false;
        if (read == null) return;
        if (!another) {
          _gentleReadHistory
            ..clear()
            ..add(read);
          _gentleReadIndex = 0;
          return;
        }
        final existing = _gentleReadHistory.indexWhere(
          (item) => item.id == read.id,
        );
        if (existing >= 0) {
          _gentleReadIndex = existing;
        } else {
          _gentleReadHistory.add(read);
          _gentleReadIndex = _gentleReadHistory.length - 1;
        }
      });
    } catch (e) {
      if (e is UnauthorizedException) return;
      debugPrint('[GENTLE READ ERROR] $e');
      if (mounted) setState(() => _gentleReadLoading = false);
    }
  }

  void _goPrevGentleRead() {
    if (_gentleReadLoading || _gentleReadIndex == 0) return;
    setState(() {
      _gentleReadIndex--;
    });
  }

  Future<void> _goNextGentleRead() async {
    if (_gentleReadLoading) return;
    if (_gentleReadIndex < _gentleReadHistory.length - 1) {
      setState(() {
        _gentleReadIndex++;
      });
      return;
    }
    await _loadGentleRead(another: true);
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
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final result = await ApiService.generateDailyPage(
        token: widget.user.token ?? '',
        mood: _mood,
        freeText: _freeText,
        dateKey: dateKey,
      );

      if (mounted) {
        setState(() {
          _page = result['content'] as DailyPageContent;
          _loading = false;
        });
        _syncAnswerControllers();
        widget.onSavePage(DateTime.now().day, _page!);
      }
    } on SessionExpiredException {
      // Do not turn an expired login into an offline daily page.
      return;
    } catch (e) {
      if (e is UnauthorizedException) return;
      debugPrint('[CHAMOMILE API ERROR] $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.message
                  : 'Failed to generate daily page. Please check your connection and try again.',
            ),
          ),
        );
      }
    }
  }

  void _newCheckIn() {
    setState(() {
      _mood = null;
      _freeText = '';
      _page = null;
    });
    widget.onSavePage(DateTime.now().day, null);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
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
              _buildChamomileWelcome(),
              _DailyPageView(
                page: _page!,
                t: t,
                mood: _mood,
                reflectionAnswerCtrl: _reflectionAnswerCtrl,
                reflectionFollowupAnswerCtrl: _reflectionFollowupAnswerCtrl,
                nightReflectionAnswerCtrl: _nightReflectionAnswerCtrl,
                onSaveAnswers: _saveAnswers,
                gentleRead: _buildGentleRead(),
              ),
              DailyPageFeedback(
                user: widget.user,
                page: _page!,
                t: t,
                mood: _mood,
              ),
              const SizedBox(height: 14),
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
            if (_page == null) _buildGentleRead(),
          ],
        ],
      ),
    );
  }

  Widget _buildGentleRead() {
    final read = _currentGentleRead;
    if (read == null && !_gentleReadLoading) return const SizedBox.shrink();
    if (read == null) {
      return AppCard(
        t: t,
        margin: const EdgeInsets.only(top: 14),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
          ),
        ),
      );
    }
    final canBrowse = read.total > 1;
    return GentleReadPost(
      read: read,
      t: t,
      baseUri: Uri.parse(ApiService.serverHost),
      loading: _gentleReadLoading,
      onOpenLink: _openGentleReadLink,
      onPrevious: canBrowse && _gentleReadIndex > 0 ? _goPrevGentleRead : null,
      onNext: canBrowse ? _goNextGentleRead : null,
    );
  }

  Future<void> _openGentleReadLink(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (error) {
      debugPrint('[GENTLE READ LINK ERROR] $error');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open this link. Please try again.'),
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

  Widget _buildChamomileWelcome() {
    final name = widget.user.name.trim();
    final greeting =
        name.isEmpty
            ? _greeting
            : '$_greeting, ${name.split(RegExp(r'\s+')).first}';

    final textToShow =
        (_page?.whatChamomileSays != null &&
                _page!.whatChamomileSays!.trim().isNotEmpty)
            ? _page!.whatChamomileSays!.trim()
            : "$greeting. I've been waiting for this moment with you. "
                'Before the day pulls you in every direction — '
                "you're here. That matters. How are you arriving today?";

    return AppCard(
      t: t,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClipOval(child: AppLogo(size: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHAMOMILE', style: AppTypography.sectionLabel(t.accent)),
                const SizedBox(height: 10),
                Text(
                  textToShow,
                  style: AppTypography.cormorantItalic(
                    18,
                    t.text,
                    height: 1.65,
                  ),
                ),
              ],
            ),
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

/// Renders the Chamomile daily page with Gentle Reads above Fun Moment.
class _DailyPageView extends StatelessWidget {
  final DailyPageContent page;
  final AppTokens t;
  final String? mood;
  final TextEditingController reflectionAnswerCtrl;
  final TextEditingController reflectionFollowupAnswerCtrl;
  final TextEditingController nightReflectionAnswerCtrl;
  final VoidCallback onSaveAnswers;
  final Widget gentleRead;

  const _DailyPageView({
    required this.page,
    required this.t,
    this.mood,
    required this.reflectionAnswerCtrl,
    required this.reflectionFollowupAnswerCtrl,
    required this.nightReflectionAnswerCtrl,
    required this.onSaveAnswers,
    required this.gentleRead,
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
              const SizedBox(height: 12),
              _answerField(
                controller: reflectionAnswerCtrl,
                hint: 'Your reflection…',
              ),
              const SizedBox(height: 14),
              Text(
                page.reflectionFollowup,
                style: AppTypography.lato400(
                  12,
                  t.muted,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              _answerField(
                controller: reflectionFollowupAnswerCtrl,
                hint: 'Your answer…',
              ),
            ],
          ),
        ),
        // 3. Emotional Alignment
        _buildEmotionalAlignment(),
        // 4. Today's Insight
        _buildInsight(),
        // 5. Micro Ritual — gradient card
        _buildMicroRitual(),
        gentleRead,
        const SizedBox(height: 14),
        // 6. Fun Moment
        _buildFunMoment(),
        // 7. Night Reflection — dark card
        _buildNightReflection(),
      ],
    );
  }

  Widget _buildEmotionalAlignment() {
    return AppCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIcons.heart(c: t.cycleRose, s: 16),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'EMOTIONAL ALIGNMENT',
                  style: AppTypography.sectionLabel(t.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'When your thoughts, body, and actions feel in sync, you feel lighter.',
            textAlign: TextAlign.center,
            style: AppTypography.cormorantItalic(16, t.muted, height: 1.5),
          ),
          if (page.emotionalFeeling.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            _alignmentCard(
              icon: AppIcons.heart(c: t.accent, s: 14),
              label: 'FEELING',
              subtitle: 'You are carrying this',
              body: page.emotionalFeeling,
              accent: t.accent,
            ),
          ],
          if (page.emotionalNeed.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _alignmentCard(
              icon: Icon(Icons.adjust_rounded, color: t.accent, size: 15),
              label: 'NEED',
              subtitle: 'What you need right now',
              body: page.emotionalNeed,
              accent: t.accent,
            ),
          ],
          if (page.emotionalResponse.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _alignmentCard(
              icon: AppIcons.star(c: t.gold, s: 15),
              label: 'RESPONSE',
              subtitle: 'A gentle step toward yourself',
              body: page.emotionalResponse,
              accent: t.gold,
            ),
          ],
        ],
      ),
    );
  }

  Widget _alignmentCard({
    required Widget icon,
    required String label,
    required String subtitle,
    required String body,
    required Color accent,
  }) {
    final night = t == AppTokens.night;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: night ? 0.14 : 0.07),
            accent.withValues(alpha: night ? 0.06 : 0.025),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: icon,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: label,
                                style: AppTypography.lato700(
                                  11,
                                  accent,
                                  letterSpacing: 1.3,
                                ),
                              ),
                              TextSpan(
                                text: '  — $subtitle',
                                style: AppTypography.lato400(
                                  11,
                                  t.muted,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    style: AppTypography.cormorantItalic(
                      18,
                      t.text,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 3,
              child: ColoredBox(color: accent.withValues(alpha: 0.46)),
            ),
          ],
        ),
      ),
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

  Widget _buildInsight() {
    return AppCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcons.star(c: t.gold, s: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "TODAY'S INSIGHT",
                  style: AppTypography.sectionLabel(t.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            page.insight,
            style: AppTypography.lato400(16, t.text, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroRitual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.gold.withValues(alpha: t == AppTokens.night ? 0.15 : 0.10),
            t.gold.withValues(alpha: t == AppTokens.night ? 0.06 : 0.035),
          ],
        ),
        border: Border.all(color: t.gold.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcons.sun(c: t.gold, s: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'MICRO RITUAL',
                  style: AppTypography.sectionLabel(t.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            page.microSkill,
            style: AppTypography.cormorantItalic(18, t.text, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildFunMoment() {
    if (page.funMoment.trim().isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: 'Fun Moment',
      accentColor: t.gold,
      icon: AppIcons.star(c: t.gold, s: 16),
      t: t,
      child: Text(
        page.funMoment,
        style: AppTypography.cormorant600(17, t.text, height: 1.6),
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
          const SizedBox(height: 14),
          _answerField(
            controller: nightReflectionAnswerCtrl,
            hint: 'Your evening thoughts…',
            dark: true,
          ),
        ],
      ),
    );
  }

  Widget _answerField({
    required TextEditingController controller,
    required String hint,
    bool dark = false,
  }) {
    final textColor = dark ? const Color(0xFFD4C8BE) : t.text;
    final hintColor = dark ? const Color(0xFF6E635A) : t.muted;
    final borderColor = dark ? const Color(0xFF403830) : t.border;
    final fillColor =
        dark ? const Color(0xFF252320) : t.bg.withValues(alpha: 0.5);

    return TextField(
      controller: controller,
      onEditingComplete: onSaveAnswers,
      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
        onSaveAnswers();
      },
      maxLines: null,
      style: AppTypography.lato400(14, textColor, height: 1.6),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.lato400(
          13,
          hintColor,
        ).copyWith(fontStyle: FontStyle.italic),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: t.accent, width: 1.5),
        ),
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
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Center(
          child: Text(
            'Thank you for helping Chamomile learn. ✦',
            style: AppTypography.cormorantItalic(14, t.muted),
          ),
        ),
      );
    }

    if (_vote == 'down') {
      return Container(
        margin: const EdgeInsets.only(top: 14),
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
      margin: const EdgeInsets.only(top: 14),
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
