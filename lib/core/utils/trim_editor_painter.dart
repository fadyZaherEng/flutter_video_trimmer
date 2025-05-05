import 'package:flutter/material.dart';

/// A custom painter to draw the video trim editor UI,
/// including border, handles (circles), and a scrubber line.
class TrimEditorPainter extends CustomPainter {
  // --- Positional Properties ---
  final Offset startPos;
  final Offset endPos;
  final double scrubberAnimationDx;

  // --- Size Properties ---
  final double borderRadius;
  final double startCircleSize;
  final double endCircleSize;
  final double borderWidth;
  final double scrubberWidth;

  // --- Visual Flags ---
  final bool showScrubber;

  // --- Paint Colors ---
  final Color borderPaintColor;
  final Color circlePaintColor;
  final Color scrubberPaintColor;

  /// Creates a painter to render the trim editor.
  ///
  /// Required:
  /// - [startPos]: Start offset of the trim area.
  /// - [endPos]: End offset of the trim area.
  /// - [scrubberAnimationDx]: Current position of the scrubber.
  ///
  /// Optional:
  /// - [startCircleSize], [endCircleSize]: Sizes of the trim handles.
  /// - [borderRadius]: Rounded corners of the trim area.
  /// - [borderWidth], [scrubberWidth]: Widths for border and scrubber.
  /// - [showScrubber]: Whether to draw the scrubber.
  /// - [borderPaintColor], [circlePaintColor], [scrubberPaintColor]: Colors.
  const TrimEditorPainter({
    required this.startPos,
    required this.endPos,
    required this.scrubberAnimationDx,
    this.startCircleSize = 0.5,
    this.endCircleSize = 0.5,
    this.borderRadius = 4.0,
    this.borderWidth = 3.0,
    this.scrubberWidth = 1.0,
    this.showScrubber = true,
    this.borderPaintColor = Colors.white,
    this.circlePaintColor = Colors.white,
    this.scrubberPaintColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = borderPaintColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final circlePaint = Paint()
      ..color = circlePaintColor
      ..style = PaintingStyle.fill;

    final scrubberPaint = Paint()
      ..color = scrubberPaintColor
      ..strokeWidth = scrubberWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw trim area border
    final rect = Rect.fromPoints(startPos, endPos);
    final roundedRect =
        RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    canvas.drawRRect(roundedRect, borderPaint);

    // Draw trim handles (start/end)
    canvas.drawCircle(
      Offset(startPos.dx, (startPos.dy + endPos.dy) / 2),
      startCircleSize,
      circlePaint,
    );

    canvas.drawCircle(
      Offset(endPos.dx, (startPos.dy + endPos.dy) / 2),
      endCircleSize,
      circlePaint,
    );

    // Draw scrubber if enabled
    if (showScrubber && scrubberAnimationDx >= startPos.dx) {
      canvas.drawLine(
        Offset(scrubberAnimationDx, startPos.dy),
        Offset(scrubberAnimationDx, endPos.dy),
        scrubberPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
