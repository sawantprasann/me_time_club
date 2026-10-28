import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../icons/app_icons.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/voice_text_input.dart';
import '../../widgets/speech_button.dart';

class JournalTab extends StatefulWidget {
  final UserProfile user;
  final AppTokens t;
  final bool isActive;
  final int? refreshTrigger;

  const JournalTab({
    super.key,
    required this.user,
    required this.t,
    this.isActive = false,
    this.refreshTrigger,
  });

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  String _sub = 'journal'; // journal | tasks | shopping
  // Journal sub-tab
  String _journalText = '';
  String? _journalEntryId;
  bool _saved = false;
  List<dynamic> _pastEntries = [];
  bool _loadingEntries = false;

  // Tasks sub-tab
  final List<_TaskItem> _tasks = [];
  final TextEditingController _newTaskCtrl = TextEditingController();
  bool _loadingTasks = false;
  bool _chamomileDone = false;
  // Shopping sub-tab
  final List<_ShopCategory> _categories = [];
  bool _loadingCategories = true;
  int? _openCat; // null means 'All' categories
  int? _targetAddCatId; // target category for global item addition
  final TextEditingController _globalItemCtrl = TextEditingController();
  bool _addingItemLoading = false;
  bool _addingCat = false;
  final TextEditingController _newCatCtrl = TextEditingController();
  bool _addingCatLoading = false;
  final Map<int, List<_ShopItem>> _shopItems = {};
  // Inline rename state
  int? _editingCatId;
  String _editingCatName = '';
  String? _editingItemId; // item id being renamed
  String _editingItemText = '';

  AppTokens get t => widget.t;

  @override
  void initState() {
    super.initState();
    _refreshAllData();
  }

  @override
  void didUpdateWidget(covariant JournalTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final becameActive = widget.isActive && !oldWidget.isActive;
    final refreshChanged = widget.refreshTrigger != null &&
        widget.refreshTrigger != oldWidget.refreshTrigger;
    if (becameActive || (widget.isActive && refreshChanged)) {
      _refreshAllData();
    }
  }

  Future<void> _refreshAllData() async {
    _fetchPastEntries();
    _fetchTasks();
    _fetchShoppingCategories();
  }

