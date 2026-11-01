/// Words heard for one mic session.
///
/// Partials replace each other. [finish] publishes the latest words once,
/// so a late final result cannot append the same sentence again.
class SpeechUtterance {
  String _latest = '';
  bool _finished = false;

  String get latest => _latest;
  bool get isFinished => _finished;

  void hear(String words) {
    if (_finished) return;
    final trimmed = words.trim();
    if (trimmed.isNotEmpty) _latest = trimmed;
  }

  /// Ends the session. Returns the transcript the first time only.
  String? finish() {
    if (_finished) return null;
    _finished = true;
    final words = _latest.trim();
    return words.isEmpty ? null : words;
  }
}
