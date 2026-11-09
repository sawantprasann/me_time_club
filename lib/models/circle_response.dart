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
              ? 'a mama'
              : (json['author'] as String? ?? 'a mama'),
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

/// One feeling on a post, already totaled. The card renders these as count pills.
class CircleFeelingCount {
  final String key;
  final String label;
  final int count;

  const CircleFeelingCount({
    required this.key,
    required this.label,
    required this.count,
  });

  factory CircleFeelingCount.fromJson(Map<String, dynamic> json) {
    final rawCount = json['count'];
    return CircleFeelingCount(
      key: json['key'] as String? ?? json['mood_key'] as String? ?? '',
      label: json['label'] as String? ?? json['text'] as String? ?? '',
      count: rawCount is int ? rawCount : int.tryParse('$rawCount') ?? 0,
    );
  }
}

/// Feelings, comments, and this user's feelings parsed from a circle post payload.
class CirclePostPayload {
  final List<CircleReply> comments;
  final List<CircleFeelingCount> feelings;
  final List<String> myMoods;
  final int mamaCount;

  const CirclePostPayload({
    required this.comments,
    required this.feelings,
    required this.myMoods,
    required this.mamaCount,
  });

  factory CirclePostPayload.fromJson(Map<String, dynamic> json) {
    final responses = (json['responses'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final comments = json.containsKey('comments')
        ? _repliesFrom(json['comments'])
        : _repliesFrom(responses.where((item) => item['kind'] != 'mood'));

    final feelings = json['feelings'] is List
        ? (json['feelings'] as List)
            .whereType<Map<String, dynamic>>()
            .map(CircleFeelingCount.fromJson)
            .where((feeling) => feeling.key.isNotEmpty && feeling.count > 0)
            .toList()
        : _feelingsFromResponses(responses);

    final myMoods = _myMoodsFrom(json, responses);
    final rawMamas = json['mama_count'];
    final mamaCount = rawMamas is int
        ? rawMamas
        : feelings.fold<int>(0, (sum, feeling) => sum + feeling.count);

    return CirclePostPayload(
      comments: comments,
      feelings: feelings,
      myMoods: myMoods,
      mamaCount: mamaCount,
    );
  }
}

List<CircleReply> _repliesFrom(dynamic source) {
  final list = source is List ? source : const [];
  return list
      .whereType<Map<String, dynamic>>()
      .map(CircleReply.fromJson)
      .where((reply) => reply.body.trim().isNotEmpty)
      .toList();
}

List<CircleFeelingCount> _feelingsFromResponses(List<Map<String, dynamic>> responses) {
  final counts = <String, int>{};
  final labels = <String, String>{};
  for (final item in responses) {
    if (item['kind'] != 'mood') continue;
    final key = item['mood_key'] as String? ?? '';
    if (key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + 1;
    labels[key] = item['text'] as String? ?? key;
  }
  final feelings = [
    for (final entry in counts.entries)
      CircleFeelingCount(
        key: entry.key,
        label: labels[entry.key] ?? entry.key,
        count: entry.value,
      ),
  ];
  feelings.sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    if (byCount != 0) return byCount;
    return a.label.compareTo(b.label);
  });
  return feelings;
}

List<String> _myMoodsFrom(
  Map<String, dynamic> json,
  List<Map<String, dynamic>> responses,
) {
  if (json['my_moods'] is List) {
    return (json['my_moods'] as List)
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  final single = json['my_mood'] as String?;
  if (single != null && single.isNotEmpty) return [single];
  return [
    for (final item in responses)
      if (item['mine'] == true && item['kind'] == 'mood' && item['mood_key'] is String)
        item['mood_key'] as String,
  ];
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
