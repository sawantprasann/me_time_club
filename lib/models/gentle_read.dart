class GentleRead {
  final int id;
  final String title;
  final String body;
  final int total;

  const GentleRead({
    required this.id,
    required this.title,
    required this.body,
    this.total = 1,
  });

  factory GentleRead.fromJson(Map<String, dynamic> json) {
    return GentleRead(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      total: json['total'] as int? ?? 1,
    );
  }
}
