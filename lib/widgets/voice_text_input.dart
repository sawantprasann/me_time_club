import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'speech_button.dart';

/// Single-line input + SpeechButton inside a Stack
class VoiceTextInput extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChange;
  final String placeholder;
  final AppTokens t;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLength;

  const VoiceTextInput({
    super.key,
    required this.value,
    required this.onChange,
    this.placeholder = '',
    required this.t,
    this.style,
    this.textAlign = TextAlign.center,
    this.maxLength,
  });

  @override
  State<VoiceTextInput> createState() => _VoiceTextInputState();
}

class _VoiceTextInputState extends State<VoiceTextInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _controller.selection = TextSelection.collapsed(offset: widget.value.length);
  }

  @override
  void didUpdateWidget(VoiceTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync when the parent programmatically changes the value
    // (e.g., clearing after submit). Do NOT update during normal typing.
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final hasValue = widget.value.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextField(
          controller: _controller,
          onChanged: widget.onChange,
          textAlign: widget.textAlign,
          maxLength: widget.maxLength,
          style: widget.style ?? AppTypography.cormorantItalic(22, t.text),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: AppTypography.cormorantItalic(22, t.muted),
            contentPadding: const EdgeInsets.fromLTRB(16, 14, 52, 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasValue ? t.accent : t.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasValue ? t.accent : t.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: t.accent, width: 1.5),
            ),
            filled: true,
            fillColor: t.card,
            counterText: '',
          ),
        ),
        // Mic Button positioned inside the field on the right
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: SpeechButton(
              onResult: (transcript) {
                widget.onChange(transcript);
              },
              t: t,
              size: 36,
            ),
          ),
        ),
      ],
    );
  }
}

/// Multi-line textarea + SpeechButton inside a Stack
class VoiceTextArea extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChange;
  final String placeholder;
  final int rows;
  final AppTokens t;
  final bool autoFocus;
  final TextStyle? style;
  final double micSize;

  const VoiceTextArea({
    super.key,
    required this.value,
    required this.onChange,
    this.placeholder = '',
    this.rows = 4,
    required this.t,
    this.autoFocus = false,
    this.style,
    this.micSize = 38,
  });

  @override
  State<VoiceTextArea> createState() => VoiceTextAreaState();
}

class VoiceTextAreaState extends State<VoiceTextArea> {
  late final TextEditingController _controller;
  final _speechKey = GlobalKey<SpeechButtonState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _controller.selection = TextSelection.collapsed(
      offset: widget.value.length,
    );
  }

  /// Text already in the field when this utterance started.
  /// Partials replace the spoken part instead of appending onto themselves.
  String? _speechBase;

  /// Stops the mic, waits for the transcript, and returns the field text.
  Future<String> finishListening() async {
    await _speechKey.currentState?.finishListening();
    return _controller.text.trim();
  }

  void _applySpoken(String transcript, {required bool done}) {
    final spoken = transcript.trim();
    _speechBase ??= _controller.text;
    final base = _speechBase!;
    final next =
        spoken.isEmpty
            ? base
            : (base.trim().isEmpty ? spoken : '${base.trimRight()} $spoken');
    if (_controller.text != next) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      widget.onChange(next);
    }
    if (done) _speechBase = null;
  }

  @override
  void didUpdateWidget(VoiceTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync when the parent programmatically changes the value
    // (e.g., clearing after submit). Do NOT update during normal typing.
    if (widget.value != _controller.text) {
      _speechBase = null;
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextField(
          controller: _controller,
          onChanged: widget.onChange,
          autofocus: widget.autoFocus,
          maxLines: widget.rows,
          style: widget.style ?? AppTypography.cormorantItalic(17, t.text, height: 1.65),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: AppTypography.cormorantItalic(15, t.muted),
            contentPadding: EdgeInsets.fromLTRB(16, 14, widget.micSize + 16, 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: t.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: t.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: t.accent, width: 1.5),
            ),
            filled: true,
            fillColor: t.card,
          ),
        ),
        // Mic Button positioned bottom-right inside the field
        Positioned(
          bottom: 10,
          right: 10,
          child: SpeechButton(
            key: _speechKey,
            onPartial: (transcript) => _applySpoken(transcript, done: false),
            onResult: (transcript) => _applySpoken(transcript, done: true),
            onListeningChanged: (listening) {
              if (listening) _speechBase = null;
            },
            t: t,
            size: widget.micSize,
          ),
        ),
      ],
    );
  }
}
