/// Builds a single RTF document of every memory so it can be opened in
/// Google Docs (File → Open → Upload).
class MemoryExportItem {
  final String? title;
  final String? description;
  final String? photoUrl;
  final String? dateKey;
  final DateTime? createdAt;
  final String? tags;
  final String? childAge;

  const MemoryExportItem({
    this.title,
    this.description,
    this.photoUrl,
    this.dateKey,
    this.createdAt,
    this.tags,
    this.childAge,
  });
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// `MeTimeClub_Memories_2026-11-09.rtf`
String memoriesExportFilename(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return 'MeTimeClub_Memories_$y-$m-$d.rtf';
}

String buildMemoriesRtf({
  required List<MemoryExportItem> memories,
  required DateTime exportedAt,
  required String serverHost,
}) {
  final ordered = [...memories]..sort((a, b) {
      final ad = _entryDate(a);
      final bd = _entryDate(b);
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });

  final count = ordered.length;
  final countLabel = count == 1 ? '1 moment' : '$count moments';
  final exportedLabel =
      'Exported ${_formatLongDate(exportedAt)}';

  final buf = StringBuffer()
    ..write(r'{\rtf1\ansi\ansicpg1252\deff0\uc1')
    ..write('\n')
    ..write(r'{\fonttbl{\f0\froman Times New Roman;}{\f1\fswiss Arial;}}')
    ..write('\n')
    ..write(
      r'{\colortbl;\red44\green40\blue37;\red122\green158\blue142;\red138\green125\blue118;}',
    )
    ..write('\n')
    ..write(r'\paperw12240\paperh15840\margl1440\margr1440\margt1440\margb1440')
    ..write('\n')
    ..write(r'\pard\sa120\qc\f0\fs48\b\cf1 Your Moments\b0\par')
    ..write('\n')
    ..write(r'\pard\sa80\qc\f1\fs22\cf3 Me Time Club\par')
    ..write('\n')
    ..write(r'\pard\sa360\qc\f1\fs20\cf3 ')
    ..write(_rtfEscape(countLabel))
    ..write(r' \u183? ')
    ..write(_rtfEscape(exportedLabel))
    ..write(r'\par')
    ..write('\n');

  for (final memory in ordered) {
    final when = _entryDate(memory);
    final dateLabel = when == null ? 'Undated' : _formatLongDate(when);
    buf
      ..write(r'\pard\sa80\ql\f0\fs28\b\cf1 ')
      ..write(_rtfEscape(dateLabel))
      ..write(r'\b0\par')
      ..write('\n');

    final title = memory.title?.trim() ?? '';
    final description = memory.description?.trim() ?? '';
    final heading = title.isNotEmpty && title != description ? title : null;
    final body = description.isNotEmpty ? description : title;

    if (heading != null) {
      buf
        ..write(r'\pard\sa60\ql\f0\fs26\b\cf1 ')
        ..write(_rtfEscape(heading))
        ..write(r'\b0\par')
        ..write('\n');
    }
    if (body.isNotEmpty) {
      buf
        ..write(r'\pard\sa160\ql\f0\fs24\i\cf1 ')
        ..write(_rtfEscape(body))
        ..write(r'\i0\par')
        ..write('\n');
    }

    final age = memory.childAge?.trim() ?? '';
    if (age.isNotEmpty) {
      buf
        ..write(r'\pard\sa40\ql\f1\fs20\cf3 ')
        ..write(_rtfEscape('Age: $age'))
        ..write(r'\par')
        ..write('\n');
    }

    final tags = memory.tags?.trim() ?? '';
    if (tags.isNotEmpty) {
      buf
        ..write(r'\pard\sa40\ql\f1\fs20\cf3 ')
        ..write(_rtfEscape('Tags: $tags'))
        ..write(r'\par')
        ..write('\n');
    }

    final photo = _absolutePhotoUrl(memory.photoUrl, serverHost);
    if (photo != null) {
      buf
        ..write(r'\pard\sa40\ql\f1\fs20\cf3 Photo\par')
        ..write('\n')
        ..write(r'\pard\sa80\ql\f1\fs20\cf2 ')
        ..write(_rtfEscape(photo))
        ..write(r'\par')
        ..write('\n');
    }

    buf
      ..write(r'\pard\brdrb\brdrs\brdrw8\brdrcf2\sa280\fs4 \par')
      ..write('\n');
  }

  buf.write('}');
  return buf.toString();
}

DateTime? _entryDate(MemoryExportItem memory) {
  final key = memory.dateKey?.trim();
  if (key != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
    final parsed = DateTime.tryParse(key);
    if (parsed != null) return parsed;
  }
  return memory.createdAt?.toLocal();
}

String _formatLongDate(DateTime date) {
  return '${_months[date.month - 1]} ${date.day}, ${date.year}';
}

String? _absolutePhotoUrl(String? url, String serverHost) {
  final value = url?.trim() ?? '';
  if (value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  final base = serverHost.endsWith('/')
      ? serverHost.substring(0, serverHost.length - 1)
      : serverHost;
  final path = value.startsWith('/') ? value : '/$value';
  return '$base$path';
}

/// RTF text escape. Non-ASCII code points are written as `\uN?` so Google
/// Docs imports them. `\uc1` in the document header makes `?` the one-byte
/// fallback.
String _rtfEscape(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    if (rune == 92) {
      out.write(r'\\');
    } else if (rune == 123) {
      out.write(r'\{');
    } else if (rune == 125) {
      out.write(r'\}');
    } else if (rune == 10) {
      out.write(r'\line ');
    } else if (rune == 13) {
      continue;
    } else if (rune >= 32 && rune < 128) {
      out.writeCharCode(rune);
    } else if (rune < 32) {
      continue;
    } else if (rune <= 0xFFFF) {
      out.write('\\u${_signed16(rune)}?');
    } else {
      final v = rune - 0x10000;
      final hi = 0xD800 + (v >> 10);
      final lo = 0xDC00 + (v & 0x3FF);
      out.write('\\u${_signed16(hi)}?\\u${_signed16(lo)}?');
    }
  }
  return out.toString();
}

int _signed16(int code) => code > 32767 ? code - 65536 : code;
