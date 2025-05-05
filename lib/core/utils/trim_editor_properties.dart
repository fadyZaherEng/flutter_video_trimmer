import 'package:flutter/material.dart';

/// Configuration for customizing the video trim editor appearance and behavior.
class TrimEditorProperties {
  /// Radius of the corners of the trim area.
  final double borderRadius;

  /// Width of the border around the trim area.
  final double borderWidth;

  /// Width of the video scrubber.
  final double scrubberWidth;

  /// Size of the circular handles at trim edges when idle.
  final double circleSize;

  /// Size of the circular handles when being dragged.
  final double circleSizeOnDrag;

  /// Color of the circular handles.
  final Color circlePaintColor;

  /// Color of the trim area's border.
  final Color borderPaintColor;

  /// Color of the video scrubber.
  final Color scrubberPaintColor;

  /// Size of the touch area for side handles (in pixels).
  /// Useful for better UX on small handles.
  final int sideTapSize;

  /// Creates a customizable configuration for the video trim editor.
  ///
  /// All parameters are optional with sensible defaults:
  /// - [circleSize] default: `5.0`
  /// - [circleSizeOnDrag] default: `8.0`
  /// - [borderWidth] default: `3.0`
  /// - [scrubberWidth] default: `1.0`
  /// - [borderRadius] default: `4.0`
  /// - [circlePaintColor], [borderPaintColor], [scrubberPaintColor] default: `Colors.white`
  /// - [sideTapSize] default: `24`
  const TrimEditorProperties({
    this.borderRadius = 4.0,
    this.borderWidth = 3.0,
    this.scrubberWidth = 1.0,
    this.circleSize = 5.0,
    this.circleSizeOnDrag = 8.0,
    this.circlePaintColor = Colors.white,
    this.borderPaintColor = Colors.white,
    this.scrubberPaintColor = Colors.white,
    this.sideTapSize = 24,
  });
}
