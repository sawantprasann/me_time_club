import 'dart:math';
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
  const JournalTab({super.key, required this.user, required this.t});

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
  String _newTask = '';
  bool _chamomileDone = false;
  // Shopping sub-tab
  final List<_ShopCategory> _categories = [
    _ShopCategory(name: 'Groceries', color: const Color(0xFF7A9E8E)),
    _ShopCategory(name: 'Baby', color: const Color(0xFFB8906A)),
    _ShopCategory(name: 'Self Care', color: const Color(0xFFB8706A)),
    _ShopCategory(name: 'Household', color: const Color(0xFF8A7D76)),
  ];
  String? _openCat;
  String _newItem = '';
  bool _addingCat = false;
  String _newCatName = '';
  final Map<String, List<_ShopItem>> _shopItems = {};

  final _palette = [
    const Color(0xFFB8706A),
    const Color(0xFFC4945A),
    const Color(0xFF7A9E8E),
    const Color(0xFF9E9E7A),
    const Color(0xFFA0887A),
  ];

  AppTokens get t => widget.t;

  @override
  void initState() {
    super.initState();
    _openCat = _categories.first.name;
    _fetchPastEntries();
    _fetchShoppingItems();
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

  void _fetchShoppingItems() async {
    try {
      final items = await ApiService.getShoppingItems(
        token: widget.user.token ?? '',
      );

      final Map<String, List<_ShopItem>> loadedItems = {};
      for (final cat in _categories) {
        loadedItems[cat.name] = [];
      }

      for (final item in items) {
        final id = item['id']?.toString();
        final name = item['name']?.toString() ?? '';
        final done = item['checked'] as bool? ?? false;

        if (name.contains('|')) {
          final parts = name.split('|');
          final catName = parts[0];
          final itemName = parts.sublist(1).join('|');

          if (!loadedItems.containsKey(catName)) {
            loadedItems[catName] = [];
          }
          loadedItems[catName]!.add(
            _ShopItem(id: id, text: itemName, done: done),
          );
        } else {
          const defaultCat = 'Groceries';
          if (!loadedItems.containsKey(defaultCat)) {
            loadedItems[defaultCat] = [];
          }
          loadedItems[defaultCat]!.add(
            _ShopItem(id: id, text: name, done: done),
          );
        }
      }

      if (mounted) {
        setState(() {
          _shopItems.clear();
          _shopItems.addAll(loadedItems);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
      child: Column(
        children: [
          _buildSubTabs(),
          const SizedBox(height: 16),
          if (_sub == 'journal') _buildJournal(),
          if (_sub == 'tasks') _buildTasks(),
          if (_sub == 'shopping') _buildShopping(),
        ],
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
                onChanged: (v) => _newTask = v,
                onSubmitted: (_) => _addTask(),
                controller: TextEditingController(text: _newTask),
                style: AppTypography.lato400(14, t.text),
                decoration: _inputDeco('Add a task…'),
              ),
            ),
            const SizedBox(width: 8),
            SpeechButton(
              onResult: (s) => setState(() => _newTask = s),
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
    if (_newTask.trim().isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final taskText = _newTask.trim();
    setState(() {
      _newTask = '';
    });

    try {
      final res = await ApiService.createTask(
        token: widget.user.token ?? '',
        title: taskText,
        completed: false,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category pills
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ..._categories.map((cat) {
              final active = _openCat == cat.name;
              final items = _shopItems[cat.name] ?? [];
              final remaining = items.where((i) => !i.done).length;
              return GestureDetector(
                onTap: () => setState(() => _openCat = cat.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                        active
                            ? cat.color.withValues(alpha: 0.2)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? cat.color : t.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat.name,
                        style:
                            active
                                ? AppTypography.lato700(12, cat.color)
                                : AppTypography.lato400(12, t.muted),
                      ),
                      if (remaining > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cat.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$remaining',
                            style: AppTypography.lato700(10, Colors.white),
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
              onTap: () => setState(() => _addingCat = !_addingCat),
              icon:
                  _addingCat
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
                  autofocus: true,
                  onChanged: (v) => _newCatName = v,
                  style: AppTypography.lato400(14, t.text),
                  decoration: _inputDeco('Category name…'),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (_newCatName.trim().isNotEmpty) {
                    setState(() {
                      _categories.add(
                        _ShopCategory(
                          name: _newCatName.trim(),
                          color: _palette[Random().nextInt(_palette.length)],
                        ),
                      );
                      _openCat = _newCatName.trim();
                      _newCatName = '';
                      _addingCat = false;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: t.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Add',
                    style: AppTypography.lato700(12, Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // Items for selected category
        if (_openCat != null) ...[
          Builder(
            builder: (_) {
              final cat = _categories.firstWhere(
                (c) => c.name == _openCat,
                orElse: () => _categories.first,
              );
              final items = _shopItems[cat.name] ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cat.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(cat.name, style: AppTypography.lato700(12, t.text)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...items.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final newDone = !item.done;
                              setState(() {
                                _shopItems[cat.name]![i] = _ShopItem(
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
                                    name: '${cat.name}|${item.text}',
                                    checked: newDone,
                                  );
                                } catch (err) {
                                  debugPrint(
                                    '[UPDATE SHOPPING ITEM ERROR] $err',
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: item.done ? cat.color : t.border,
                                  width: 2,
                                ),
                                color:
                                    item.done ? cat.color : Colors.transparent,
                              ),
                              child:
                                  item.done
                                      ? AppIcons.check(c: Colors.white, s: 12)
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.text,
                              style: AppTypography.lato400(14, t.text).copyWith(
                                decoration:
                                    item.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                color: item.done ? t.muted : t.text,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final removedItem = _shopItems[cat.name]![i];
                              setState(() {
                                _shopItems[cat.name]!.removeAt(i);
                              });
                              if (removedItem.id != null) {
                                try {
                                  await ApiService.deleteShoppingItem(
                                    token: widget.user.token ?? '',
                                    itemId: removedItem.id!,
                                  );
                                } catch (err) {
                                  debugPrint(
                                    '[DELETE SHOPPING ITEM ERROR] $err',
                                  );
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
                          onChanged: (v) => _newItem = v,
                          onSubmitted: (_) => _addItem(cat.name),
                          controller: TextEditingController(text: _newItem),
                          style: AppTypography.lato400(14, t.text),
                          decoration: _inputDeco('Add an item…'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SpeechButton(
                        onResult: (s) => setState(() => _newItem = s),
                        t: t,
                        size: 38,
                      ),
                      const SizedBox(width: 8),
                      SolidButton(
                        onTap: () => _addItem(cat.name),
                        icon: AppIcons.plus(c: Colors.white, s: 14),
                        size: 36,
                        color: t.accent,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  void _addItem(String catName) async {
    if (_newItem.trim().isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final itemText = _newItem.trim();
    setState(() {
      _newItem = '';
    });

    try {
      final nameWithCat = '$catName|$itemText';
      final res = await ApiService.createShoppingItem(
        token: widget.user.token ?? '',
        name: nameWithCat,
        checked: false,
      );
      final createdId = res['id']?.toString();

      if (mounted) {
        setState(() {
          _shopItems[catName] = [
            ...(_shopItems[catName] ?? []),
            _ShopItem(id: createdId, text: itemText, done: false),
          ];
        });
      }
    } catch (e) {
      debugPrint('[CREATE SHOPPING ITEM ERROR] $e');
      if (mounted) {
        setState(() {
          _shopItems[catName] = [
            ...(_shopItems[catName] ?? []),
            _ShopItem(text: itemText, done: false),
          ];
        });
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
  final String name;
  final Color color;
  _ShopCategory({required this.name, required this.color});
}

class _ShopItem {
  final String? id;
  final String text;
  final bool done;
  _ShopItem({this.id, required this.text, required this.done});
}
