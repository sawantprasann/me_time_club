import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// One moment, laid out the way the Memories screen shows it:
/// a wide photo, then an italic caption with the card's color bar.
class MemoryCardExport {
  final String caption;
  final String accentHex;
  final Uint8List? photoJpeg;
  final int photoWidth;
  final int photoHeight;

  const MemoryCardExport({
    required this.caption,
    required this.accentHex,
    this.photoJpeg,
    this.photoWidth = 0,
    this.photoHeight = 0,
  });
}

/// `MeTimeClub_Memories_2026-11-09.docx`
///
/// Word format, not RTF: Google Docs keeps the photos when the file is a .docx.
String memoriesExportFilename(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return 'MeTimeClub_Memories_$y-$m-$d.docx';
}

/// Crops like the memory card (`BoxFit.cover`, about twice as wide as tall)
/// and returns a JPEG plus its pixel size.
({Uint8List bytes, int width, int height})? prepareMemoryPhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  var photo = img.bakeOrientation(decoded);
  const ratio = 2.0;
  final current = photo.width / photo.height;
  if (current > ratio) {
    final width = (photo.height * ratio).round().clamp(1, photo.width);
    final x = ((photo.width - width) / 2).round();
    photo = img.copyCrop(photo, x: x, y: 0, width: width, height: photo.height);
  } else if (current < ratio) {
    final height = (photo.width / ratio).round().clamp(1, photo.height);
    final y = ((photo.height - height) / 2).round();
    photo = img.copyCrop(photo, x: 0, y: y, width: photo.width, height: height);
  }
  if (photo.width > 1200) {
    photo = img.copyResize(photo, width: 1200);
  }
  return (
    bytes: img.encodeJpg(photo, quality: 82),
    width: photo.width,
    height: photo.height,
  );
}

