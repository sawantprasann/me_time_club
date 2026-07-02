import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../icons/app_icons.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/speech_button.dart';

class CalendarTab extends StatefulWidget {
  final UserProfile user;
  final AppTokens t;
  final Map<int, DailyPageContent> dailyPages;

  const CalendarTab({
    super.key,
    required this.user,
    required this.t,
    required this.dailyPages,
  });

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late int _viewYear;
  late int _viewMonth;
  int _sel = 1;
  bool _pageExpanded = false;
  bool _showYearPicker = false;

  // Tasks: key = "$year-$month-$day" (local cache key)
  final Map<String, List<_TaskItem>> _tasks = {};
  late TextEditingController _taskController;

  // Cycle days — local display keys (non-padded, matches _dateKey output)
  final Set<String> _cycleDays = {};
  // API ids keyed by zero-padded date (YYYY-MM-DD) for delete calls
  final Map<String, String> _cycleDayIds = {};

  // Cache fetched daily pages by date key YYYY-MM-DD
  final Map<String, DailyPageContent?> _fetchedPages = {};
  bool _loadingPage = false;

  AppTokens get t => widget.t;

  // Zero-padded YYYY-MM-DD for the currently selected day (used for API calls)
  String get _apiDateKey =>
      '$_viewYear-${_viewMonth.toString().padLeft(2, '0')}-${_sel.toString().padLeft(2, '0')}';

  String get _apiMonth =>
      '$_viewYear-${_viewMonth.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController();
    final now = DateTime.now();
    _viewYear = now.year;
    _viewMonth = now.month;
    _sel = now.day;
    _fetchDailyPageForSelected();
    _loadCycleDays();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  /// Load cycle days for the current view month from the server.
  Future<void> _loadCycleDays() async {
    try {
      final raw = await ApiService.fetchMonthCycleDays(
        token: widget.user.token ?? '',
        month: _apiMonth,
      );
      if (!mounted) return;
      setState(() {
        for (final r in raw) {
          final dk = r['date_key'] as String; // "2026-07-02"
          final id = r['id'].toString();
          _cycleDayIds[dk] = id;
          // Convert to non-padded local key matching _dateKey()
          final parts = dk.split('-');
          final d = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          _cycleDays.add(_dateKey(d));
        }
      });
    } catch (e) {
      debugPrint('[CYCLE DAYS LOAD ERROR] $e');
    }
  }

  void _fetchDailyPageForSelected() async {
    final dateKey =
        '$_viewYear-${_viewMonth.toString().padLeft(2, '0')}-${_sel.toString().padLeft(2, '0')}';

    // Check session generated page first
    final isSessionCurrent =
        _isCurrentMonth && widget.dailyPages.containsKey(_sel);
    if (isSessionCurrent) return;

    if (_fetchedPages.containsKey(dateKey)) return;

    setState(() {
      _loadingPage = true;
    });

    try {
      final page = await ApiService.getDailyPageByDate(
        token: widget.user.token ?? '',
        dateKey: dateKey,
      );
      if (mounted) {
        setState(() {
          _fetchedPages[dateKey] = page;
          _loadingPage = false;
        });
      }
    } catch (e) {
      debugPrint('[GET DAILY PAGE ERROR] $e');
      if (mounted) {
        setState(() {
          _fetchedPages[dateKey] = null;
          _loadingPage = false;
        });
      }
    }
  }

  void _selectDay(int dayNum) {
    setState(() {
      _sel = dayNum;
      _pageExpanded = false;
    });
    _fetchDailyPageForSelected();
  }

