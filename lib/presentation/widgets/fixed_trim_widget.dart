import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_video_trimmer_ios_android/core/utils/duration_styles.dart';
import 'package:flutter_video_trimmer_ios_android/core/utils/editor_drag_type.dart';
import 'package:flutter_video_trimmer_ios_android/core/utils/trim_area_properties.dart';
import 'package:flutter_video_trimmer_ios_android/core/utils/trim_editor_painter.dart';
import 'package:flutter_video_trimmer_ios_android/core/utils/trim_editor_properties.dart';
import 'package:flutter_video_trimmer_ios_android/flutter_video_trimmer.dart';
 import 'package:video_player/video_player.dart';

import 'fixed_thumbnail_widget.dart';

class FixedTrimWidget extends StatefulWidget {
  /// Controls video trimming logic and playback.
  final FlutterVideoTrimmer trimmer;

  /// Width of the trimmer preview area.
  final double viewerWidth;

  /// Height of the trimmer preview area.
  final double viewerHeight;

  /// Maximum allowed duration for the trimmed video.
  final Duration maxVideoLength;

  /// Whether to show the start and end times above the trimmer.
  /// Defaults to `true`.
  final bool showDuration;

  /// Text style for displaying duration labels.
  /// Defaults to `TextStyle(color: Colors.white)`.
  final TextStyle durationTextStyle;

  /// Format style for displaying time durations (e.g., HH:MM:SS).
  /// Defaults to `DurationStyle.FORMAT_HH_MM_SS`.
  final DurationStyle durationStyle;

  /// Callback triggered when the start point of the trim changes.
  /// Returns start time in milliseconds.
  final Function(double startValue)? onStartChanged;

  /// Callback triggered when the end point of the trim changes.
  /// Returns end time in milliseconds.
  final Function(double endValue)? onEndChanged;

  /// Callback triggered on video playback state change.
  /// Returns `true` if playing, `false` if paused.
  final Function(bool isPlaying)? onPlaybackStateChanged;

  /// Customization options for the trim editor UI.
  final TrimEditorProperties editorProperties;

  /// Customization options for the trim area's visual style.
  final FixedTrimAreaProperties areaProperties;

  /// Callback triggered when all video thumbnails are loaded.
  final VoidCallback onThumbnailsLoaded;

  const FixedTrimWidget({
    super.key,
    required this.trimmer,
    required this.onThumbnailsLoaded,
    this.viewerWidth = 50.0 * 8,
    this.viewerHeight = 50,
    this.maxVideoLength = const Duration(milliseconds: 0),
    this.showDuration = true,
    this.durationTextStyle = const TextStyle(color: Colors.white),
    this.durationStyle = DurationStyle.FORMAT_HH_MM_SS,
    this.onStartChanged,
    this.onEndChanged,
    this.onPlaybackStateChanged,
    this.editorProperties = const TrimEditorProperties(),
    this.areaProperties = const FixedTrimAreaProperties(),
  });

  @override
  State<FixedTrimWidget> createState() => _FixedTrimWidgetState();
}

/// A widget that provides a video trimmer interface.
///
/// Displays a frame-by-frame preview with draggable handles to select
/// the portion of the video to trim.
///
/// Required parameters:
/// - [viewerWidth]: Width of the trimmer area.
/// - [viewerHeight]: Height of the trimmer area.
///
/// Optional parameters:
/// - [maxVideoLength]: Maximum duration for the trimmed video.
/// - [showDuration]: Whether to show start/end times (default: true).
/// - [durationTextStyle]: Style for the time labels (default: white text).
/// - [durationStyle]: Format for duration (default: HH:MM:SS).
/// - [onStartChanged]: Called when start position changes.
/// - [onEndChanged]: Called when end position changes.
/// - [onPlaybackStateChanged]: Called when video is played or paused.
/// - [editorProperties]: Style and behavior options for the trimmer.
/// - [areaProperties]: Style options for the trim area.
/// - [onThumbnailsLoaded]: Called when thumbnail generation is complete.

