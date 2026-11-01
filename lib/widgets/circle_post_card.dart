import 'package:flutter/material.dart';
import '../models/circle_response.dart';
import '../theme/tokens.dart';
import 'shared_widgets.dart';

enum _ResponsePanel { feelings, reply }

/// Post card for the circle.
///
/// Feelings are grouped under the post. The latest [commentsPageSize]
/// comments (10) are shown. Load more reveals the previous 10.
/// The API returns every comment, so paging stays on this card.
/// Respond with feeling and Respond are separate panels. A person can
/// leave each feeling once; chips they already sent start selected.
class CirclePostCard extends StatefulWidget {
  static const commentsPageSize = 10;
  static const visibleFeelingGroups = 4;

  final AppTokens t;
  final String author;
  final String body;
  final String time;
  final List<CircleReply> replies;
  final List<CircleMood> moods;
  final List<CircleFeelingCount> feelings;
  final List<String> myMoods;
  final String? myMood;
  final int? mamaCount;
  final Future<dynamic> Function(CircleResponseDraft)? onSendReply;

  const CirclePostCard({
    super.key,
    required this.t,
    required this.author,
    required this.body,
    required this.time,
    this.replies = const [],
    this.moods = const [],
    this.feelings = const [],
    this.myMoods = const [],
    this.myMood,
    this.mamaCount,
    this.onSendReply,
  });

  @override
  State<CirclePostCard> createState() => _CirclePostCardState();
}

class _CirclePostCardState extends State<CirclePostCard> {
  static const _defaultFeelings = {
    'holding_you': 'Holding you',
    'i_understand': 'I understand',
    'this_feels_heavy': 'This feels heavy',
    'youre_doing_okay': "You're doing okay",
    'im_here': "I'm here",
    'this_will_pass': 'This will pass',
    'take_a_breath': 'Take a breath',
  };

  Map<String, String> get _feelingLabels {
    if (widget.moods.isNotEmpty) {
      return {for (final mood in widget.moods) mood.key: mood.label};
    }
    return _defaultFeelings;
  }

  final _draft = TextEditingController();
  final Set<String> _selectedKeys = {};
  final Map<String, int> _localFeelingAdds = {};
  _ResponsePanel? _panel;
  bool _sending = false;
  bool _feelingsExpanded = false;
  int _commentPages = 1;
  String? _error;

  AppTokens get t => widget.t;

  @override
  void initState() {
    super.initState();
    _syncSelectionFromWidget();
  }

