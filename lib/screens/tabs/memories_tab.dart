import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/tokens.dart';
import '../../icons/app_icons.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/voice_text_input.dart';

class MemoriesTab extends StatefulWidget {
  final UserProfile user;
  final AppTokens t;
  const MemoriesTab({
    super.key,
    required this.user,
    required this.t,
  });

  @override
  State<MemoriesTab> createState() => _MemoriesTabState();
}

class _MemoriesTabState extends State<MemoriesTab> {
  final List<_Memory> _memories = [];
  bool _loading = false;
  bool _adding = false;
  bool _saving = false;
  String _newTitle = '';
  String _newBody = '';

  String? _editingId;
  String _editTitle = '';
  String _editBody = '';

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
    _loadMemories();
  }

  void _loadMemories() async {
    setState(() {
      _loading = true;
    });

    try {
      final list = await ApiService.getMemories(token: widget.user.token ?? '');
      final loaded = list.map((item) {
        final id = item['id'].toString();
        final title = item['title']?.toString() ?? 'Memorable Moment';
        final bodyVal = item['body']?.toString() ?? '';
        final createdAtStr = item['created_at']?.toString() ?? '';

        DateTime date = DateTime.now();
        try {
          date = DateTime.parse(createdAtStr);
        } catch (_) {}

        return _Memory(
          id: id,
          title: title,
          body: bodyVal,
          color: _palette[Random().nextInt(_palette.length)],
          date: date,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _memories.clear();
          _memories.addAll(loaded);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[LOAD MEMORIES ERROR] $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load moments: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _saveMemory() async {
    if (_newTitle.trim().isEmpty || _newBody.trim().isEmpty) return;

    final titleText = _newTitle.trim();
    final bodyText = _newBody.trim();

    setState(() {
      _saving = true;
    });

    try {
      final res = await ApiService.createMemory(
        token: widget.user.token ?? '',
        title: titleText,
        body: bodyText,
      );

      final newId = res['id']?.toString() ?? '0';
      final bodyVal = res['body']?.toString() ?? bodyText;

      final newMemory = _Memory(
        id: newId,
        title: titleText,
        body: bodyVal,
        color: _palette[Random().nextInt(_palette.length)],
        date: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _memories.insert(0, newMemory);
          _adding = false;
          _newTitle = '';
          _newBody = '';
          _saving = false;
        });
      }
    } catch (e) {
      debugPrint('[CREATE MEMORY ERROR] $e');
      if (mounted) {
        setState(() {
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save moment: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _updateMemory(String id) async {
    if (_editTitle.trim().isEmpty || _editBody.trim().isEmpty) return;

    final titleText = _editTitle.trim();
    final bodyText = _editBody.trim();

    setState(() {
      _saving = true;
    });

    try {
      await ApiService.updateMemory(
        token: widget.user.token ?? '',
        memoryId: id,
        title: titleText,
        body: bodyText,
      );

      if (mounted) {
        setState(() {
          final idx = _memories.indexWhere((m) => m.id == id);
          if (idx != -1) {
            _memories[idx].title = titleText;
            _memories[idx].body = bodyText;
          }
          _editingId = null;
          _editTitle = '';
          _editBody = '';
          _saving = false;
        });
      }
    } catch (e) {
      debugPrint('[UPDATE MEMORY ERROR] $e');
      if (mounted) {
        setState(() {
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update moment: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _deleteMemory(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        title: Text('Delete Moment', style: AppTypography.playfair(18, t.text)),
        content: Text(
          'Are you sure you want to delete this special moment?',
          style: AppTypography.lato400(13, t.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppTypography.lato700(13, t.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: AppTypography.lato700(13, Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteMemory(
        token: widget.user.token ?? '',
        memoryId: id,
      );

      if (mounted) {
        setState(() {
          _memories.removeWhere((m) => m.id == id);
        });
      }
    } catch (e) {
      debugPrint('[DELETE MEMORY ERROR] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete moment: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Moments', style: AppTypography.playfair(22, t.text)),
              SolidButton(
                onTap: () => setState(() {
                  _adding = !_adding;
                  if (!_adding) {
                    _newTitle = '';
                    _newBody = '';
                  }
                }),
                icon: _adding
                    ? AppIcons.close(c: Colors.white, s: 14)
                    : AppIcons.plus(c: Colors.white, s: 16),
                size: 36,
                color: _adding ? t.border : t.accent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Composer
          if (_adding) _buildComposer(),
          // Spinner
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black26),
                  ),
                ),
              ),
            )
          else ...[
            // Memory cards
            ..._memories.map((m) => _buildMemoryCard(m)),
            if (_memories.isEmpty && !_adding)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      AppIcons.memories(c: t.border, s: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Your moments will live here.',
                        style: AppTypography.cormorantItalic(17, t.muted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildComposer() {
    final canSave = _newTitle.trim().isNotEmpty && _newBody.trim().isNotEmpty;
    return AppCard(
      t: t,
      child: Column(
        children: [
          // Title Input
          VoiceTextInput(
            value: _newTitle,
            onChange: (v) => setState(() => _newTitle = v),
            placeholder: 'Give this moment a title…',
            t: t,
            style: AppTypography.playfair(18, t.text),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 12),
          // Caption/Body Input
          VoiceTextArea(
            value: _newBody,
            onChange: (v) => setState(() => _newBody = v),
            placeholder: 'What happened? Write details…',
            t: t,
            rows: 3,
            micSize: 32,
          ),
          const SizedBox(height: 12),
          // Save button
          GestureDetector(
            onTap: canSave && !_saving ? _saveMemory : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: canSave && !_saving ? t.accent : t.border,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Save Moment',
                        style: AppTypography.lato700(
                          14,
                          canSave ? Colors.white : t.muted,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionsMenu(_Memory m) {
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
              child: Text(
                m.title,
                style: AppTypography.playfair(16, t.text),
              ),
            ),
            const Divider(),
            ListTile(
              leading: AppIcons.pen(c: t.accent, s: 18),
              title: Text('Edit Moment', style: AppTypography.lato700(14, t.text)),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _editingId = m.id;
                  _editTitle = m.title;
                  _editBody = m.body;
                });
              },
            ),
            ListTile(
              leading: AppIcons.close(c: Colors.redAccent, s: 18),
              title: Text('Delete Moment', style: AppTypography.lato700(14, Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                _deleteMemory(m.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryCard(_Memory m) {
    if (_editingId == m.id) {
      final canUpdate = _editTitle.trim().isNotEmpty && _editBody.trim().isNotEmpty;
      return AppCard(
        t: t,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Moment',
              style: AppTypography.playfair(16, t.accent),
            ),
            const SizedBox(height: 12),
            VoiceTextInput(
              value: _editTitle,
              onChange: (v) => setState(() => _editTitle = v),
              placeholder: 'Give this moment a title…',
              t: t,
              style: AppTypography.playfair(18, t.text),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 12),
            VoiceTextArea(
              value: _editBody,
              onChange: (v) => setState(() => _editBody = v),
              placeholder: 'What happened? Write details…',
              t: t,
              rows: 3,
              micSize: 32,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => setState(() => _editingId = null),
                  child: Text('Cancel', style: AppTypography.lato700(12, t.muted)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canUpdate && !_saving ? t.accent : t.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: canUpdate && !_saving ? () => _updateMemory(m.id) : null,
                  child: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Save', style: AppTypography.lato700(12, Colors.white)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final Color accentColor = m.color;

    return GestureDetector(
      onLongPress: () => _showActionsMenu(m),
      onTap: () => _showActionsMenu(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.border),
          boxShadow: t.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                Container(
                  width: 5,
                  color: accentColor,
                ),
                // Text content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          m.title,
                          style: AppTypography.playfair(18, t.text),
                        ),
                        if (m.body.isNotEmpty && m.body != m.title) ...[
                          const SizedBox(height: 6),
                          // Body text
                          Text(
                            m.body,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: t.text,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Small horizontal divider matching accent color
                        Container(
                          width: 25,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Memory {
  final String id;
  String title;
  String body;
  final Color color;
  final DateTime date;
  _Memory({
    required this.id,
    required this.title,
    required this.body,
    required this.color,
    required this.date,
  });
}
