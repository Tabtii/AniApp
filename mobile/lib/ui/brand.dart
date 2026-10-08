import 'package:flutter/material.dart';

import 'visuals.dart';

/// AniApp's vector mark: a rising A ribbon with a play-shaped counter.
/// This painter also exports the Android/iOS launcher artwork.
class AniAppMark extends StatelessWidget {
  const AniAppMark({super.key, this.size = 36, this.tile = false});
  final double size;
  final bool tile;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'AniApp',
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: AniAppMarkPainter(tile: tile),
    ),
  );
}

class AniAppMarkPainter extends CustomPainter {
  const AniAppMarkPainter({this.tile = false});
  final bool tile;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    if (tile) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 100, 100),
        Paint()..color = const Color(0xFF0D111B),
      );
      canvas.translate(16, 16);
      canvas.scale(.68);
    }
    final body = Path()
      ..moveTo(9, 84)
      ..lineTo(42, 16)
      ..quadraticBezierTo(50, 2, 58, 16)
      ..lineTo(91, 84)
      ..quadraticBezierTo(94, 91, 86, 91)
      ..lineTo(69, 91)
      ..lineTo(58, 69)
      ..lineTo(40, 69)
      ..lineTo(29, 91)
      ..lineTo(15, 91)
      ..quadraticBezierTo(5, 91, 9, 84)
      ..close();
    final play = Path()
      ..moveTo(44, 33)
      ..lineTo(44, 58)
      ..lineTo(64, 46)
      ..close();
    final mark = Path.combine(PathOperation.difference, body, play);
    canvas.drawPath(
      mark,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFAA83), coral, Color(0xFFE895AF), lavender],
          stops: [0, .38, .7, 1],
        ).createShader(const Rect.fromLTWH(8, 8, 84, 84)),
    );
    // The trailing facet keeps the silhouette legible at launcher sizes.
    canvas.drawPath(
      Path()
        ..moveTo(69, 91)
        ..lineTo(58, 69)
        ..lineTo(76, 53)
        ..lineTo(91, 84)
        ..quadraticBezierTo(94, 91, 86, 91)
        ..close(),
      Paint()..color = lavender,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(AniAppMarkPainter oldDelegate) => tile != oldDelegate.tile;
}