  @override
  void didUpdateWidget(CirclePostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectionFromWidget();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _syncSelectionFromWidget() {
    if (widget.myMoods.isEmpty && (widget.myMood == null || widget.myMood!.isEmpty)) {
      return;
    }
    _selectedKeys
      ..clear()
      ..addAll(widget.myMoods);
    if (widget.myMood != null && widget.myMood!.isNotEmpty) {
      _selectedKeys.add(widget.myMood!);
    }
  }

  void _togglePanel(_ResponsePanel panel) {
    setState(() {
      _panel = _panel == panel ? null : panel;
      _error = null;
    });
  }

  String? _keyForLabel(String? label) {
    if (label == null) return null;
    for (final entry in _feelingLabels.entries) {
      if (entry.value == label) return entry.key;
    }
    return null;
  }

  List<CircleFeelingCount> get _feelingGroups {
    final grouped = <String, CircleFeelingCount>{
      for (final feeling in widget.feelings) feeling.key: feeling,
    };
    if (widget.onSendReply == null) {
      for (final entry in _localFeelingAdds.entries) {
        final existing = grouped[entry.key];
        grouped[entry.key] = CircleFeelingCount(
          key: entry.key,
          label: existing?.label ?? _feelingLabels[entry.key] ?? entry.key,
          count: (existing?.count ?? 0) + entry.value,
        );
      }
    }
    final feelings = grouped.values.toList();
    feelings.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return a.label.compareTo(b.label);
    });
    return feelings;
  }

  int get _mamaCount {
    final localPerson = widget.onSendReply == null && _localFeelingAdds.isNotEmpty;
    if (widget.mamaCount != null) {
      final alreadyCounted = widget.myMoods.isNotEmpty ||
          (widget.myMood != null && widget.myMood!.isNotEmpty);
      return widget.mamaCount! + (localPerson && !alreadyCounted ? 1 : 0);
    }
    if (widget.feelings.isNotEmpty) {
      final total = widget.feelings.fold<int>(0, (sum, feeling) => sum + feeling.count);
      return total + (localPerson ? 1 : 0);
    }
    return localPerson ? 1 : 0;
  }

  String? get _presenceLine {
    final feelings = _feelingGroups;
    if (feelings.isEmpty || _mamaCount <= 0) return null;
    final verb = _mamaCount == 1 ? 'mama is' : 'mamas are';
    final top = feelings.take(2).map((feeling) => feeling.label.toLowerCase()).toList();
    final mostly = top.length == 1 ? top.first : '${top[0]} and ${top[1]}';
    return '$_mamaCount $verb here with you — mostly $mostly.';
  }

  List<CircleReply> get _visibleComments {
    final all = widget.replies;
    final window = _commentPages * CirclePostCard.commentsPageSize;
    if (all.length <= window) return all;
    return all.sublist(all.length - window);
  }

  bool get _hasMoreComments =>
      widget.replies.length > _commentPages * CirclePostCard.commentsPageSize;

  Future<void> _send({String? feeling}) async {
    final text = feeling ?? _draft.text.trim();
    if (text.isEmpty || _sending) return;

    final feelingKey = _keyForLabel(feeling);
    if (feelingKey != null && _selectedKeys.contains(feelingKey)) return;

    final sendReply = widget.onSendReply;
    if (sendReply == null) {
      if (feelingKey == null) return;
      setState(() {
        _error = null;
        _selectedKeys.add(feelingKey);
        _localFeelingAdds[feelingKey] = (_localFeelingAdds[feelingKey] ?? 0) + 1;
      });
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await sendReply(CircleResponseDraft(body: text, feelingKey: feelingKey));
      if (!mounted) return;
      setState(() {
        if (feelingKey != null) {
          _selectedKeys.add(feelingKey);
        } else {
          _draft.clear();
          _panel = null;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Your response could not be sent. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feelings = _feelingGroups;
    final comments = _visibleComments;
    final presence = _presenceLine;
    final shownFeelings = _feelingsExpanded || feelings.length <= CirclePostCard.visibleFeelingGroups
        ? feelings
        : feelings.sublist(0, CirclePostCard.visibleFeelingGroups);
    final hiddenFeelings = feelings.length - shownFeelings.length;

    return AppCard(
      t: t,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(widget.author, style: AppTypography.lato700(13, t.accent)),
              ),
              const SizedBox(width: 12),
              Text(widget.time, style: AppTypography.lato400(12, t.muted)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.body,
            style: AppTypography.cormorantItalic(18, t.text, height: 1.7),
          ),
          if (presence != null || comments.isNotEmpty) ...[
            _divider(),
            if (presence != null) ...[
              Text(
                presence,
                style: AppTypography.cormorantItalic(16, t.muted, height: 1.45),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final feeling in shownFeelings) _countPill(feeling),
                  if (hiddenFeelings > 0)
                    _moreFeelingsPill(hiddenFeelings),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_hasMoreComments)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _commentPages += 1),
                  style: TextButton.styleFrom(
                    foregroundColor: t.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Load more', style: AppTypography.lato700(13, t.accent)),
                ),
              ),
            for (final reply in comments) ...[
              _comment(reply),
              const SizedBox(height: 14),
            ],
          ],
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttons = [
                _panelButton('Respond with feeling', _ResponsePanel.feelings, t.accent),
                _panelButton('Respond', _ResponsePanel.reply, t.text),
              ];
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              if (constraints.maxWidth < 260 || textScale > 1.2) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [buttons[0], const SizedBox(height: 8), buttons[1]],
                );
              }
              return Row(
                children: [
                  Expanded(child: buttons[0]),
                  const SizedBox(width: 8),
                  Expanded(child: buttons[1]),
                ],
              );
            },
          ),
          if (_panel != null) ...[
            _divider(),
            if (_panel == _ResponsePanel.feelings) ...[
              Text(
                'SEND A FEELING…',
                style: AppTypography.lato400(10, t.muted).copyWith(letterSpacing: 1.3),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _feelingLabels.entries) _feelingChip(entry.key, entry.value),
                ],
              ),
              const SizedBox(height: 14),
              _replyField(hint: 'Or write a gentle response…'),
            ],
            if (_panel == _ResponsePanel.reply)
              _replyField(hint: 'Write a gentle response…'),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: AppTypography.lato400(12, t.accent)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Divider(height: 1, color: t.border),
  );

  Widget _countPill(CircleFeelingCount feeling) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              feeling.label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.lato700(13, t.text),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text('${feeling.count}', style: AppTypography.lato700(11, t.accent)),
          ),
        ],
      ),
    );
  }

  Widget _moreFeelingsPill(int hidden) {
    return GestureDetector(
      onTap: () => setState(() => _feelingsExpanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: t.border),
        ),
        child: Text('+$hidden more', style: AppTypography.lato700(13, t.muted)),
      ),
    );
  }

  Widget _comment(CircleReply reply) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reply.author, style: AppTypography.lato700(13, t.accent)),
              const SizedBox(height: 2),
              Text(
                reply.body,
                style: AppTypography.cormorantItalic(17, t.text, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panelButton(String label, _ResponsePanel panel, Color color) {
    final active = _panel == panel;
    return OutlinedButton(
      onPressed: _sending ? null : () => _togglePanel(panel),
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? Colors.white : color,
        backgroundColor: active ? t.accent : Colors.transparent,
        side: BorderSide(color: active ? t.accent : t.border, width: 1.4),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        textStyle: AppTypography.lato700(12, color),
      ),
      child: Text(active ? 'Close' : label, textAlign: TextAlign.center),
    );
  }

  Widget _feelingChip(String key, String feeling) {
    final selected = _selectedKeys.contains(key);
    return ChoiceChip(
      label: Text(feeling),
      selected: selected,
      onSelected: _sending
          ? null
          : (_) {
              _send(feeling: feeling);
            },
      showCheckmark: false,
      labelStyle: AppTypography.lato700(12, selected ? t.accent : t.text),
      backgroundColor: t.bg,
      selectedColor: t.accent.withValues(alpha: 0.10),
      side: BorderSide(color: selected ? t.accent : t.border, width: 1.2),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _replyField({required String hint}) {
    final canSend = widget.onSendReply != null && _draft.text.trim().isNotEmpty && !_sending;
    final input = TextField(
      controller: _draft,
      enabled: !_sending,
      minLines: 1,
      maxLines: 4,
      onChanged: (_) => setState(() => _error = null),
      style: AppTypography.cormorantItalic(17, t.text, height: 1.4),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.cormorantItalic(16, t.muted.withValues(alpha: 0.7)),
        filled: true,
        fillColor: t.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: t.accent),
        ),
      ),
    );
    final send = FilledButton(
      onPressed: canSend ? () => _send() : null,
      style: FilledButton.styleFrom(
        backgroundColor: t.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: t.border,
        disabledForegroundColor: t.muted,
        minimumSize: const Size(64, 44),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: _sending
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(
              'Send',
              style: AppTypography.lato700(12, canSend ? Colors.white : t.muted),
            ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 260 || MediaQuery.textScalerOf(context).scale(1) > 1.4) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [input, const SizedBox(height: 8), send],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [Expanded(child: input), const SizedBox(width: 8), send],
        );
      },
    );
  }
}
