import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/tokens.dart';
import '../../icons/app_icons.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/voice_text_input.dart';

class MeTab extends StatefulWidget {
  final UserProfile user;
  final AppTokens t;
  final Function(UserProfile) onUpdateUser;
  final VoidCallback onLogout;

  const MeTab({
    super.key,
    required this.user,
    required this.t,
    required this.onUpdateUser,
    required this.onLogout,
  });

  @override
  State<MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<MeTab> {
  bool _editing = false;
  String? _activeLetter; // null | 'pre' | 'future'
  final Map<String, String> _letters = {'pre': '', 'future': ''};
  Timer? _letterSaveTimer;
  bool _letterSaved = false; // briefly shows "Saved" indicator

  // Editable profile copy
  late String _name;
  late List<String> _phases;
  late int _childCount;
  late List<String> _journey;
  late List<String> _hardships;
  late String _bio;
  Uint8List? _photo;
  bool _saving = false;

  AppTokens get t => widget.t;

  @override
  void initState() {
    super.initState();
    _syncFromUser();
    _fetchProfileFromServer();
  }

  void _fetchProfileFromServer() async {
    final token = widget.user.token;
    if (token == null || token.isEmpty) return;

    try {
      final json = await ApiService.getProfile(token: token);
      final profile = UserProfile.fromJson({...json, 'token': token});
      // Preserve local photo
      final completed = profile.copyWith(photo: widget.user.photo);
      if (mounted) {
        widget.onUpdateUser(completed);
      }
    } catch (e) {
      debugPrint('[ME TAB FETCH ERROR] $e');
    }
  }

  @override
  void didUpdateWidget(covariant MeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) _syncFromUser();
  }

  void _syncFromUser() {
    _name = widget.user.name;
    _phases = List.from(widget.user.phases);
    _childCount = widget.user.childCount;
    _journey = List.from(widget.user.journey);
    _hardships = List.from(widget.user.hardships);
    _bio = widget.user.bio;
    _photo = widget.user.photo;
    _letters['pre'] = widget.user.preBabyLetter;
    _letters['future'] = widget.user.futureSelfLetter;
  }

  @override
  void dispose() {
    _letterSaveTimer?.cancel();
    super.dispose();
  }

  void _scheduleSave() {
    _letterSaveTimer?.cancel();
    _letterSaveTimer = Timer(const Duration(milliseconds: 1500), _saveLetter);
  }

