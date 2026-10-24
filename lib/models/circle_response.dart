class CircleReply {
  final String author;
  final String body;

  const CircleReply({required this.author, required this.body});

  factory CircleReply.fromJson(Map<String, dynamic> json) => CircleReply(
    author:
        json['anonymous'] == true
            ? 'Anonymous'
            : (json['author'] as String? ?? 'Anonymous'),
    body: json['body'] as String? ?? '',
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
