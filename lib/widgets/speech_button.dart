import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/tokens.dart';
import '../icons/app_icons.dart';

/// Circular microphone button for voice input.
/// Idle: border t.border, bg t.card
/// Listening: border t.accent, bg accent+18, glow ring, pulsing icon
class SpeechButton extends StatefulWidget {
  final Function(String transcript) onResult;
  final AppTokens t;
  final double size;

  const SpeechButton({
    super.key,
    required this.onResult,
    required this.t,
    this.size = 38,
  });

  @override
  State<SpeechButton> createState() => _SpeechButtonState();
}

class _SpeechButtonState extends State<SpeechButton>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
      );
    } catch (_) {
      _isAvailable = false;
    }
    if (mounted) setState(() {});
  }

  void _toggleListening() async {
    if (!_isAvailable) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            widget.onResult(result.recognizedWords);
            setState(() => _isListening = false);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: 'en_GB',
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return GestureDetector(
      onTap: _isAvailable ? _toggleListening : null,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glowOpacity =
              _isListening ? 0.2 + _pulseController.value * 0.15 : 0.0;
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening ? t.accent.withValues(alpha: 0.18) : t.card,
              border: Border.all(
                color: _isListening ? t.accent : t.border,
                width: 1.5,
              ),
              boxShadow:
                  _isListening
                      ? [
                        BoxShadow(
                          color: t.accent.withValues(alpha: glowOpacity),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                      : null,
            ),
            child: Center(
              child: AppIcons.mic(
                c:
                    _isListening
                        ? t.accent
                        : (_isAvailable ? t.muted : t.border),
                s: widget.size * 0.48,
              ),
            ),
          );
        },
      ),
    );
  }
}
