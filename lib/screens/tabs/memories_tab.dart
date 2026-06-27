import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/tokens.dart';
import '../../icons/app_icons.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/voice_text_input.dart';

class MemoriesTab extends StatefulWidget {
  final AppTokens t;
  const MemoriesTab({super.key, required this.t});

  @override
  State<MemoriesTab> createState() => _MemoriesTabState();
}

class _MemoriesTabState extends State<MemoriesTab> {
  final List<_Memory> _memories = [];
  bool _adding = false;
  String _caption = '';
  Uint8List? _photo;
  final _palette = [
    const Color(0xFFB8706A),
    const Color(0xFFC4945A),
    const Color(0xFF7A9E8E),
    const Color(0xFF9E9E7A),
    const Color(0xFFA0887A),
  ];

  AppTokens get t => widget.t;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _photo = bytes);
    }
  }

  void _save() {
    if (_photo == null && _caption.trim().isEmpty) return;
    setState(() {
      _memories.insert(
        0,
        _Memory(
          photo: _photo,
          caption: _caption.trim(),
          color: _palette[Random().nextInt(_palette.length)],
          date: DateTime.now(),
        ),
      );
      _adding = false;
      _caption = '';
      _photo = null;
    });
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
                onTap:
                    () => setState(() {
                      _adding = !_adding;
                      if (!_adding) {
                        _caption = '';
                        _photo = null;
                      }
                    }),
                icon:
                    _adding
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
      ),
    );
  }

  Widget _buildComposer() {
    return AppCard(
      t: t,
      child: Column(
        children: [
          // Photo area
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: _photo != null ? 200 : 110,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: t.bg,
                border: Border.all(color: t.border),
              ),
              child:
                  _photo != null
                      ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _photo!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => setState(() => _photo = null),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.45),
                                ),
                                child: AppIcons.close(c: Colors.white, s: 12),
                              ),
                            ),
                          ),
                        ],
                      )
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: 0.5,
                              child: AppIcons.camera(c: t.muted, s: 28),
                            ),
                            const SizedBox(height: 6),
                            Opacity(
                              opacity: 0.5,
                              child: Text(
                                'Add a photo',
                                style: AppTypography.lato400(13, t.muted),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 12),
          // Caption
          VoiceTextArea(
            value: _caption,
            onChange: (v) => setState(() => _caption = v),
            placeholder: 'Write a caption…',
            t: t,
            rows: 3,
            micSize: 32,
          ),
          const SizedBox(height: 12),
          // Save button
          GestureDetector(
            onTap: _save,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color:
                    (_photo != null || _caption.trim().isNotEmpty)
                        ? t.accent
                        : t.border,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'Save Moment',
                  style: AppTypography.lato700(
                    14,
                    (_photo != null || _caption.trim().isNotEmpty)
                        ? Colors.white
                        : t.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(_Memory m) {
    return AppCard(
      t: t,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (m.photo != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.memory(
                m.photo!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 180,
              ),
            ),
          if (m.caption.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: m.color, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.caption,
                    style: AppTypography.cormorantItalic(
                      17,
                      t.text,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 18,
                    height: 2,
                    color: m.color.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Memory {
  final Uint8List? photo;
  final String caption;
  final Color color;
  final DateTime date;
  _Memory({
    this.photo,
    required this.caption,
    required this.color,
    required this.date,
  });
}
