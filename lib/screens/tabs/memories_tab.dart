import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/tokens.dart';
import '../../icons/app_icons.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/voice_text_input.dart';

class MemoriesTab extends StatefulWidget {
  final UserProfile user;
  final AppTokens t;
  const MemoriesTab({super.key, required this.user, required this.t});

  @override
  State<MemoriesTab> createState() => _MemoriesTabState();
}

class _MemoriesTabState extends State<MemoriesTab> {
  final List<_Memory> _memories = [];
  bool _loading = false;
  bool _adding = false;
  bool _saving = false;

  // Composer state
  String _caption = '';
  XFile? _pickedImage;

  // Edit state
  String? _editingId;
  String _editCaption = '';
  XFile? _editPickedImage;

  final _picker = ImagePicker();

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
    setState(() => _loading = true);
    try {
      final list = await ApiService.getMemories(token: widget.user.token ?? '');
      final loaded = list.map((item) {
        DateTime date = DateTime.now();
        try {
          date = DateTime.parse(item['created_at']?.toString() ?? '');
        } catch (_) {}
        return _Memory(
          id: item['id'].toString(),
          caption: item['description']?.toString() ?? item['title']?.toString() ?? '',
          photoUrl: item['photo_url']?.toString(),
          color: _palette[Random().nextInt(_palette.length)],
          date: date,
        );
      }).toList();
      if (mounted) {
        setState(() {
          _memories
            ..clear()
            ..addAll(loaded);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[LOAD MEMORIES ERROR] $e');
      if (mounted) {
        setState(() => _loading = false);
        _showError('Failed to load moments: $e');
      }
    }
  }

  Future<void> _pickImage({bool forEdit = false}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() {
        if (forEdit) {
          _editPickedImage = picked;
        } else {
          _pickedImage = picked;
        }
      });
    }
  }

