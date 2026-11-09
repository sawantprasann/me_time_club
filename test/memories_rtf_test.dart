import 'package:flutter_test/flutter_test.dart';
import 'package:me_time_club/services/memories_rtf.dart';

void main() {
  final exportedAt = DateTime(2026, 11, 9);

  test('filename matches the Google Docs download name', () {
    expect(
      memoriesExportFilename(exportedAt),
      'MeTimeClub_Memories_2026-11-09.rtf',
    );
  });

  test('writes every moment oldest first, with photo links', () {
    final rtf = buildMemoriesRtf(
      memories: [
        MemoryExportItem(
          title: 'Newer day',
          description: 'Newer day',
          createdAt: DateTime(2026, 11, 9),
          photoUrl: '/uploads/memories/new.jpg',
          childAge: '2 years',
          tags: 'park',
        ),
        const MemoryExportItem(
          description: 'First steps',
          dateKey: '2026-03-01',
          createdAt: null,
          photoUrl: 'https://cdn.example.com/old.jpg',
        ),
      ],
      exportedAt: exportedAt,
      serverHost: 'http://139.59.23.15/',
    );

    expect(rtf.startsWith(r'{\rtf1\ansi'), isTrue);
    expect(rtf.contains('Your Moments'), isTrue);
    expect(rtf.contains('2 moments'), isTrue);
    expect(rtf.contains('Exported November 9, 2026'), isTrue);
    expect(rtf.indexOf('First steps'), lessThan(rtf.indexOf('Newer day')));
    expect(rtf.contains('March 1, 2026'), isTrue);
    expect(rtf.contains('November 9, 2026'), isTrue);
    expect(rtf.contains('http://139.59.23.15/uploads/memories/new.jpg'), isTrue);
    expect(rtf.contains('https://cdn.example.com/old.jpg'), isTrue);
    expect(rtf.contains('Age: 2 years'), isTrue);
    expect(rtf.contains('Tags: park'), isTrue);
    expect(rtf.endsWith('}'), isTrue);
  });

  test('shows a distinct title and caption once each', () {
    final rtf = buildMemoriesRtf(
      memories: const [
        MemoryExportItem(title: 'Park', description: 'We sat in the sun.'),
      ],
      exportedAt: exportedAt,
      serverHost: 'http://example.com',
    );

    expect(rtf.contains('Park'), isTrue);
    expect(rtf.contains('We sat in the sun.'), isTrue);
    expect('Park'.allMatches(rtf).length, 1);
  });

  test('escapes RTF special characters and emoji', () {
    final rtf = buildMemoriesRtf(
      memories: const [
        MemoryExportItem(description: 'a\\b {c}\nsecond 🌸'),
      ],
      exportedAt: exportedAt,
      serverHost: 'http://example.com',
    );

    expect(rtf.contains(r'a\\b \{c\}'), isTrue);
    expect(rtf.contains(r'\line '), isTrue);
    expect(rtf.contains('🌸'), isFalse);
    expect(rtf.contains(r'\u'), isTrue);
  });

  test('omits empty photo, age, and tag lines', () {
    final rtf = buildMemoriesRtf(
      memories: const [MemoryExportItem(description: 'Just words')],
      exportedAt: exportedAt,
      serverHost: 'http://example.com',
    );

    expect(rtf.contains('Photo'), isFalse);
    expect(rtf.contains('Age:'), isFalse);
    expect(rtf.contains('Tags:'), isFalse);
    expect(rtf.contains('1 moment'), isTrue);
  });
}
