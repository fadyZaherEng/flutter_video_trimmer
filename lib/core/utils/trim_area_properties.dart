import 'package:flutter/material.dart';

class TrimAreaProperties {
  /// * [thumbnailFit] for specifying the image fit type of each thumbnail image.
  /// By default it is set to `BoxFit.fitHeight`.
  ///
  ///
  /// * [thumbnailQuality] for specifying the quality of each
  /// generated image thumbnail, to be displayed in the trimmer
  /// area. By default it is set to `75`.
  ///
  ///
  /// * [blurEdges] for adding a blur to the trim area edges. Use `blurColor`
  /// for specifying the color of the blur (usually it's the background color
  /// which helps in blending). By default it is set to `false`.
  ///
  ///
  /// * [blurColor] for specifying the color of the blur. Use the color of the
  /// background to blend with it. By default it is set to `Colors.black`.
  ///
  ///
  /// * [startIcon] for specifying the widget to be placed at the start
  /// of the trimmer area. You can pass `null` for hiding
  /// the widget.
  ///
  ///
  /// * [endIcon] for specifying the widget to be placed at the end
  /// of the trimmer area. You can pass `null` for hiding
  /// the widget.
  ///
  ///
  /// * [borderRadius] for specifying the size of the circular border radius
  /// to be applied to each corner of the trimmer area Container.
  /// By default it is set to `4.0`.
  ///
  final BoxFit thumbnailFit;
  final int thumbnailQuality;
  final bool blurEdges;
  final Color blurColor;
  final Widget? startIcon;
  final Widget? endIcon;
  final double borderRadius;

  const TrimAreaProperties({
    this.thumbnailFit = BoxFit.fitHeight,
    this.thumbnailQuality = 75,
    this.blurEdges = false,
    this.blurColor = Colors.black,
    this.startIcon,
    this.endIcon,
    this.borderRadius = 4.0,
  });

  factory TrimAreaProperties.fixed({
    BoxFit thumbnailFit,
    int thumbnailQuality,
    double borderRadius,
  }) = FixedTrimAreaProperties;

  factory TrimAreaProperties.edgeBlur({
    BoxFit thumbnailFit,
    int thumbnailQuality,
    bool blurEdges,
    Color blurColor,
    Widget? startIcon,
    Widget? endIcon,
    double borderRadius,
  }) = _TrimAreaPropertiesWithBlur;
}

class FixedTrimAreaProperties extends TrimAreaProperties {
  const FixedTrimAreaProperties({
    super.thumbnailFit,
    super.thumbnailQuality,
    super.borderRadius,
  });
}

class _TrimAreaPropertiesWithBlur extends TrimAreaProperties {
  _TrimAreaPropertiesWithBlur({
    super.thumbnailFit,
    super.thumbnailQuality,
    blurEdges,
    super.blurColor,
    super.borderRadius,
    endIcon,
    startIcon,
  }) : super(
          blurEdges: true,
          startIcon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
          endIcon: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 16,
          ),
        );
}
