import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:me_time_club/services/memories_docx.dart';

void main() {
  test('filename is a Word file Google Docs can open with photos', () {
    expect(
      memoriesExportFilename(DateTime(2026, 11, 9)),
      'MeTimeClub_Memories_2026-11-09.docx',
    );
  });

  test('document shows the photo and caption, not the image address', () {
    final photo = img.encodeJpg(
      img.fill(img.Image(width: 8, height: 4), color: img.ColorRgb8(180, 112, 106)),
      quality: 80,
    );
    final docx = buildMemoriesDocx([
      MemoryCardExport(
        caption: 'We sat in the sun.',
        accentHex: 'B8706A',
        photoJpeg: photo,
        photoWidth: 8,
        photoHeight: 4,
      ),
      const MemoryCardExport(caption: 'Just words', accentHex: '7A9E8E'),
    ]);

    final xml = String.fromCharCodes(docx);
    expect(xml.contains('Your Moments'), isTrue);
    expect(xml.contains('We sat in the sun.'), isTrue);
    expect(xml.contains('Just words'), isTrue);
    expect(xml.contains('word/media/image1.jpg'), isTrue);
    expect(xml.contains('uploads/'), isFalse);
    expect(docx[0], 0x50);
    expect(docx[1], 0x4B);
  });

  test('keeps screen order and the card accent color', () {
    final docx = String.fromCharCodes(buildMemoriesDocx(const [
      MemoryCardExport(caption: 'Newest', accentHex: 'B8706A'),
      MemoryCardExport(caption: 'Older', accentHex: '7A9E8E'),
    ]));

    expect(docx.indexOf('Newest'), lessThan(docx.indexOf('Older')));
    expect(docx.contains('B8706A'), isTrue);
    expect(docx.contains('7A9E8E'), isTrue);
  });

  test('crops a portrait photo to the wide memory-card shape', () {
    final source = img.encodePng(img.Image(width: 20, height: 40));
    final prepared = prepareMemoryPhoto(Uint8List.fromList(source));

    expect(prepared, isNotNull);
    expect(prepared!.width / prepared.height, closeTo(2, 0.05));
    expect(prepared.bytes[0], 0xFF);
    expect(prepared.bytes[1], 0xD8);
  });
}