  void _saveMemory() async {
    if (_caption.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final res = await ApiService.createMemory(
        token: widget.user.token ?? '',
        title: _caption.trim(),
        description: _caption.trim(),
        imagePath: _pickedImage?.path,
      );
      final newMemory = _Memory(
        id: res['id']?.toString() ?? '0',
        caption: res['description']?.toString() ?? res['title']?.toString() ?? _caption.trim(),
        photoUrl: res['photo_url']?.toString(),
        color: _palette[Random().nextInt(_palette.length)],
        date: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _memories.insert(0, newMemory);
          _adding = false;
          _caption = '';
          _pickedImage = null;
          _saving = false;
        });
      }
    } catch (e) {
      debugPrint('[CREATE MEMORY ERROR] $e');
      if (mounted) {
        setState(() => _saving = false);
        _showError('Failed to save moment: $e');
      }
    }
  }

  void _updateMemory(String id) async {
    if (_editCaption.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final res = await ApiService.updateMemory(
        token: widget.user.token ?? '',
        memoryId: id,
        title: _editCaption.trim(),
        description: _editCaption.trim(),
        imagePath: _editPickedImage?.path,
      );
      if (mounted) {
        setState(() {
          final idx = _memories.indexWhere((m) => m.id == id);
          if (idx != -1) {
            _memories[idx].caption = _editCaption.trim();
            final newUrl = res['photo_url']?.toString();
            if (newUrl != null) _memories[idx].photoUrl = newUrl;
          }
          _editingId = null;
          _editCaption = '';
          _editPickedImage = null;
          _saving = false;
        });
      }
    } catch (e) {
      debugPrint('[UPDATE MEMORY ERROR] $e');
      if (mounted) {
        setState(() => _saving = false);
        _showError('Failed to update moment: $e');
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
            child: Text('Delete', style: AppTypography.lato700(13, Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteMemory(token: widget.user.token ?? '', memoryId: id);
      if (mounted) setState(() => _memories.removeWhere((m) => m.id == id));
    } catch (e) {
      if (mounted) _showError('Failed to delete moment: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
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
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: t.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: AppIcons.pen(c: t.accent, s: 18),
              title: Text('Edit Moment', style: AppTypography.lato700(14, t.text)),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _editingId = m.id;
                  _editCaption = m.caption;
                  _editPickedImage = null;
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
              if (!_adding)
                GestureDetector(
                  onTap: () => setState(() => _adding = true),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: AppIcons.plus(c: Colors.white, s: 16)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Composer
          if (_adding) _buildComposer(),

          // Spinner or list
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

  // ─── Composer card ──────────────────────────────────────────────────────────

  Widget _buildComposer() {
    final canSave = _caption.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        children: [
          // Photo picker area
          GestureDetector(
            onTap: () => _pickImage(),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: _pickedImage != null
                  ? Stack(
                      children: [
                        Image.file(
                          File(_pickedImage!.path),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _pickedImage = null),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      width: double.infinity,
                      height: 160,
                      color: t.bg,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 36, color: t.muted),
                          const SizedBox(height: 8),
                          Text('Add a photo', style: AppTypography.lato400(13, t.muted)),
                        ],
                      ),
                    ),
            ),
          ),

          // Caption input + action buttons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                VoiceTextArea(
                  value: _caption,
                  onChange: (v) => setState(() => _caption = v),
                  placeholder: 'Write a caption…',
                  t: t,
                  rows: 3,
                  micSize: 32,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: canSave && !_saving ? _saveMemory : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: canSave && !_saving
                                ? t.accent.withValues(alpha: 0.85)
                                : t.border,
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
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _saving
                          ? null
                          : () => setState(() {
                                _adding = false;
                                _caption = '';
                                _pickedImage = null;
                              }),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: t.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: t.border),
                        ),
                        child: Icon(Icons.close, color: t.muted, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Memory card ────────────────────────────────────────────────────────────

  Widget _buildMemoryCard(_Memory m) {
    if (_editingId == m.id) return _buildEditCard(m);

    final accentColor = m.color;
    return GestureDetector(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              if (m.photoUrl != null && m.photoUrl!.isNotEmpty)
                Image.network(
                  'http://139.59.23.15${m.photoUrl}',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),

              // Caption with left accent bar
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: accentColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.caption,
                              style: AppTypography.cormorantItalic(17, t.text, height: 1.5),
                            ),
                            const SizedBox(height: 10),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditCard(_Memory m) {
    final canUpdate = _editCaption.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickImage(forEdit: true),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: _editPickedImage != null
                  ? Stack(
                      children: [
                        Image.file(
                          File(_editPickedImage!.path),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _editPickedImage = null),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : m.photoUrl != null && m.photoUrl!.isNotEmpty
                      ? Stack(
                          children: [
                            Image.network(
                              'http://139.59.23.15${m.photoUrl}',
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _emptyPhotoBox(),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Change photo',
                                  style: AppTypography.lato400(11, Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _emptyPhotoBox(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                VoiceTextArea(
                  value: _editCaption,
                  onChange: (v) => setState(() => _editCaption = v),
                  placeholder: 'Write a caption…',
                  t: t,
                  rows: 3,
                  micSize: 32,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: canUpdate && !_saving ? () => _updateMemory(m.id) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: canUpdate && !_saving
                                ? t.accent.withValues(alpha: 0.85)
                                : t.border,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Save Moment',
                                    style: AppTypography.lato700(14, Colors.white),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() {
                        _editingId = null;
                        _editCaption = '';
                        _editPickedImage = null;
                      }),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: t.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: t.border),
                        ),
                        child: Icon(Icons.close, color: t.muted, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPhotoBox() {
    return Container(
      width: double.infinity,
      height: 130,
      color: t.bg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 30, color: t.muted),
          const SizedBox(height: 6),
          Text('Add a photo', style: AppTypography.lato400(12, t.muted)),
        ],
      ),
    );
  }
}

// ─── Data class ──────────────────────────────────────────────────────────────

class _Memory {
  final String id;
  String caption;
  String? photoUrl;
  final Color color;
  final DateTime date;

  _Memory({
    required this.id,
    required this.caption,
    this.photoUrl,
    required this.color,
    required this.date,
  });
}