  String get _taskKey => '$_viewYear-$_viewMonth-$_sel';

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _viewYear == now.year && _viewMonth == now.month;
  }

  int get _daysInMonth => DateTime(_viewYear, _viewMonth + 1, 0).day;

  int get _firstWeekday =>
      DateTime(_viewYear, _viewMonth, 1).weekday % 7; // 0=Sun

  List<_TaskItem> get _currentTasks => _tasks[_taskKey] ?? [];

  void _prevMonth() {
    setState(() {
      if (_viewMonth == 1) {
        _viewMonth = 12;
        _viewYear--;
      } else {
        _viewMonth--;
      }
      _sel = 1;
      _pageExpanded = false;
      _cycleDays.clear();
      _cycleDayIds.clear();
    });
    _fetchDailyPageForSelected();
    _loadCycleDays();
  }

  void _nextMonth() {
    setState(() {
      if (_viewMonth == 12) {
        _viewMonth = 1;
        _viewYear++;
      } else {
        _viewMonth++;
      }
      _sel = 1;
      _pageExpanded = false;
      _cycleDays.clear();
      _cycleDayIds.clear();
    });
    _fetchDailyPageForSelected();
    _loadCycleDays();
  }

  void _addTask() async {
    if (_newTask.trim().isEmpty) return;
    final taskText = _newTask.trim();
    final dateKey = _apiDateKey; // zero-padded YYYY-MM-DD for the server
    setState(() => _newTask = '');
    _taskController.clear();

    try {
      final res = await ApiService.createTask(
        token: widget.user.token ?? '',
        title: taskText,
        completed: false,
        dateKey: dateKey,
      );
      final createdId = res['id']?.toString();

      if (mounted) {
        setState(() {
          _tasks[_taskKey] = [
            ..._currentTasks,
            _TaskItem(id: createdId, text: taskText, done: false),
          ];
        });
      }
    } catch (e) {
      debugPrint('[CALENDAR TASK API ERROR] $e');
      if (mounted) {
        setState(() {
          _tasks[_taskKey] = [
            ..._currentTasks,
            _TaskItem(text: taskText, done: false),
          ];
        });
      }
    }
  }

  Future<void> _markCycleDay() async {
    final base = DateTime(_viewYear, _viewMonth, _sel);
    final localKey = _dateKey(base); // non-padded, for grid display
    final paddedKey = _apiDateKey;   // zero-padded, for API

    if (_cycleDays.contains(localKey)) {
      // Unmark — remove from local set immediately, then delete from server
      setState(() => _cycleDays.remove(localKey));
      final id = _cycleDayIds.remove(paddedKey);
      if (id != null) {
        try {
          await ApiService.deleteCycleDay(
            token: widget.user.token ?? '',
            cycleDayId: id,
          );
        } catch (e) {
          debugPrint('[CYCLE DELETE ERROR] $e');
        }
      }
    } else {
      // Mark 3 consecutive days — update UI first, then persist to API
      final localKeys = <String>[];
      final paddedKeys = <String>[];
      for (int i = 0; i < 3; i++) {
        final d = base.add(Duration(days: i));
        localKeys.add(_dateKey(d));
        paddedKeys.add(
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        );
      }
      setState(() => _cycleDays.addAll(localKeys));

      try {
        final results = await ApiService.bulkCreateCycleDays(
          token: widget.user.token ?? '',
          dateKeys: paddedKeys,
        );
        if (mounted) {
          setState(() {
            for (final r in results) {
              final dk = r['date_key'] as String;
              _cycleDayIds[dk] = r['id'].toString();
            }
          });
        }
      } catch (e) {
        debugPrint('[CYCLE MARK ERROR] $e');
      }
    }
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
      child: Column(
        children: [
          _buildMonthNav(),
          if (_showYearPicker) _buildYearPicker(),
          const SizedBox(height: 14),
          _buildCalendarGrid(),
          const SizedBox(height: 6),
          _buildDotLegend(),
          const SizedBox(height: 18),
          _buildDailyPageSection(),
          const SizedBox(height: 14),
          _buildTasksSection(),
          const SizedBox(height: 14),
          _buildCycleSection(),
        ],
      ),
    );
  }

  Widget _buildMonthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SolidButton(
          onTap: _prevMonth,
          icon: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(3.14159),
            child: AppIcons.chevRight(c: Colors.white, s: 16),
          ),
          size: 36,
          color: t.accent,
        ),
        Row(
          children: [
            Text(
              _monthNames[_viewMonth - 1],
              style: AppTypography.playfair(20, t.text),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _showYearPicker = !_showYearPicker),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _showYearPicker ? t.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _showYearPicker ? t.accent : t.border,
                  ),
                ),
                child: Text(
                  '$_viewYear',
                  style: AppTypography.lato700(
                    13,
                    _showYearPicker ? Colors.white : t.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
        SolidButton(
          onTap: _nextMonth,
          icon: AppIcons.chevRight(c: Colors.white, s: 16),
          size: 36,
          color: t.accent,
        ),
      ],
    );
  }

  Widget _buildYearPicker() {
    final currentYear = DateTime.now().year;
    final years = List.generate(12, (i) => currentYear - 5 + i);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children:
            years.map((y) {
              final sel = y == _viewYear;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _viewYear = y;
                    _showYearPicker = false;
                    _sel = 1;
                    _cycleDays.clear();
                    _cycleDayIds.clear();
                  });
                  _fetchDailyPageForSelected();
                  _loadCycleDays();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? t.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: sel ? t.accent : t.border),
                  ),
                  child: Text(
                    '$y',
                    style: AppTypography.lato700(
                      12,
                      sel ? Colors.white : t.muted,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    bool isToday(int d) =>
        d == now.day && _viewMonth == now.month && _viewYear == now.year;

    return AppCard(
      t: t,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Day headers
          Row(
            children:
                ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: AppTypography.lato700(
                              11,
                              t.muted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 8),
          // Grid
          ...List.generate(6, (week) {
            return Row(
              children: List.generate(7, (dow) {
                final dayNum = week * 7 + dow - _firstWeekday + 1;
                if (dayNum < 1 || dayNum > _daysInMonth) {
                  return const Expanded(child: SizedBox(height: 42));
                }
                final selected = dayNum == _sel;
                final today = isToday(dayNum);
                final dayKey = _dateKey(
                  DateTime(_viewYear, _viewMonth, dayNum),
                );
                final hasTask =
                    (_tasks['$_viewYear-$_viewMonth-$dayNum'] ?? []).isNotEmpty;
                final dotDateKey =
                    '$_viewYear-${_viewMonth.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                final hasPage =
                    (_isCurrentMonth &&
                        widget.dailyPages.containsKey(dayNum)) ||
                    (_fetchedPages[dotDateKey] != null);
                final hasCycle = _cycleDays.contains(dayKey);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDay(dayNum),
                    child: Container(
                      height: 42,
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            selected
                                ? t.accent
                                : today
                                ? t.accent.withValues(alpha: 0.22)
                                : Colors.transparent,
                        border:
                            today && !selected
                                ? Border.all(color: t.accent, width: 2)
                                : null,
                        boxShadow:
                            selected
                                ? [
                                  BoxShadow(
                                    color: t.accent.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                  ),
                                ]
                                : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: AppTypography.lato700(
                              13,
                              selected
                                  ? Colors.white
                                  : today
                                  ? t.accent
                                  : t.text,
                            ),
                          ),
                          if (!selected) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (hasTask) _dot(t.gold),
                                if (hasPage) _dot(t.accent),
                                if (hasCycle) _dot(t.cycleRose),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 3,
    height: 3,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
  );

  Widget _buildDotLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Tasks', t.gold),
        const SizedBox(width: 16),
        _legendItem('Page', t.accent),
        const SizedBox(width: 16),
        _legendItem('Cycle', t.cycleRose),
      ],
    );
  }

  Widget _legendItem(String label, Color c) => Row(
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      ),
      const SizedBox(width: 4),
      Text(label, style: AppTypography.lato400(10, t.muted)),
    ],
  );

  Widget _buildDailyPageSection() {
    final dateKey =
        '$_viewYear-${_viewMonth.toString().padLeft(2, '0')}-${_sel.toString().padLeft(2, '0')}';

    DailyPageContent? page;
    final isSessionCurrent =
        _isCurrentMonth && widget.dailyPages.containsKey(_sel);
    if (isSessionCurrent) {
      page = widget.dailyPages[_sel];
    } else {
      page = _fetchedPages[dateKey];
    }

    final hasPage = page != null;

    return AppCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcons.bloom(c: hasPage ? t.accent : t.border, s: 18),
              const SizedBox(width: 8),
              Text('DAILY PAGE', style: AppTypography.sectionLabel(t.muted)),
              const Spacer(),
              if (hasPage && !_loadingPage)
                SolidButton(
                  onTap: () => setState(() => _pageExpanded = !_pageExpanded),
                  icon: Transform.rotate(
                    angle: _pageExpanded ? 0.785 : 0,
                    child: AppIcons.plus(c: Colors.white, s: 14),
                  ),
                  size: 30,
                  color: _pageExpanded ? const Color(0xFF8A5A55) : t.accent,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingPage)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black26),
                  ),
                ),
              ),
            )
          else if (page != null) ...[
            Text(
              '❝ ${page.openingThought} ❞',
              style: AppTypography.dmSerifItalic(15, t.accent, height: 1.5),
            ),
            if (_pageExpanded) ...[
              const SizedBox(height: 14),
              _expandedSection('REFLECTION', page.reflection),
              _expandedSection('FOLLOWUP', page.reflectionFollowup),
              _expandedSection('FEELING', page.emotionalFeeling),
              _expandedSection('NEED', page.emotionalNeed),
              _expandedSection('RESPONSE', page.emotionalResponse),
              _expandedSection('INSIGHT', page.insight),
              // Micro Ritual
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  page.microSkill,
                  style: AppTypography.cormorantItalic(14, t.text, height: 1.5),
                ),
              ),
              // Night Reflection
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C2825), Color(0xFF1E1C1A)],
                  ),
                ),
                child: Text(
                  page.nightReflection,
                  style: AppTypography.dmSerifItalic(
                    15,
                    const Color(0xFFF0EBE3),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ] else
            Text(
              _isCurrentMonth
                  ? 'Open today\'s page from Home to see it here.'
                  : 'No page saved for this day.',
              style: AppTypography.cormorantItalic(14, t.muted),
            ),
        ],
      ),
    );
  }

  Widget _expandedSection(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.lato700(9, t.muted, letterSpacing: 1.2),
          ),
          const SizedBox(height: 3),
          Text(text, style: AppTypography.lato400(13, t.text, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    return AppCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcons.journal(c: t.accent, s: 16),
              const SizedBox(width: 8),
              Text('TASKS', style: AppTypography.sectionLabel(t.muted)),
            ],
          ),
          const SizedBox(height: 10),
          ..._currentTasks.asMap().entries.map((e) {
            final i = e.key;
            final task = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final newDone = !task.done;
                      setState(() {
                        _tasks[_taskKey]![i] = _TaskItem(
                          id: task.id,
                          text: task.text,
                          done: newDone,
                        );
                      });
                      if (task.id != null) {
                        try {
                          await ApiService.updateTask(
                            token: widget.user.token ?? '',
                            taskId: task.id!,
                            completed: newDone,
                          );
                        } catch (err) {
                          debugPrint('[CALENDAR TASK UPDATE API ERROR] $err');
                        }
                      }
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.done ? t.accent : t.border,
                          width: 2,
                        ),
                        color: task.done ? t.accent : Colors.transparent,
                      ),
                      child:
                          task.done
                              ? AppIcons.check(c: Colors.white, s: 12)
                              : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.text,
                      style: AppTypography.lato400(14, t.text).copyWith(
                        decoration:
                            task.done ? TextDecoration.lineThrough : null,
                        color: task.done ? t.muted : t.text,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final removedTask = _tasks[_taskKey]![i];
                      setState(() {
                        _tasks[_taskKey]!.removeAt(i);
                      });
                      if (removedTask.id != null) {
                        try {
                          await ApiService.deleteTask(
                            token: widget.user.token ?? '',
                            taskId: removedTask.id!,
                          );
                        } catch (err) {
                          debugPrint('[CALENDAR TASK DELETE API ERROR] $err');
                        }
                      }
                    },
                    child: AppIcons.close(c: t.muted, s: 14),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  onChanged: (v) => _newTask = v,
                  onSubmitted: (_) => _addTask(),
                  style: AppTypography.lato400(14, t.text),
                  decoration: InputDecoration(
                    hintText: 'Add a task…',
                    hintStyle: AppTypography.lato400(14, t.muted),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
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
                      borderSide: BorderSide(color: t.accent),
                    ),
                    filled: true,
                    fillColor: t.card,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SpeechButton(
                onResult: (s) {
                  setState(() => _newTask = s);
                  _taskController.text = s;
                  _taskController.selection = TextSelection.fromPosition(
                    TextPosition(offset: s.length),
                  );
                },
                t: t,
                size: 36,
              ),
              const SizedBox(width: 8),
              SolidButton(
                onTap: _addTask,
                icon: AppIcons.plus(c: Colors.white, s: 14),
                size: 36,
                color: t.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCycleSection() {
    final selKey = _dateKey(DateTime(_viewYear, _viewMonth, _sel));
    final isMarked = _cycleDays.contains(selKey);

    // Get cycle days for display
    final sortedDays = _cycleDays.toList()..sort();

    return AppCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, color: t.cycleRose, size: 16),
              const SizedBox(width: 8),
              Text('CYCLE', style: AppTypography.sectionLabel(t.muted)),
              const Spacer(),
              SolidButton(
                onTap: _markCycleDay,
                icon:
                    isMarked
                        ? AppIcons.check(c: Colors.white, s: 14)
                        : AppIcons.plus(c: Colors.white, s: 14),
                size: 30,
                color: isMarked ? t.cycleRose : t.accent,
              ),
            ],
          ),
          if (sortedDays.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  sortedDays.map((key) {
                    final parts = key.split('-');
                    final d = DateTime(
                      int.parse(parts[0]),
                      int.parse(parts[1]),
                      int.parse(parts[2]),
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: t.cycleRose.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: t.cycleRose.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        '${d.day} ${_shortMonths[d.month - 1]}',
                        style: AppTypography.lato400(11, t.cycleRose),
                      ),
                    );
                  }).toList(),
            ),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _TaskItem {
  final String? id;
  final String text;
  final bool done;
  _TaskItem({this.id, required this.text, required this.done});
}
