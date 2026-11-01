import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/tokens.dart';
import '../icons/app_icons.dart';
import 'speech_utterance.dart';

/// Circular microphone button for voice input.
/// Idle: border t.border, bg t.card
/// Listening: border t.accent, bg accent+18, glow ring, pulsing icon
class SpeechButton extends StatefulWidget {
  final Function(String transcript) onResult;
  final ValueChanged<String>? onPartial;
  final ValueChanged<bool>? onListeningChanged;
  final AppTokens t;
  final double size;

  const SpeechButton({
    super.key,
    required this.onResult,
    this.onPartial,
    this.onListeningChanged,
    required this.t,
    this.size = 38,
  });

  @override
  State<SpeechButton> createState() => SpeechButtonState();
}

class SpeechButtonState extends State<SpeechButton>
    with SingleTickerProviderStateMixin {
  /// How long to wait for a transcript that has not arrived yet.
  /// Partials are committed immediately; this only covers a late final result.
  static const _finalGrace = Duration(milliseconds: 400);

  final stt.SpeechToText _speech = stt.SpeechToText();
  SpeechUtterance _utterance = SpeechUtterance();
  bool _isListening = false;
  bool _sessionActive = false;
  bool _isAvailable = false;
  bool _disposed = false;
  Timer? _finishTimer;
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
            _scheduleFinish();
          }
        },
        onError: (_) {
          _scheduleFinish();
        },
      );
    } catch (_) {
      _isAvailable = false;
    }
    if (mounted) setState(() {});
  }

  /// Stops the mic and returns after the transcript is committed.
  ///
  /// The recognizer often reports "not listening" before the final words
  /// arrive. Callers that submit on the next tap must wait for this.
  Future<void> finishListening() async {
    if (!_sessionActive) return;
    _finishTimer?.cancel();
    _finishTimer = null;
    final deadline = DateTime.now().add(_finalGrace);
    if (_isListening) {
      try {
        await _speech.stop().timeout(const Duration(seconds: 1));
      } catch (_) {}
    }
    while (mounted &&
        _sessionActive &&
        _utterance.latest.isEmpty &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    _finish();
  }

  void _toggleListening() async {
    if (!_isAvailable) return;

    if (_isListening || _sessionActive) {
      await finishListening();
    } else {
      _utterance = SpeechUtterance();
      _sessionActive = true;
      setState(() => _isListening = true);
      widget.onListeningChanged?.call(true);
      try {
        await _speech.listen(
          onResult: _hear,
          listenOptions: stt.SpeechListenOptions(
            localeId: 'en_GB',
            listenMode: stt.ListenMode.confirmation,
            partialResults: true,
          ),
        );
      } catch (_) {
        _finish();
      }
    }
  }

  void _hear(SpeechRecognitionResult result) {
    if (_disposed || !_sessionActive || _utterance.isFinished) return;
    final words = result.recognizedWords.trim();
    if (words.isNotEmpty) {
      _utterance.hear(words);
      widget.onPartial?.call(_utterance.latest);
    }
    if (result.finalResult) {
      _finishTimer?.cancel();
      _finishTimer = null;
      _finish();
    }
  }

  void _scheduleFinish() {
    if (_disposed || !_sessionActive || _utterance.isFinished) return;
    if (_utterance.latest.isNotEmpty) {
      _finish();
      return;
    }
    _finishTimer ??= Timer(_finalGrace, _finish);
  }

  void _finish() {
    if (_disposed || !_sessionActive) return;
    _sessionActive = false;
    _finishTimer?.cancel();
    _finishTimer = null;
    final spoken = _utterance.finish();
    if (mounted) setState(() => _isListening = false);
    widget.onListeningChanged?.call(false);
    if (spoken != null) widget.onResult(spoken);
  }

  @override
  void dispose() {
    _disposed = true;
    _finishTimer?.cancel();
    _speech.stop();
    _pulseController.dispose();
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
