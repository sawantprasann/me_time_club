class CircleReply {
  final int? id;
  final String author;
  final String body;
  final String? kind;
  final String? moodKey;
  final bool anonymous;
  final bool mine;

  final DateTime? createdAt;
  final String? rawTimeString;

  const CircleReply({
    this.id,
    required this.author,
    required this.body,
    this.kind,
    this.moodKey,
    this.anonymous = false,
    this.mine = false,
    this.createdAt,
    this.rawTimeString,
  });

  String get timeString {
    if (rawTimeString != null && rawTimeString!.trim().isNotEmpty) {
      return rawTimeString!.trim();
    }
    if (createdAt == null) return 'Just now';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.isNegative && diff.inSeconds.abs() < 90) return 'Just now';
    final safeDiff = diff.isNegative ? diff.abs() : diff;
    if (safeDiff.inSeconds < 45) return 'Just now';
    if (safeDiff.inDays > 0) {
      return safeDiff.inDays == 1 ? '1 day ago' : '${safeDiff.inDays} days ago';
    }
    if (safeDiff.inHours > 0) {
      return safeDiff.inHours == 1 ? '1 hour ago' : '${safeDiff.inHours} hours ago';
    }
    if (safeDiff.inMinutes > 0) {
      return safeDiff.inMinutes == 1 ? '1 min ago' : '${safeDiff.inMinutes} mins ago';
    }
    return '1 min ago';
  }

  factory CircleReply.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    try {
      final rawDate = json['created_at'] ?? json['createdAt'] ?? json['date'];
      if (rawDate != null) {
        createdAt = DateTime.parse(rawDate.toString()).toLocal();
      }
    } catch (_) {}

    // Check if the API sends a pre-formatted human time string
    final rawTime = json['time'] ??
        json['time_ago'] ??
        json['created_at_human'] ??
        json['created_at_in_words'];
    final explicitTime = (rawTime is String &&
            rawTime.isNotEmpty &&
            !rawTime.contains('T'))
        ? rawTime
        : null;

    return CircleReply(
      id: json['id'] as int?,
      author:
          json['anonymous'] == true
              ? 'Anonymous'
              : (json['author'] as String? ?? 'Anonymous'),
      body: json['text'] as String? ?? json['body'] as String? ?? '',
      kind: json['kind'] as String?,
      moodKey: json['mood_key'] as String?,
      anonymous: json['anonymous'] as bool? ?? false,
      mine: json['mine'] as bool? ?? false,
      createdAt: createdAt,
      rawTimeString: explicitTime,
    );
  }
}

/// Proposed request content; no request is made until the replies API is ready.
class CircleResponseDraft {
  final String body;
  final String? feelingKey;

  const CircleResponseDraft({required this.body, this.feelingKey});

  Map<String, dynamic> toJson() => {
    'circle_response': {
      'body': body,
      if (feelingKey != null) 'feeling_key': feelingKey,
      'anonymous': true,
    },
  };
}

/// Mood option from /api/v1/circle_posts/moods
class CircleMood {
  final String key;
  final String label;

  const CircleMood({required this.key, required this.label});

  factory CircleMood.fromJson(Map<String, dynamic> json) => CircleMood(
    key: json['key'] as String? ?? '',
    label: json['label'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
  };
}
