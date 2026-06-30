import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          style:
              widget.style ??
              GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: t.text,
              ),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontStyle: FontStyle.italic,
              color: t.muted,
            ),
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
  State<VoiceTextArea> createState() => _VoiceTextAreaState();
}

class _VoiceTextAreaState extends State<VoiceTextArea> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _controller.selection = TextSelection.collapsed(offset: widget.value.length);
  }

  @override
  void didUpdateWidget(VoiceTextArea oldWidget) {
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextField(
          controller: _controller,
          onChanged: widget.onChange,
          autofocus: widget.autoFocus,
          maxLines: widget.rows,
          style:
              widget.style ??
              GoogleFonts.cormorantGaramond(
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: t.text,
                height: 1.65,
              ),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: GoogleFonts.cormorantGaramond(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: t.muted,
            ),
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
            onResult: (transcript) {
              final newVal = widget.value.isEmpty
                  ? transcript
                  : '${widget.value} $transcript';
              widget.onChange(newVal);
            },
            t: t,
            size: widget.micSize,
          ),
        ),
      ],
    );
  }
}
