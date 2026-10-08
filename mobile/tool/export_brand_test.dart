import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aniapp/ui/brand.dart';

void main() {
  testWidgets('export native AniApp vector mark', (tester) async {
    final sizes = <String, int>{
      for (final e in {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      }.entries)
        'android/app/src/main/res/mipmap-${e.key}/ic_launcher.png': e.value,
      'web/favicon.png': 32,
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-maskable-192.png': 192,
      'web/icons/Icon-maskable-512.png': 512,
      '../docs/brand/aniapp-mark.png': 512,
      'android/app/src/main/res/drawable/ic_launcher_foreground.png': 432,
    };
    final icons = jsonDecode(
      File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
      ).readAsStringSync(),
    );
    for (final item in icons['images'] as List) {
      sizes['ios/Runner/Assets.xcassets/AppIcon.appiconset/${item['filename']}'] =
          (double.parse(item['size'].split('x')[0]) *
                  double.parse(item['scale'].replaceAll('x', '')))
              .round();
    }
    await tester.runAsync(() async {
      for (final item in sizes.entries) {
        final rec = ui.PictureRecorder();
        final canvas = Canvas(rec);
        const AniAppMarkPainter(
          tile: true,
        ).paint(canvas, Size.square(item.value.toDouble()));
        final picture = rec.endRecording();
        final image = await picture.toImage(item.value, item.value);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(item.key).parent.createSync(recursive: true);
        File(item.key).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
    });
  });
}