  void _confirmDeleteAccount() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: widget.t.card,
        title: Text(
          'Delete My Account',
          style: AppTypography.playfair(18, const Color(0xFFD9534F)),
        ),
        content: Text(
          'This will permanently delete your account and everything in it — your daily pages, journal, tasks, cycle data, circle posts, and letters.\n\nThis cannot be undone.',
          style: AppTypography.lato400(14, widget.t.text, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppTypography.lato700(14, widget.t.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete Everything',
              style: AppTypography.lato700(14, const Color(0xFFD9534F)),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;
      final token = widget.user.token ?? '';
      final success = await ApiService.deleteAccount(token: token);
      if (!mounted) return;
      if (success) {
        widget.onLogout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete account. Please try again.'),
            backgroundColor: Color(0xFFD9534F),
          ),
        );
      }
    });
  }

  void _saveLetter() {
    _letterSaveTimer?.cancel();
    final token = widget.user.token;
    if (token == null || token.isEmpty || _activeLetter == null) return;
    final key = _activeLetter!;
    final text = _letters[key] ?? '';
    ApiService.updateProfile(
      token: token,
      profileParams: {
        if (key == 'pre') 'pre_baby_letter': text,
        if (key == 'future') 'future_self_letter': text,
      },
    ).then((json) {
      final updated = UserProfile.fromJson({...json, 'token': token});
      if (mounted) {
        widget.onUpdateUser(updated.copyWith(photo: _photo));
        setState(() => _letterSaved = true);
        Future.delayed(const Duration(seconds: 2),
            () { if (mounted) setState(() => _letterSaved = false); });
      }
    }).catchError((e) {
      debugPrint('[LETTER SAVE ERROR] $e');
    });
  }

  void _save() async {
    final token = widget.user.token;
    if (token == null || token.isEmpty) return;

    setState(() {
      _saving = true;
    });

    // Map human readable hardships back to snake_case for API
    final apiHardships = _hardships.map((h) => hardshipToApi[h] ?? h).toList();

    // Map human readable journey back to snake_case for API
    final apiJourney = _journey.map((j) => journeyToApi[j] ?? j).toList();

    // Determine primary phase / journey stage
    final String phase = _phases.isNotEmpty ? _phases.first : 'expecting';

    final pregnancyWeek = widget.user.pregnancyMonth?.replaceAll(' weeks', '');

    final Map<String, dynamic> profileParams = {
      'name': _name.trim(),
      'display_name': _name.trim(),
      'bio': _bio.trim(),
      'child_count': _childCount,
      'pregnancy_week': pregnancyWeek,
      'journey_stage': phase,
      'primary_phase': phase,
      'hardships': apiHardships,
      'hardships_text': widget.user.hardshipsText,
      'journey_tags': apiJourney,
      'journey_text': _bio.trim(),
      'free_text': widget.user.hardshipsText,
      'pre_baby_letter': _letters['pre'] ?? '',
      'future_self_letter': _letters['future'] ?? '',
    };

    try {
      final json = await ApiService.updateProfile(
        token: token,
        profileParams: profileParams,
      );

      final updatedProfile = UserProfile.fromJson({...json, 'token': token});

      // Also preserve local photo
      final completedProfile = updatedProfile.copyWith(photo: _photo);

      if (mounted) {
        widget.onUpdateUser(completedProfile);
        setState(() {
          _editing = false;
        });
      }
    } catch (e) {
      debugPrint('[ME TAB SAVE ERROR] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _photo = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeLetter != null) return _buildLetterEditor();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 14),
          _buildNameSection(),
          const SizedBox(height: 6),
          if (!_editing)
            Text(
              widget.user.phaseLabel,
              style: AppTypography.lato400(12, t.muted),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),
          _buildEditControls(),
          const SizedBox(height: 20),
          _buildAboutMe(),
          _buildChipSection(
            'Motherhood Phases',
            [
              'expecting',
              'newborn',
              'baby',
              'toddler',
              'preschool',
              'school_age',
            ],
            [
              'Expecting',
              'Newborn (0-6m)',
              'Baby (6-18m)',
              'Toddler (18m-3y)',
              'Preschool (3-5y)',
              'School Age (5+)',
            ],
            t.accent,
            _phases,
            (v) => setState(() {
              if (_phases.contains(v)) {
                _phases.remove(v);
              } else {
                _phases.add(v);
              }
            }),
          ),
          if (_editing) _buildChildCount(),
          if (!_editing && _childCount > 0)
            _sectionView(
              'Number of Children',
              '$_childCount ${_childCount == 1 ? 'child' : 'children'}',
            ),
          _buildChipSection(
            'My Journey',
            [
              'First-time mother',
              'Second-time mother',
              'Third time (or more)',
              'Single mother',
              'Single father',
              'Co-parenting',
              'Working mother',
              'Stay-at-home mother',
              'IVF / fertility journey',
              'Loss and healing',
              'Adoptive parent',
              'Neurodivergent child',
              'Postpartum recovery',
              'Blended family',
            ],
            null,
            t.gold,
            _journey,
            (v) => setState(() {
              if (_journey.contains(v)) {
                _journey.remove(v);
              } else {
                _journey.add(v);
              }
            }),
          ),
          _buildChipSection(
            'What Feels Hardest',
            [
              'Overwhelm',
              'Loneliness',
              'Sleep exhaustion',
              'Burnout',
              'Mom guilt',
              'Identity loss',
              'Mental load',
              'Need calm',
              'Finding time for myself',
            ],
            null,
            t.green,
            _hardships,
            (v) => setState(() {
              if (_hardships.contains(v)) {
                _hardships.remove(v);
              } else {
                _hardships.add(v);
              }
            }),
          ),
          const SizedBox(height: 24),
          // Private Letters
          Text('PRIVATE LETTERS', style: AppTypography.sectionLabel(t.muted)),
          const SizedBox(height: 12),
          _buildLetterCard(
            'A Letter to My Pre-Baby Self',
            AppIcons.leaf(c: t.green, s: 20),
            t.green,
            'pre',
          ),
          _buildLetterCard(
            'A Letter to My Future Self',
            AppIcons.bloom(c: t.accent, s: 20),
            t.accent,
            'future',
          ),
          if (!_editing) ...[
            const SizedBox(height: 32),
            // Log out
            GestureDetector(
              onTap: widget.onLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.accent.withValues(alpha: 0.4)),
                  color: t.accent.withValues(alpha: 0.05),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: t.accent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Log Out of Sanctuary',
                      style: AppTypography.lato700(13, t.accent),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Delete account
            GestureDetector(
              onTap: _confirmDeleteAccount,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD9534F).withValues(alpha: 0.4)),
                  color: const Color(0xFFD9534F).withValues(alpha: 0.05),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_forever_rounded,
                        color: const Color(0xFFD9534F), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Delete My Account',
                      style: AppTypography.lato700(13, const Color(0xFFD9534F)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _editing ? _pickPhoto : null,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: t.border, width: 3),
              gradient:
                  _photo == null
                      ? LinearGradient(
                        colors: [
                          t.accent.withValues(alpha: 0.4),
                          t.gold.withValues(alpha: 0.4),
                        ],
                      )
                      : null,
            ),
            child: ClipOval(
              child:
                  _photo != null
                      ? Image.memory(
                        _photo!,
                        fit: BoxFit.cover,
                        width: 96,
                        height: 96,
                      )
                      : Center(child: AppIcons.me(c: t.accent, s: 42)),
            ),
          ),
          if (_editing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.accent,
                ),
                child: Center(child: AppIcons.camera(c: Colors.white, s: 14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNameSection() {
    if (_editing) {
      return SizedBox(
        width: 220,
        child: TextField(
          onChanged: (v) => setState(() => _name = v),
          controller: TextEditingController(text: _name)
            ..selection = TextSelection.collapsed(offset: _name.length),
          textAlign: TextAlign.center,
          style: AppTypography.playfair(22, t.text),
          decoration: InputDecoration(
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: t.accent, width: 2),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: t.accent, width: 2),
            ),
          ),
        ),
      );
    }
    return Text(
      widget.user.name,
      style: AppTypography.playfair(24, t.text),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEditControls() {
    if (_editing) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _saving ? t.accent.withValues(alpha: 0.5) : t.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : AppIcons.check(c: Colors.white, s: 16),
                    const SizedBox(width: 8),
                    Text(
                      _saving ? 'Saving...' : 'Save Profile',
                      style: AppTypography.lato700(14, Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _saving
                ? null
                : () {
                    _syncFromUser();
                    setState(() => _editing = false);
                  },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.border),
              ),
              child: Center(child: AppIcons.close(c: t.muted, s: 16)),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _editing = true),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcons.pen(c: t.accent, s: 16),
            const SizedBox(width: 8),
            Text('Edit My Profile', style: AppTypography.lato700(14, t.accent)),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutMe() {
    return _sectionWrapper(
      'About Me',
      _editing
          ? VoiceTextArea(
            value: _bio,
            onChange: (v) => setState(() => _bio = v),
            placeholder: 'Tell Chamomile about you…',
            t: t,
            rows: 3,
            micSize: 34,
          )
          : Text(
            _bio.isEmpty ? 'Not shared yet.' : _bio,
            style: AppTypography.cormorantItalic(
              16,
              _bio.isEmpty ? t.muted : t.text,
              height: 1.6,
            ),
          ),
    );
  }

  Widget _buildChipSection(
    String title,
    List<String> allOptions,
    List<String>? displayLabels,
    Color color,
    List<String> selected,
    Function(String) onToggle,
  ) {
    if (_editing) {
      return _sectionWrapper(
        title,
        Wrap(
          children:
              allOptions.asMap().entries.map((e) {
                final val = e.value;
                final label = displayLabels?[e.key] ?? val;
                final id =
                    displayLabels != null
                        ? val.split(' ')[0].toLowerCase()
                        : val;
                final sel = selected.contains(id);
                return ChipButton(
                  label: label,
                  selected: sel,
                  onTap: () => onToggle(id),
                  color: color,
                  t: t,
                );
              }).toList(),
        ),
      );
    }
    // View mode
    if (selected.isEmpty) {
      return _sectionView(title, 'Not specified yet.');
    }
    return _sectionWrapper(
      title,
      Wrap(
        children:
            selected.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(right: 6, bottom: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(s, style: AppTypography.lato400(12, color)),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildChildCount() {
    return _sectionWrapper(
      'Number of Children',
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepperBtn('−', () {
            if (_childCount > 0) setState(() => _childCount--);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$_childCount',
              style: AppTypography.playfair(30, t.text),
            ),
          ),
          _stepperBtn('+', () => setState(() => _childCount++)),
        ],
      ),
    );
  }

  Widget _stepperBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: t.border, width: 1.5),
          color: t.card,
        ),
        child: Center(
          child: Text(label, style: AppTypography.lato700(18, t.text)),
        ),
      ),
    );
  }

  Widget _sectionWrapper(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: AppTypography.sectionLabel(t.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _sectionView(String title, String text) {
    return _sectionWrapper(
      title,
      Text(
        text,
        style: AppTypography.cormorantItalic(16, t.muted, height: 1.5),
      ),
    );
  }

  Widget _buildLetterCard(String title, Widget icon, Color color, String key) {
    final hasWritten = _letters[key]!.isNotEmpty;
    return GestureDetector(
      onTap: () => setState(() => _activeLetter = key),
      child: AppCard(
        t: t,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: color.withValues(alpha: 0.18),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.playfair(15, t.text)),
                  const SizedBox(height: 2),
                  Text(
                    hasWritten ? 'Written ✦' : 'Private. Just for you.',
                    style: AppTypography.lato400(11, t.muted),
                  ),
                ],
              ),
            ),
            AppIcons.chevRight(c: t.muted, s: 16),
          ],
        ),
      ),
    );
  }

  // ─── Letter Editor ───────────────────────────────
  Widget _buildLetterEditor() {
    final isPreBaby = _activeLetter == 'pre';
    final title =
        isPreBaby
            ? 'A Letter to My Pre-Baby Self'
            : 'A Letter to My Future Self';
    final subtitle =
        isPreBaby
            ? 'What would you tell yourself before everything changed?'
            : 'What do you want to remember when this season passes?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              _letterSaveTimer?.cancel();
              setState(() => _activeLetter = null);
            },
            child: Row(
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14159),
                  child: AppIcons.chevRight(c: t.accent, s: 16),
                ),
                const SizedBox(width: 6),
                Text('Back', style: AppTypography.lato400(14, t.accent)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.playfair(20, t.text)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTypography.cormorantItalic(15, t.muted)),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: _letterSaved ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 12, color: t.green),
                    const SizedBox(width: 4),
                    Text('Saved', style: AppTypography.lato400(11, t.green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: VoiceTextArea(
              value: _letters[_activeLetter!]!,
              onChange: (v) {
                setState(() => _letters[_activeLetter!] = v);
                _scheduleSave();
              },
              placeholder: 'Dear me…',
              t: t,
              rows: 14,
            ),
          ),
        ],
      ),
    );
  }
}