Uint8List buildMemoriesDocx(List<MemoryCardExport> memories) {
  final images = <Uint8List>[];
  final body = StringBuffer();

  body.write(_paragraph(
    'Your Moments',
    size: 44,
    bold: true,
    after: 280,
  ));

  for (final memory in memories) {
    final hasPhoto = memory.photoJpeg != null &&
        memory.photoJpeg!.isNotEmpty &&
        memory.photoWidth > 0 &&
        memory.photoHeight > 0;
    final caption = memory.caption.trim();
    if (!hasPhoto && caption.isEmpty) continue;

    if (hasPhoto) {
      final index = images.length;
      images.add(memory.photoJpeg!);
      body.write(_photoParagraph(
        relationId: 'rId${index + 2}',
        docId: index + 1,
        name: 'moment${index + 1}.jpg',
        pixelWidth: memory.photoWidth,
        pixelHeight: memory.photoHeight,
        after: caption.isEmpty ? 360 : 0,
      ));
    }
    if (caption.isNotEmpty) {
      body.write(_paragraph(
        caption,
        italic: true,
        size: 34,
        after: 80,
        accent: memory.accentHex,
        shaded: true,
      ));
      body.write(_accentRule(memory.accentHex));
    }
  }

  final document = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
  <w:background w:color="F5F0E8"/>
  <w:body>
    $body
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720" w:header="0" w:footer="0" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
''';

  final rels = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..writeln('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">')
    ..writeln('<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>');
  for (var i = 0; i < images.length; i++) {
    rels.writeln(
      '<Relationship Id="rId${i + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image${i + 1}.jpg"/>',
    );
  }
  rels.write('</Relationships>');

  final files = <String, List<int>>{
    '[Content_Types].xml': _utf8(_contentTypes(images.isNotEmpty)),
    '_rels/.rels': _utf8(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>',
    ),
    'word/document.xml': _utf8(document),
    'word/settings.xml': _utf8(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:displayBackgroundShape/>'
      '</w:settings>',
    ),
    'word/_rels/document.xml.rels': _utf8(rels.toString()),
  };
  for (var i = 0; i < images.length; i++) {
    files['word/media/image${i + 1}.jpg'] = images[i];
  }
  return _zipStore(files);
}

String _contentTypes(bool hasJpeg) {
  final jpeg = hasJpeg
      ? '<Default Extension="jpg" ContentType="image/jpeg"/>'
      : '';
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '$jpeg'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '<Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>'
      '</Types>';
}

/// Page content is 7.5 inches wide. Photos keep the card's 2:1 crop.
const _photoWidthEmu = 6858000;

String _photoParagraph({
  required String relationId,
  required int docId,
  required String name,
  required int pixelWidth,
  required int pixelHeight,
  required int after,
}) {
  final height = pixelWidth == 0
      ? _photoWidthEmu ~/ 2
      : (_photoWidthEmu * pixelHeight / pixelWidth).round();
  return '''
<w:p>
  <w:pPr><w:spacing w:after="$after"/><w:shd w:val="clear" w:color="auto" w:fill="FFFFFF"/></w:pPr>
  <w:r>
    <w:drawing>
      <wp:inline distT="0" distB="0" distL="0" distR="0">
        <wp:extent cx="$_photoWidthEmu" cy="$height"/>
        <wp:effectExtent l="0" t="0" r="0" b="0"/>
        <wp:docPr id="$docId" name="$name"/>
        <wp:cNvGraphicFramePr>
          <a:graphicFrameLocks noChangeAspect="1"/>
        </wp:cNvGraphicFramePr>
        <a:graphic>
          <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
            <pic:pic>
              <pic:nvPicPr>
                <pic:cNvPr id="$docId" name="$name"/>
                <pic:cNvPicPr/>
              </pic:nvPicPr>
              <pic:blipFill>
                <a:blip r:embed="$relationId"/>
                <a:stretch><a:fillRect/></a:stretch>
              </pic:blipFill>
              <pic:spPr>
                <a:xfrm>
                  <a:off x="0" y="0"/>
                  <a:ext cx="$_photoWidthEmu" cy="$height"/>
                </a:xfrm>
                <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
              </pic:spPr>
            </pic:pic>
          </a:graphicData>
        </a:graphic>
      </wp:inline>
    </w:drawing>
  </w:r>
</w:p>
''';
}

String _paragraph(
  String text, {
  int size = 34,
  bool bold = false,
  bool italic = false,
  int after = 200,
  String? accent,
  bool shaded = false,
}) {
  final border = accent == null
      ? ''
      : '<w:pBdr><w:left w:val="single" w:sz="24" w:space="10" w:color="$accent"/></w:pBdr>';
  final indent = accent == null ? '' : '<w:ind w:left="220"/>';
  final shade = shaded ? '<w:shd w:val="clear" w:color="auto" w:fill="FFFFFF"/>' : '';
  final style = StringBuffer()
    ..write(bold ? '<w:b/>' : '')
    ..write(italic ? '<w:i/>' : '')
    ..write('<w:rFonts w:ascii="Georgia" w:hAnsi="Georgia"/>')
    ..write('<w:sz w:val="$size"/><w:szCs w:val="$size"/>')
    ..write('<w:color w:val="2C2825"/>');

  final runs = StringBuffer();
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (i > 0) runs.write('<w:r><w:rPr>$style</w:rPr><w:br/></w:r>');
    runs.write('<w:r><w:rPr>$style</w:rPr><w:t xml:space="preserve">${_xml(lines[i])}</w:t></w:r>');
  }

  return '<w:p><w:pPr><w:spacing w:after="$after"/>$indent$border$shade</w:pPr>$runs</w:p>';
}

/// The short accent mark under a caption on a memory card.
String _accentRule(String accent) {
  return '<w:p><w:pPr><w:spacing w:before="40" w:after="360"/>'
      '<w:ind w:left="220" w:right="8640"/>'
      '<w:pBdr><w:bottom w:val="single" w:sz="12" w:space="1" w:color="$accent"/></w:pBdr>'
      '<w:shd w:val="clear" w:color="auto" w:fill="FFFFFF"/>'
      '</w:pPr><w:r><w:t xml:space="preserve"> </w:t></w:r></w:p>';
}

String _xml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

List<int> _utf8(String value) => utf8.encode(value);

Uint8List _zipStore(Map<String, List<int>> files) {
  final local = BytesBuilder(copy: false);
  final central = BytesBuilder(copy: false);
  var offset = 0;
  for (final entry in files.entries) {
    final name = _utf8(entry.key);
    final data = entry.value;
    final crc = _crc32(data);
    final header = <int>[
      ..._u32(0x04034b50),
      ..._u16(20),
      ..._u16(0),
      ..._u16(0),
      ..._u16(0),
      ..._u16(0),
      ..._u32(crc),
      ..._u32(data.length),
      ..._u32(data.length),
      ..._u16(name.length),
      ..._u16(0),
      ...name,
    ];
    local.add(header);
    local.add(data);

    central.add([
      ..._u32(0x02014b50),
      ..._u16(20),
      ..._u16(20),
      ..._u16(0),
      ..._u16(0),
      ..._u16(0),
      ..._u16(0),
      ..._u32(crc),
      ..._u32(data.length),
      ..._u32(data.length),
      ..._u16(name.length),
      ..._u16(0),
      ..._u16(0),
      ..._u16(0),
      ..._u16(0),
      ..._u32(0),
      ..._u32(offset),
      ...name,
    ]);
    offset += header.length + data.length;
  }

  final centralBytes = central.toBytes();
  final out = BytesBuilder(copy: false)
    ..add(local.toBytes())
    ..add(centralBytes)
    ..add(_u32(0x06054b50))
    ..add(_u16(0))
    ..add(_u16(0))
    ..add(_u16(files.length))
    ..add(_u16(files.length))
    ..add(_u32(centralBytes.length))
    ..add(_u32(offset))
    ..add(_u16(0));
  return out.toBytes();
}

int _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
      crc &= 0xFFFFFFFF;
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

List<int> _u16(int value) => [value & 0xFF, (value >> 8) & 0xFF];

List<int> _u32(int value) => [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
