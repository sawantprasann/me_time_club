import 'package:flutter/material.dart';
import '../models/circle_response.dart';
import '../theme/tokens.dart';
import 'shared_widgets.dart';

enum _ResponsePanel { feelings, reply }

/// Post presentation and draft controls. Only a successful callback clears a reply.
class CirclePostCard extends StatefulWidget {
  final AppTokens t;
  final String author;
  final String body;
  final String time;
  final List<CircleReply> replies;
  final Future<void> Function(CircleResponseDraft)? onSendReply;

  const CirclePostCard({
    super.key,
    required this.t,
    required this.author,
    required this.body,
    required this.time,
    this.replies = const [],
    this.onSendReply,
  });

  @override
  State<CirclePostCard> createState() => _CirclePostCardState();
}

class _CirclePostCardState extends State<CirclePostCard> {
  static const _feelings = {
    'holding_you': 'Holding you',
    'i_understand': 'I understand',
    'this_feels_heavy': 'This feels heavy',
    'youre_doing_okay': "You're doing okay",
    'im_here': "I'm here",
    'this_will_pass': 'This will pass',
    'take_a_breath': 'Take a breath',
  };

  final _draft = TextEditingController();
  // UI-only responses while the backend contract is being implemented.
  final List<CircleReply> _localFeelingReplies = [];
  _ResponsePanel? _panel;
  String? _selectedFeeling;
  bool _sending = false;
  String? _error;
  AppTokens get t => widget.t;
  List<CircleReply> get _replies => [
    ...widget.replies,
    ..._localFeelingReplies,
  ];

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _togglePanel(_ResponsePanel panel) {
    setState(() => _panel = _panel == panel ? null : panel);
  }

  Future<void> _send({String? feeling}) async {
    final sendReply = widget.onSendReply;
    final text = feeling ?? _draft.text.trim();
    if (sendReply == null || text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      String? feelingKey;
      for (final entry in _feelings.entries) {
        if (entry.value == feeling) feelingKey = entry.key;
      }
      await sendReply(CircleResponseDraft(body: text, feelingKey: feelingKey));
      if (!mounted) return;
      setState(() {
        if (feeling == null) _draft.clear();
        _panel = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          if (feeling != null) _panel = _ResponsePanel.feelings;
          _error = 'Your response could not be sent. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final replies = _replies;
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
                child: Text(
                  widget.author,
                  style: AppTypography.lato700(13, t.accent),
                ),
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
          if (replies.isNotEmpty) ...[
            _divider(),
            for (final reply in replies)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${reply.author}:  ',
                        style: AppTypography.lato700(12, t.muted),
                      ),
                      TextSpan(
                        text: reply.body,
                        style: AppTypography.cormorantItalic(
                          17,
                          t.text,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttons = [
                _panelButton(
                  'Respond with feeling',
                  _ResponsePanel.feelings,
                  t.accent,
                ),
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
                replies.isEmpty
                    ? 'BE THE FIRST TO RESPOND GENTLY…'
                    : 'RESPOND GENTLY…',
                style: AppTypography.lato400(
                  10,
                  t.muted,
                ).copyWith(letterSpacing: 1.3),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _feelings.values.map(_feelingChip).toList(),
              ),
            ],
            if (_panel == _ResponsePanel.reply) _replyField(),
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
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Divider(height: 1, color: t.border),
  );

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

  Widget _feelingChip(String feeling) {
    final selected = _selectedFeeling == feeling;
    return ChoiceChip(
      label: Text(feeling),
      selected: selected,
      onSelected:
          _sending
              ? null
              : (_) {
                setState(() {
                  _selectedFeeling = feeling;
                  _panel = null;
                  _error = null;
                  if (widget.onSendReply == null &&
                      !_localFeelingReplies.any(
                        (reply) => reply.body == feeling,
                      )) {
                    _localFeelingReplies.add(
                      CircleReply(author: 'Anonymous', body: feeling),
                    );
                  }
                });
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

  Widget _replyField() {
    final canSend =
        widget.onSendReply != null &&
        _draft.text.trim().isNotEmpty &&
        !_sending;
    final input = TextField(
      controller: _draft,
      enabled: !_sending,
      minLines: 1,
      maxLines: 4,
      onChanged: (_) => setState(() => _error = null),
      style: AppTypography.cormorantItalic(17, t.text, height: 1.4),
      decoration: InputDecoration(
        hintText: 'Write a gentle response…',
        hintStyle: AppTypography.cormorantItalic(
          16,
          t.muted.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: t.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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
      child:
          _sending
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : Text(
                'Send',
                style: AppTypography.lato700(
                  12,
                  canSend ? Colors.white : t.muted,
                ),
              ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 260 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.4) {
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
