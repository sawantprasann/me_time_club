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
  final List<CircleMood> moods;
  final String? myMood;
  final Future<dynamic> Function(CircleResponseDraft)? onSendReply;

  const CirclePostCard({
    super.key,
    required this.t,
    required this.author,
    required this.body,
    required this.time,
    this.replies = const [],
    this.moods = const [],
    this.myMood,
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

  Map<String, String> get _feelings {
    if (widget.moods.isNotEmpty) {
      return {for (final m in widget.moods) m.key: m.label};
    }
    return _defaultFeelings;
  }

  final _draft = TextEditingController();
  // UI-only responses in test/preview environments when onSendReply is null
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
  void initState() {
    super.initState();
    if (widget.myMood != null) {
      _selectedFeeling = _feelings[widget.myMood];
    }
  }

  @override
  void didUpdateWidget(CirclePostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.myMood != oldWidget.myMood && widget.myMood != null) {
      _selectedFeeling = _feelings[widget.myMood];
    }
  }

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

  void _openAllResponses(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AllResponsesBottomSheet(
        t: t,
        author: widget.author,
        body: widget.body,
        time: widget.time,
        initialReplies: widget.replies,
        moods: widget.moods,
        onSendReply: widget.onSendReply,
      ),
    );
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
            if (replies.length > 3)
              GestureDetector(
                onTap: () => _openAllResponses(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: t.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'View all ${replies.length} responses',
                        style: AppTypography.lato700(12, t.accent),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: t.accent,
                      ),
                    ],
                  ),
                ),
              ),
            for (final reply in (replies.length > 3
                ? replies.sublist(replies.length - 3)
                : replies))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
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
                    const SizedBox(width: 8),
                    Text(
                      reply.timeString,
                      style: AppTypography.lato400(11, t.muted),
                    ),
                  ],
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

class _AllResponsesBottomSheet extends StatefulWidget {
  final AppTokens t;
  final String author;
  final String body;
  final String time;
  final List<CircleReply> initialReplies;
  final List<CircleMood> moods;
  final Future<dynamic> Function(CircleResponseDraft)? onSendReply;

  const _AllResponsesBottomSheet({
    required this.t,
    required this.author,
    required this.body,
    required this.time,
    required this.initialReplies,
    required this.moods,
    this.onSendReply,
  });

  @override
  State<_AllResponsesBottomSheet> createState() => _AllResponsesBottomSheetState();
}

class _AllResponsesBottomSheetState extends State<_AllResponsesBottomSheet> {
  late final List<CircleReply> _replies;
  final _draft = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _showFeelings = false;
  String? _error;

  AppTokens get t => widget.t;

  static const _defaultFeelings = {
    'holding_you': 'Holding you',
    'i_understand': 'I understand',
    'this_feels_heavy': 'This feels heavy',
    'youre_doing_okay': "You're doing okay",
    'im_here': "I'm here",
    'this_will_pass': 'This will pass',
    'take_a_breath': 'Take a breath',
  };

  Map<String, String> get _feelings {
    if (widget.moods.isNotEmpty) {
      return {for (final m in widget.moods) m.key: m.label};
    }
    return _defaultFeelings;
  }

  @override
  void initState() {
    super.initState();
    _replies = List.from(widget.initialReplies);
  }

  @override
  void dispose() {
    _draft.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send({String? feeling}) async {
    final text = feeling ?? _draft.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    String? feelingKey;
    for (final entry in _feelings.entries) {
      if (entry.value == feeling) feelingKey = entry.key;
    }

    if (widget.onSendReply != null) {
      try {
        final serverResult = await widget.onSendReply!(
          CircleResponseDraft(body: text, feelingKey: feelingKey),
        );
        if (mounted) {
          setState(() {
            if (serverResult is List<CircleReply>) {
              _replies
                ..clear()
                ..addAll(serverResult);
            }
            if (feeling == null) _draft.clear();
            _showFeelings = false;
          });
          _scrollToBottom();
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _error = 'Your response could not be saved. Please try again.';
          });
        }
      } finally {
        if (mounted) setState(() => _sending = false);
      }
    } else {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        height: screenHeight * 0.82,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: t.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Responses',
                              style: AppTypography.cormorant600(22, t.text),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: t.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_replies.length}',
                                style: AppTypography.lato700(11, t.accent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gentle words from the circle',
                          style: AppTypography.lato400(12, t.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: t.muted, size: 22),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: t.border),

            // Original post context summary
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.border.withValues(alpha: 0.7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.author, style: AppTypography.lato700(12, t.accent)),
                      const SizedBox(width: 8),
                      Text(widget.time, style: AppTypography.lato400(11, t.muted)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cormorantItalic(15, t.text, height: 1.4),
                  ),
                ],
              ),
            ),

            // Responses list
            Expanded(
              child: _replies.isEmpty
                  ? Center(
                      child: Text(
                        'No responses yet.\nBe the first to share a gentle word.',
                        textAlign: TextAlign.center,
                        style: AppTypography.cormorantItalic(16, t.muted, height: 1.5),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: _replies.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 20,
                        color: t.border.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, index) {
                        final reply = _replies[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  reply.author,
                                  style: AppTypography.lato700(13, t.accent),
                                ),
                                if (reply.mine) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: t.accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'You',
                                      style: AppTypography.lato700(9, t.accent),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Text(
                                  reply.timeString,
                                  style: AppTypography.lato400(11, t.muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              reply.body,
                              style: AppTypography.cormorantItalic(16, t.text, height: 1.5),
                            ),
                          ],
                        );
                      },
                    ),
            ),

            // Error message if any
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  _error!,
                  style: AppTypography.lato400(12, t.accent),
                ),
              ),

            // Feelings picker panel if toggled
            if (_showFeelings) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                decoration: BoxDecoration(
                  color: t.bg,
                  border: Border(top: BorderSide(color: t.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESPOND GENTLY WITH FEELING…',
                      style: AppTypography.lato400(10, t.muted).copyWith(letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _feelings.values.map((feeling) {
                        return ChoiceChip(
                          label: Text(feeling),
                          selected: false,
                          onSelected: _sending ? null : (_) => _send(feeling: feeling),
                          showCheckmark: false,
                          labelStyle: AppTypography.lato700(12, t.text),
                          backgroundColor: t.card,
                          side: BorderSide(color: t.border, width: 1.2),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            Divider(height: 1, color: t.border),

            // Input bar at bottom of sheet
            if (widget.onSendReply != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _sending
                            ? null
                            : () => setState(() => _showFeelings = !_showFeelings),
                        icon: Icon(
                          _showFeelings ? Icons.close_rounded : Icons.favorite_border_rounded,
                          color: _showFeelings ? t.accent : t.muted,
                          size: 22,
                        ),
                        tooltip: 'Feelings',
                      ),
                      Expanded(
                        child: TextField(
                          controller: _draft,
                          enabled: !_sending,
                          minLines: 1,
                          maxLines: 3,
                          onChanged: (_) => setState(() => _error = null),
                          style: AppTypography.cormorantItalic(16, t.text, height: 1.3),
                          decoration: InputDecoration(
                            hintText: 'Write a gentle response…',
                            hintStyle: AppTypography.cormorantItalic(
                              15,
                              t.muted.withValues(alpha: 0.7),
                            ),
                            filled: true,
                            fillColor: t.bg,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: t.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: t.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: t.accent),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _sending ? null : () => _send(),
                        style: FilledButton.styleFrom(
                          backgroundColor: t.accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: t.border,
                          disabledForegroundColor: t.muted,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                          minimumSize: const Size(42, 42),
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 17, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

