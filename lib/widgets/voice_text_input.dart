import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';
import 'speech_button.dart';

/// Single-line input + SpeechButton inside a Stack
class VoiceTextInput extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value);
    controller.selection = TextSelection.collapsed(offset: value.length);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextField(
          controller: controller,
          onChanged: onChange,
          textAlign: textAlign,
          maxLength: maxLength,
          style:
              style ??
              GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: t.text,
              ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontStyle: FontStyle.italic,
              color: t.muted,
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 14, 52, 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: value.isNotEmpty ? t.accent : t.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: value.isNotEmpty ? t.accent : t.border,
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
                onChange(transcript);
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
class VoiceTextArea extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value);
    controller.selection = TextSelection.collapsed(offset: value.length);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextField(
          controller: controller,
          onChanged: onChange,
          autofocus: autoFocus,
          maxLines: rows,
          style:
              style ??
              GoogleFonts.cormorantGaramond(
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: t.text,
                height: 1.65,
              ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.cormorantGaramond(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: t.muted,
            ),
            contentPadding: EdgeInsets.fromLTRB(16, 14, micSize + 16, 14),
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
              final newVal = value.isEmpty ? transcript : '$value $transcript';
              onChange(newVal);
            },
            t: t,
            size: micSize,
          ),
        ),
      ],
    );
  }
}