  @override
  void dispose() {
    _newTaskCtrl.dispose();
    _newCatCtrl.dispose();
    _globalItemCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() => _loadingTasks = true);
    try {
      final raw = await ApiService.getTasks(
        token: widget.user.token ?? '',
      );
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(
            raw.map(
              (t) => _TaskItem(
                id: t['id']?.toString(),
                text: t['title'] as String? ?? '',
                done: t['completed'] as bool? ?? false,
              ),
            ),
          );
        _loadingTasks = false;
      });
    } catch (e) {
      debugPrint('[FETCH TASKS ERROR] $e');
      if (mounted) setState(() => _loadingTasks = false);
    }
  }

  void _fetchPastEntries() async {
    setState(() {
      _loadingEntries = true;
    });

    try {
      final entries = await ApiService.getJournalEntries(
        token: widget.user.token ?? '',
      );
      if (mounted) {
        setState(() {
          _pastEntries = entries;
          _loadingEntries = false;
        });
      }
    } catch (e) {
      debugPrint('[FETCH JOURNAL ENTRIES ERROR] $e');
      if (mounted) {
        setState(() {
          _loadingEntries = false;
        });
      }
    }
  }

  Future<void> _fetchShoppingCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final raw = await ApiService.getShoppingCategories(
        token: widget.user.token ?? '',
      );
      if (!mounted) return;
      final cats = raw
          .map((c) => _ShopCategory(
                id: c['id'] as int,
                name: c['name'] as String? ?? '',
                isSystem: c['system'] as bool? ?? false,
              ))
          .toList();
      setState(() {
        _categories
          ..clear()
          ..addAll(cats);
        _openCat = null;
        if (_targetAddCatId == null || !cats.any((c) => c.id == _targetAddCatId)) {
          _targetAddCatId = cats.isNotEmpty ? cats.first.id : null;
        }
        _loadingCategories = false;
      });
      _fetchShoppingItems();
    } catch (e) {
      debugPrint('[FETCH SHOPPING CATEGORIES ERROR] $e');
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _fetchShoppingItems() async {
    try {
      final items = await ApiService.getShoppingItems(
        token: widget.user.token ?? '',
      );

      final Map<int, List<_ShopItem>> loadedItems = {};
      for (final cat in _categories) {
        loadedItems[cat.id] = [];
      }

      for (final item in items) {
        final itemId = item['id']?.toString();
        final name = item['name']?.toString() ?? '';
        final done = item['checked'] as bool? ?? false;
        final catId = item['category_id'] as int?;

        if (catId != null) {
          loadedItems.putIfAbsent(catId, () => []);
          loadedItems[catId]!.add(_ShopItem(id: itemId, text: name, done: done));
        } else if (_categories.isNotEmpty) {
          final defaultId = _categories.first.id;
          loadedItems.putIfAbsent(defaultId, () => []);
          loadedItems[defaultId]!.add(_ShopItem(id: itemId, text: name, done: done));
        }
      }

      if (mounted) {
        setState(() {
          _shopItems
            ..clear()
            ..addAll(loadedItems);
        });
      }
    } catch (e) {
      debugPrint('[FETCH SHOPPING ITEMS ERROR] $e');
    }
  }

  String get _dateLabel {
    final now = DateTime.now();
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
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
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: t.accent,
      onRefresh: _refreshAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          children: [
            _buildSubTabs(),
            const SizedBox(height: 16),
            if (_sub == 'journal') _buildJournal(),
            if (_sub == 'tasks') _buildTasks(),
            if (_sub == 'shopping') _buildShopping(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabs() {
    return Row(
      children:
          ['journal', 'tasks', 'shopping'].map((s) {
            final active = _sub == s;
            final label = s[0].toUpperCase() + s.substring(1);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _sub = s),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: active ? t.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style:
                          active
                              ? AppTypography.lato700(14, t.accent)
                              : AppTypography.lato400(14, t.muted),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  void _saveJournalEntry() async {
    if (_journalText.trim().isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saved = false;
    });

    try {
      if (_journalEntryId == null) {
        await ApiService.createJournalEntry(
          token: widget.user.token ?? '',
          body: _journalText.trim(),
        );
        if (mounted) {
          setState(() {
            _journalText = '';
            _journalEntryId = null;
            _saved = true;
          });
          _fetchPastEntries();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _saved = false;
              });
            }
          });
        }
      } else {
        await ApiService.updateJournalEntry(
          token: widget.user.token ?? '',
          entryId: _journalEntryId!,
          body: _journalText.trim(),
        );
        if (mounted) {
          setState(() {
            _journalText = '';
            _journalEntryId = null;
            _saved = true;
          });
          _fetchPastEntries();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _saved = false;
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[JOURNAL SAVE ERROR] $e');
      if (mounted) {
        setState(() {
          _saved = true;
        });
      }
    }
  }

  // ─── Journal Sub-Tab ─────────────────────────────
  Widget _buildJournal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _dateLabel,
          style: AppTypography.lato700(10, t.muted, letterSpacing: 1.8),
        ),
        const SizedBox(height: 14),
        VoiceTextArea(
          value: _journalText,
          onChange:
              (v) => setState(() {
                _journalText = v;
                _saved = false;
              }),
          placeholder: 'A quiet place to write. No prompts. No pressure.',
          t: t,
          rows: 10,
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _saveJournalEntry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _saved ? t.green : t.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_saved) ...[
                  AppIcons.check(c: Colors.white, s: 16),
                  const SizedBox(width: 8),
                ],
                Text(
                  _saved ? 'Saved' : 'Save Entry',
                  style: AppTypography.lato700(14, Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'PAST JOURNAL ENTRIES',
          style: AppTypography.lato700(10, t.muted, letterSpacing: 1.8),
        ),
        const SizedBox(height: 12),
        if (_loadingEntries)
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
        else if (_pastEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'No past entries found.',
              style: AppTypography.cormorantItalic(14, t.muted),
            ),
          )
        else
          Column(
            children:
                _pastEntries.map((entry) {
                  final entryId = entry['id']?.toString() ?? '';
                  final body = entry['body']?.toString() ?? '';
                  final createdAtStr = entry['created_at']?.toString() ?? '';

                  DateTime? date;
                  try {
                    date = DateTime.parse(createdAtStr);
                  } catch (_) {}

                  String dateString = 'Unknown Date';
                  if (date != null) {
                    final months = [
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
                    dateString =
                        '${date.day} ${months[date.month - 1]} ${date.year}';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() {
                                _journalText = body;
                                _journalEntryId = entryId;
                                _saved = true;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateString,
                                  style: AppTypography.lato700(10, t.accent),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  style: AppTypography.lato400(13, t.text),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            try {
                              await ApiService.deleteJournalEntry(
                                token: widget.user.token ?? '',
                                entryId: entryId,
                              );
                              _fetchPastEntries();
                              if (_journalEntryId == entryId) {
                                setState(() {
                                  _journalText = '';
                                  _journalEntryId = null;
                                  _saved = false;
                                });
                              }
                            } catch (e) {
                              debugPrint('[DELETE JOURNAL ENTRY ERROR] $e');
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: t.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }

  // ─── Tasks Sub-Tab ───────────────────────────────
  Widget _buildTasks() {
    return Column(
      children: [
        // Chamomile reminder card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                t.accent.withValues(alpha: 0.14),
                t.gold.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(color: t.accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _chamomileDone = !_chamomileDone),
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          _chamomileDone
                              ? t.accent
                              : t.accent.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    color: _chamomileDone ? t.accent : Colors.transparent,
                  ),
                  child:
                      _chamomileDone
                          ? AppIcons.check(c: Colors.white, s: 12)
                          : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIcons.bloom(c: t.accent, s: 14),
                        const SizedBox(width: 6),
                        Text(
                          'CHAMOMILE\'S REMINDER',
                          style: AppTypography.sectionLabel(t.accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Take 5 minutes just for yourself today — even if it\'s just a cup of tea in quiet.',
                      style: AppTypography.lato400(14, t.text, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_loadingTasks && _tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(t.accent),
                ),
              ),
            ),
          ),
        // User tasks
        ..._tasks.asMap().entries.map((e) {
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
                      _tasks[i] = _TaskItem(
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
                        debugPrint('[JOURNAL TASK UPDATE API ERROR] $err');
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
                      decoration: task.done ? TextDecoration.lineThrough : null,
                      color: task.done ? t.muted : t.text,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final removedTask = _tasks[i];
                    setState(() {
                      _tasks.removeAt(i);
                    });
                    if (removedTask.id != null) {
                      try {
                        await ApiService.deleteTask(
                          token: widget.user.token ?? '',
                          taskId: removedTask.id!,
                        );
                      } catch (err) {
                        debugPrint('[JOURNAL TASK DELETE API ERROR] $err');
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
                controller: _newTaskCtrl,
                onSubmitted: (_) => _addTask(),
                style: AppTypography.lato400(14, t.text),
                decoration: _inputDeco('Add a task…'),
              ),
            ),
            const SizedBox(width: 8),
            SpeechButton(
              onResult: (s) => setState(() => _newTaskCtrl.text = s),
              t: t,
              size: 38,
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
    );
  }

  void _addTask() async {
    final taskText = _newTaskCtrl.text.trim();
    if (taskText.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _newTaskCtrl.clear();
    });

    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

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
          _tasks.add(_TaskItem(id: createdId, text: taskText, done: false));
        });
      }
    } catch (e) {
      debugPrint('[JOURNAL TASK API ERROR] $e');
      if (mounted) {
        setState(() {
          _tasks.add(_TaskItem(text: taskText, done: false));
        });
      }
    }
  }

  // ─── Shopping Sub-Tab ────────────────────────────
  Widget _buildShopping() {
    if (_loadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category pills
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // "All" filter pill
            GestureDetector(
              onTap: () => setState(() => _openCat = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _openCat == null ? t.accent.withValues(alpha: 0.15) : t.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _openCat == null ? t.accent : t.border.withValues(alpha: 0.8),
                    width: _openCat == null ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  'All',
                  style: _openCat == null
                      ? AppTypography.lato700(12, t.accent)
                      : AppTypography.lato400(12, t.muted),
                ),
              ),
            ),
            ..._categories.map((cat) {
              final active = _openCat == cat.id;
              final items = _shopItems[cat.id] ?? [];
              final remaining = items.where((i) => !i.done).length;
              // Inline rename for this pill
              if (_editingCatId == cat.id) {
                return SizedBox(
                  width: 140,
                  child: TextField(
                    autofocus: true,
                    controller: TextEditingController(text: _editingCatName)
                      ..selection = TextSelection.collapsed(offset: _editingCatName.length),
                    onChanged: (v) => _editingCatName = v,
                    onSubmitted: (_) => _renameCategory(cat.id, _editingCatName),
                    onTapOutside: (_) => _renameCategory(cat.id, _editingCatName),
                    style: AppTypography.lato400(13, t.text),
                    decoration: _inputDeco('Category name…'),
                  ),
                );
              }
              return GestureDetector(
                onTap: () => setState(() {
                  _openCat = active ? null : cat.id;
                  if (_openCat != null) _targetAddCatId = _openCat;
                }),
                onLongPress: () => _showCategoryOptions(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? t.accent.withValues(alpha: 0.15) : t.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? t.accent : t.border.withValues(alpha: 0.8),
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat.name,
                        style: active
                            ? AppTypography.lato700(12, t.accent)
                            : AppTypography.lato400(12, t.muted),
                      ),
                      if (remaining > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: active ? t.accent : t.muted.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$remaining',
                            style: AppTypography.lato700(
                              10,
                              active ? Colors.white : t.muted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            // Add category button
            SolidButton(
              onTap: () {
                setState(() {
                  _addingCat = !_addingCat;
                  if (!_addingCat) _newCatCtrl.clear();
                });
              },
              icon: _addingCat
                  ? AppIcons.close(c: Colors.white, s: 12)
                  : AppIcons.plus(c: Colors.white, s: 14),
              size: 30,
              color: t.accent,
            ),
          ],
        ),
        // New category input
        if (_addingCat) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newCatCtrl,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCategory(),
                  style: AppTypography.lato400(14, t.text),
                  decoration: _inputDeco('Category name…'),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addingCatLoading ? null : _addCategory,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _addingCatLoading ? t.accent.withValues(alpha: 0.5) : t.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _addingCatLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Add', style: AppTypography.lato700(12, Colors.white)),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // Global Add Item Bar
        if (_categories.isNotEmpty)
          Builder(
            builder: (_) {
              final effectiveCatId = _openCat ??
                  _targetAddCatId ??
                  (_categories.isNotEmpty ? _categories.first.id : null);
              final targetCat = _categories.firstWhere(
                (c) => c.id == effectiveCatId,
                orElse: () => _categories.first,
              );

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.border.withValues(alpha: 0.7)),
                  boxShadow: t.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Add to',
                          style: AppTypography.lato700(12, t.muted),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<int>(
                          initialValue: targetCat.id,
                          tooltip: 'Choose category',
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          color: t.card,
                          onSelected: (id) => setState(() => _targetAddCatId = id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: t.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: t.accent.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: t.accent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  targetCat.name,
                                  style: AppTypography.lato700(12, t.accent),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down, size: 14, color: t.accent),
                              ],
                            ),
                          ),
                          itemBuilder: (ctx) => _categories.map((c) {
                            final isSelected = c.id == targetCat.id;
                            return PopupMenuItem<int>(
                              value: c.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? t.accent : t.muted.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    c.name,
                                    style: AppTypography.lato400(
                                      13,
                                      isSelected ? t.accent : t.text,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _globalItemCtrl,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addGlobalItem(),
                            style: AppTypography.lato400(14, t.text),
                            decoration: _inputDeco('Add an item to ${targetCat.name}…'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SpeechButton(
                          onResult: (s) => setState(() => _globalItemCtrl.text = s),
                          t: t,
                          size: 38,
                        ),
                        const SizedBox(width: 8),
                        SolidButton(
                          onTap: _addGlobalItem,
                          icon: _addingItemLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : AppIcons.plus(c: Colors.white, s: 14),
                          size: 36,
                          color: t.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 20),
        // All categories & their lists on screen
        if (_categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No categories yet', style: AppTypography.lato400(14, t.muted)),
            ),
          )
        else ...[
          Builder(
            builder: (_) {
              final catsToShow = _openCat == null
                  ? _categories
                  : _categories.where((c) => c.id == _openCat).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: catsToShow.map((cat) {
                  final items = _shopItems[cat.id] ?? [];
                  final remaining = items.where((i) => !i.done).length;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: t.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: t.border.withValues(alpha: 0.7)),
                      boxShadow: t.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: t.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: AppTypography.lato700(15, t.text),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: remaining > 0
                                      ? t.accent.withValues(alpha: 0.12)
                                      : t.muted.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  remaining > 0 ? '$remaining left' : 'All done',
                                  style: AppTypography.lato700(
                                    11,
                                    remaining > 0 ? t.accent : t.muted,
                                  ),
                                ),
                              ),
                              if (!cat.isSystem) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showCategoryOptions(cat),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: AppIcons.pen(c: t.muted, s: 13),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Divider(color: t.border.withValues(alpha: 0.4), height: 1),
                        // Items list
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 16,
                                  color: t.muted.withValues(alpha: 0.45),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'No items in ${cat.name}',
                                  style: AppTypography.lato400(13, t.muted).copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => Divider(
                              color: t.border.withValues(alpha: 0.25),
                              height: 1,
                              indent: 36,
                            ),
                            itemBuilder: (context, i) {
                              final item = items[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _toggleShoppingItem(cat.id, i),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: item.done ? t.accent : t.border,
                                            width: 1.8,
                                          ),
                                          color: item.done ? t.accent : Colors.transparent,
                                        ),
                                        child: item.done
                                            ? AppIcons.check(c: Colors.white, s: 12)
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _editingItemId == item.id && item.id != null
                                          ? TextField(
                                              autofocus: true,
                                              controller: TextEditingController(text: _editingItemText)
                                                ..selection = TextSelection.collapsed(
                                                    offset: _editingItemText.length),
                                              onChanged: (v) => _editingItemText = v,
                                              onSubmitted: (_) =>
                                                  _renameItem(cat.id, i, _editingItemText),
                                              onTapOutside: (_) =>
                                                  _renameItem(cat.id, i, _editingItemText),
                                              style: AppTypography.lato400(14, t.text),
                                              decoration: _inputDeco('Item name…'),
                                            )
                                          : GestureDetector(
                                              onLongPress: item.id != null
                                                  ? () => setState(() {
                                                        _editingItemId = item.id;
                                                        _editingItemText = item.text;
                                                      })
                                                  : null,
                                              child: Text(
                                                item.text,
                                                style: AppTypography.lato400(14, t.text).copyWith(
                                                  decoration: item.done
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                  color: item.done ? t.muted : t.text,
                                                ),
                                              ),
                                            ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _deleteShoppingItem(cat.id, i),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: AppIcons.close(
                                          c: t.muted.withValues(alpha: 0.6),
                                          s: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _addCategory() async {
    final name = _newCatCtrl.text.trim();
    if (name.isEmpty || _addingCatLoading) return;
    setState(() => _addingCatLoading = true);
    try {
      final res = await ApiService.createShoppingCategory(
        token: widget.user.token ?? '',
        name: name,
      );
      if (res != null && mounted) {
        final catData = res['category'] is Map<String, dynamic>
            ? res['category'] as Map<String, dynamic>
            : res;
        final rawId = catData['id'];
        final catId = rawId is int
            ? rawId
            : int.tryParse(rawId?.toString() ?? '') ??
                DateTime.now().millisecondsSinceEpoch;
        final newCat = _ShopCategory(
          id: catId,
          name: catData['name'] as String? ?? name,
          isSystem: false,
        );
        setState(() {
          _categories.add(newCat);
          _shopItems[newCat.id] = [];
          _openCat = null;
          _newCatCtrl.clear();
          _addingCat = false;
          _addingCatLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[CREATE CATEGORY ERROR] $e');
      if (mounted) {
        setState(() => _addingCatLoading = false);
        final message =
            e is ApiException ? e.message : 'Failed to create category: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(int catId) async {
    final cat = _categories.firstWhere((c) => c.id == catId);
    if (cat.isSystem) return;
    setState(() {
      _categories.removeWhere((c) => c.id == catId);
      _shopItems.remove(catId);
      if (_openCat == catId) _openCat = null;
      if (_targetAddCatId == catId) {
        _targetAddCatId = _categories.isNotEmpty ? _categories.first.id : null;
      }
    });
    try {
      await ApiService.deleteShoppingCategory(
        token: widget.user.token ?? '',
        categoryId: catId,
      );
    } catch (e) {
      debugPrint('[DELETE CATEGORY ERROR] $e');
    }
  }

  Future<void> _renameCategory(int catId, String newName) async {
    if (newName.trim().isEmpty) return;
    final name = newName.trim();
    setState(() {
      final idx = _categories.indexWhere((c) => c.id == catId);
      if (idx != -1) {
        _categories[idx] = _ShopCategory(id: catId, name: name, isSystem: false);
      }
      _editingCatId = null;
      _editingCatName = '';
    });
    try {
      await ApiService.updateShoppingCategory(
        token: widget.user.token ?? '',
        categoryId: catId,
        name: name,
      );
    } catch (e) {
      debugPrint('[RENAME CATEGORY ERROR] $e');
    }
  }

  Future<void> _renameItem(int catId, int itemIdx, String newName) async {
    if (newName.trim().isEmpty) return;
    final name = newName.trim();
    final item = _shopItems[catId]![itemIdx];
    setState(() {
      _shopItems[catId]![itemIdx] = _ShopItem(id: item.id, text: name, done: item.done);
      _editingItemId = null;
      _editingItemText = '';
    });
    if (item.id != null) {
      try {
        await ApiService.updateShoppingItem(
          token: widget.user.token ?? '',
          itemId: item.id!,
          name: name,
          checked: item.done,
          categoryId: catId,
        );
      } catch (e) {
        debugPrint('[RENAME ITEM ERROR] $e');
      }
    }
  }

  void _showCategoryOptions(_ShopCategory cat) {
    if (cat.isSystem) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(cat.name, style: AppTypography.playfair(16, t.text)),
            ),
            const Divider(),
            ListTile(
              leading: AppIcons.pen(c: t.accent, s: 18),
              title: Text('Rename', style: AppTypography.lato700(14, t.text)),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _editingCatId = cat.id;
                  _editingCatName = cat.name;
                });
              },
            ),
            ListTile(
              leading: AppIcons.close(c: Colors.redAccent, s: 18),
              title: Text('Delete', style: AppTypography.lato700(14, Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                _deleteCategory(cat.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _addGlobalItem() async {
    final text = _globalItemCtrl.text.trim();
    if (text.isEmpty || _addingItemLoading) return;

    final targetCatId = _openCat ??
        _targetAddCatId ??
        (_categories.isNotEmpty ? _categories.first.id : null);
    if (targetCatId == null) return;

    FocusManager.instance.primaryFocus?.unfocus();
    _globalItemCtrl.clear();
    setState(() => _addingItemLoading = true);

    try {
      final res = await ApiService.createShoppingItem(
        token: widget.user.token ?? '',
        name: text,
        checked: false,
        categoryId: targetCatId,
      );
      final createdId = res['id']?.toString();

      if (mounted) {
        setState(() {
          _shopItems[targetCatId] = [
            ...(_shopItems[targetCatId] ?? []),
            _ShopItem(id: createdId, text: text, done: false),
          ];
          _addingItemLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[CREATE SHOPPING ITEM ERROR] $e');
      if (mounted) {
        setState(() {
          _shopItems[targetCatId] = [
            ...(_shopItems[targetCatId] ?? []),
            _ShopItem(text: text, done: false),
          ];
          _addingItemLoading = false;
        });
      }
    }
  }

  Future<void> _toggleShoppingItem(int catId, int i) async {
    final item = _shopItems[catId]![i];
    final newDone = !item.done;
    setState(() {
      _shopItems[catId]![i] = _ShopItem(
        id: item.id,
        text: item.text,
        done: newDone,
      );
    });
    if (item.id != null) {
      try {
        await ApiService.updateShoppingItem(
          token: widget.user.token ?? '',
          itemId: item.id!,
          checked: newDone,
          categoryId: catId,
        );
      } catch (err) {
        debugPrint('[UPDATE SHOPPING ITEM ERROR] $err');
      }
    }
  }

  Future<void> _deleteShoppingItem(int catId, int i) async {
    final removedItem = _shopItems[catId]![i];
    setState(() => _shopItems[catId]!.removeAt(i));
    if (removedItem.id != null) {
      try {
        await ApiService.deleteShoppingItem(
          token: widget.user.token ?? '',
          itemId: removedItem.id!,
        );
      } catch (err) {
        debugPrint('[DELETE SHOPPING ITEM ERROR] $err');
      }
    }
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppTypography.lato400(14, t.muted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
  );
}

class _TaskItem {
  final String? id;
  final String text;
  final bool done;
  _TaskItem({this.id, required this.text, required this.done});
}

class _ShopCategory {
  final int id;
  final String name;
  final bool isSystem;
  _ShopCategory({required this.id, required this.name, required this.isSystem});
}

class _ShopItem {
  final String? id;
  final String text;
  final bool done;
  _ShopItem({this.id, required this.text, required this.done});
}
