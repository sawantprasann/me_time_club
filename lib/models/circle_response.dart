class CircleReply {
  final int? id;
  final String author;
  final String body;
  final String? kind;
  final String? moodKey;
  final bool anonymous;
  final bool mine;

  const CircleReply({
    this.id,
    required this.author,
    required this.body,
    this.kind,
    this.moodKey,
    this.anonymous = false,
    this.mine = false,
  });

  factory CircleReply.fromJson(Map<String, dynamic> json) => CircleReply(
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
  );
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
