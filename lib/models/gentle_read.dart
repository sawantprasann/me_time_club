class GentleRead {
  final int id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? imageAlt;
  final String? linkUrl;
  final String? linkLabel;
  final int total;

  const GentleRead({
    required this.id,
    this.title = '',
    this.body = '',
    this.imageUrl,
    this.imageAlt,
    this.linkUrl,
    this.linkLabel,
    this.total = 1,
  });

  factory GentleRead.fromJson(Map<String, dynamic> json) {
    return GentleRead(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['text'] as String? ?? '',
      imageUrl: _urlValue(json['image_url'] ?? json['image']),
      imageAlt: _optionalString(json['image_alt']),
      linkUrl: _urlValue(json['link_url'] ?? json['link']),
      linkLabel: _optionalString(json['link_label']),
      total: json['total'] as int? ?? 1,
    );
  }

  static String? _optionalString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static String? _urlValue(Object? value) {
    if (value is Map) return _optionalString(value['url']);
    return _optionalString(value);
  }
}