class _FixedTrimWidgetState extends State<FixedTrimWidget>
    with TickerProviderStateMixin {
  final _trimmerAreaKey = GlobalKey();

  File? get _videoFile => widget.trimmer.currentVideoFile;

  VideoPlayerController get videoPlayerController =>
      widget.trimmer.videoPlayerController!;

  double _videoStartPos = 0.0;
  double _videoEndPos = 0.0;
  int _videoDuration = 0;
  int _currentPosition = 0;

  Offset _startPos = const Offset(0, 0);
  Offset _endPos = const Offset(0, 0);

  double _startFraction = 0.0;
  double _endFraction = 1.0;

  double _thumbnailViewerW = 0.0;
  double _thumbnailViewerH = 0.0;
  int _numberOfThumbnails = 0;

  double? fraction;
  double? maxLengthPixels;

  late double _startCircleSize;
  late double _endCircleSize;
  late double _borderRadius;

  Animation<double>? _scrubberAnimation;
  AnimationController? _animationController;
  late Tween<double> _linearTween;

  FixedThumbnailWidget? thumbnailWidget;
  EditorDragType _dragType = EditorDragType.left;
  bool _allowDrag = true;

  @override
  void initState() {
    super.initState();
    _initEditorProperties();
    SchedulerBinding.instance.addPostFrameCallback((_) => _afterLayout());
  }

  void _initEditorProperties() {
    _startCircleSize = widget.editorProperties.circleSize;
    _endCircleSize = widget.editorProperties.circleSize;
    _borderRadius = widget.editorProperties.borderRadius;
    _thumbnailViewerH = widget.viewerHeight;
  }

  void _afterLayout() {
    final renderBox =
        _trimmerAreaKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width;

    if (width == null || _videoFile == null) return;

    _thumbnailViewerW = width;
    _numberOfThumbnails = (_thumbnailViewerW ~/ _thumbnailViewerH);
    _thumbnailViewerW = _numberOfThumbnails * _thumbnailViewerH;

    _setupThumbnailWidget();
    _initializeVideoController();
  }

  void _setupThumbnailWidget() {
    thumbnailWidget = FixedThumbnailWidget(
      videoFile: _videoFile!,
      videoDuration: _videoDuration,
      fit: widget.areaProperties.thumbnailFit,
      thumbnailHeight: _thumbnailViewerH,
      numberOfThumbnails: _numberOfThumbnails,
      quality: widget.areaProperties.thumbnailQuality,
      onThumbnailLoadingComplete: widget.onThumbnailsLoaded,
    );
  }

  void _initializeVideoController() {
    final controller = videoPlayerController;
    _videoDuration = controller.value.duration.inMilliseconds;
    controller.setVolume(1.0);
    controller.addListener(_onVideoUpdate);

    final totalDuration = controller.value.duration;
    final isLimited = widget.maxVideoLength > Duration.zero &&
        widget.maxVideoLength < totalDuration;

    fraction = isLimited
        ? widget.maxVideoLength.inMilliseconds / totalDuration.inMilliseconds
        : null;

    maxLengthPixels =
        fraction != null ? _thumbnailViewerW * fraction! : _thumbnailViewerW;

    _videoEndPos = fraction != null
        ? _videoDuration * fraction!
        : _videoDuration.toDouble();

    _endPos = Offset(maxLengthPixels!, _thumbnailViewerH);
    widget.onEndChanged?.call(_videoEndPos);

    _linearTween = Tween(begin: _startPos.dx, end: _endPos.dx);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt()),
    );

    _scrubberAnimation = _linearTween.animate(_animationController!)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController?.stop();
        }
      });
  }

  void _onVideoUpdate() {
    final controller = videoPlayerController;

    if (controller.value.isPlaying) {
      widget.onPlaybackStateChanged?.call(true);

      setState(() {
        _currentPosition = controller.value.position.inMilliseconds;

        if (_currentPosition > _videoEndPos.toInt()) {
          controller.pause();
          _animationController?.stop();
          widget.onPlaybackStateChanged?.call(false);
        } else if (!_animationController!.isAnimating) {
          _animationController?.forward();
        }
      });
    } else {
      if (_animationController != null) {
        _animationController?.stop();
        widget.onPlaybackStateChanged?.call(false);
      }
    }
  }

  void _onDragStart(DragStartDetails details) {
    final localX = details.localPosition.dx;
    final startDiff = (_startPos.dx - localX).abs();
    final endDiff = (_endPos.dx - localX).abs();

    _allowDrag = startDiff <= widget.editorProperties.sideTapSize ||
        endDiff <= widget.editorProperties.sideTapSize;

    if (!_allowDrag) return;

    if (localX <= _startPos.dx + widget.editorProperties.sideTapSize) {
      _dragType = EditorDragType.left;
    } else if (localX <= _endPos.dx - widget.editorProperties.sideTapSize) {
      _dragType = EditorDragType.center;
    } else {
      _dragType = EditorDragType.right;
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_allowDrag) return;

    if (_dragType == EditorDragType.left &&
        _startPos.dx + details.delta.dx >= 0 &&
        _startPos.dx + details.delta.dx <= _endPos.dx &&
        (_endPos.dx - _startPos.dx - details.delta.dx <= maxLengthPixels!)) {
      _startCircleSize = widget.editorProperties.circleSizeOnDrag;
      _startPos += details.delta;
      _onStartDragged();
    } else if (_dragType == EditorDragType.center &&
        _startPos.dx + details.delta.dx >= 0 &&
        _endPos.dx + details.delta.dx <= _thumbnailViewerW) {
      _startCircleSize = widget.editorProperties.circleSizeOnDrag;
      _endCircleSize = widget.editorProperties.circleSizeOnDrag;
      _startPos += details.delta;
      _endPos += details.delta;
      _onStartDragged();
      _onEndDragged();
    } else if (_dragType == EditorDragType.right &&
        _endPos.dx + details.delta.dx <= _thumbnailViewerW &&
        _endPos.dx + details.delta.dx >= _startPos.dx &&
        (_endPos.dx - _startPos.dx + details.delta.dx <= maxLengthPixels!)) {
      _endCircleSize = widget.editorProperties.circleSizeOnDrag;
      _endPos += details.delta;
      _onEndDragged();
    }

    setState(() {});
  }

  void _onStartDragged() {
    _startFraction = _startPos.dx / _thumbnailViewerW;
    _videoStartPos = _videoDuration * _startFraction;
    widget.onStartChanged?.call(_videoStartPos);

    _linearTween.begin = _startPos.dx;
    _animationController?.duration =
        Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt());
    _animationController?.reset();
  }

  void _onEndDragged() {
    _endFraction = _endPos.dx / _thumbnailViewerW;
    _videoEndPos = _videoDuration * _endFraction;
    widget.onEndChanged?.call(_videoEndPos);

    _linearTween.end = _endPos.dx;
    _animationController?.duration =
        Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt());
    _animationController?.reset();
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _startCircleSize = widget.editorProperties.circleSize;
      _endCircleSize = widget.editorProperties.circleSize;
    });

    final seekTo =
        _dragType == EditorDragType.right ? _videoEndPos : _videoStartPos;
    videoPlayerController.seekTo(Duration(milliseconds: seekTo.toInt()));
  }

  @override
  void dispose() {
    videoPlayerController
      ..pause()
      ..setVolume(0.0)
      ..dispose();

    widget.onPlaybackStateChanged?.call(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showDuration)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                width: _thumbnailViewerW,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Duration(milliseconds: _videoStartPos.toInt())
                          .format(widget.durationStyle),
                      style: widget.durationTextStyle,
                    ),
                    if (videoPlayerController.value.isPlaying)
                      Text(
                        Duration(milliseconds: _currentPosition)
                            .format(widget.durationStyle),
                        style: widget.durationTextStyle,
                      ),
                    Text(
                      Duration(milliseconds: _videoEndPos.toInt())
                          .format(widget.durationStyle),
                      style: widget.durationTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          CustomPaint(
            foregroundPainter: TrimEditorPainter(
              startPos: _startPos,
              endPos: _endPos,
              scrubberAnimationDx: _scrubberAnimation?.value ?? 0,
              startCircleSize: _startCircleSize,
              endCircleSize: _endCircleSize,
              borderRadius: _borderRadius,
              borderWidth: widget.editorProperties.borderWidth,
              scrubberWidth: widget.editorProperties.scrubberWidth,
              circlePaintColor: widget.editorProperties.circlePaintColor,
              borderPaintColor: widget.editorProperties.borderPaintColor,
              scrubberPaintColor: widget.editorProperties.scrubberPaintColor,
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(widget.areaProperties.borderRadius),
              child: Container(
                key: _trimmerAreaKey,
                color: Colors.grey[900],
                height: _thumbnailViewerH,
                width: _thumbnailViewerW == 0.0
                    ? widget.viewerWidth
                    : _thumbnailViewerW,
                child: thumbnailWidget ?? const SizedBox(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
