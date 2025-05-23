import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fz_trimmer/core/utils/durations.dart';
import 'package:fz_trimmer/core/utils/drager_editor.dart';
import 'package:fz_trimmer/core/utils/trim_editor_painter.dart';
import 'package:fz_trimmer/core/utils/trim_editor_properties.dart';
import 'package:fz_trimmer/core/utils/trimmer_shape_props.dart';
import 'package:fz_trimmer/flutter_video_trimmer.dart';
import 'package:video_player/video_player.dart';

import 'fixed_thumbnail_widget.dart';

class FixedTrimmerWidget extends StatefulWidget {
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
  final TrimEditorProperties editorProps;

  /// Customization options for the trim area's visual style.
  final FixedTrimmerProps shapeProps;

  /// Callback triggered when all video thumbnails are loaded.
  final VoidCallback onThumbnailsLoaded;

  const FixedTrimmerWidget({
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
    this.editorProps = const TrimEditorProperties(),
    this.shapeProps = const FixedTrimmerProps(),
  });

  @override
  State<FixedTrimmerWidget> createState() => _FixedTrimmerWidgetState();
}

class _FixedTrimmerWidgetState extends State<FixedTrimmerWidget>
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
  DraggerEditor _dragType = DraggerEditor.left;
  bool _allowDrag = true;

  @override
  void initState() {
    super.initState();
    _initEditorProperties();
    SchedulerBinding.instance.addPostFrameCallback((_) => _afterLayout());
  }

  void _initEditorProperties() {
    _startCircleSize = widget.editorProps.circleSize;
    _endCircleSize = widget.editorProps.circleSize;
    _borderRadius = widget.editorProps.borderRadius;
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
      fit: widget.shapeProps.thumbnailFit,
      thumbnailHeight: _thumbnailViewerH,
      numberOfThumbnails: _numberOfThumbnails,
      quality: widget.shapeProps.thumbnailQuality,
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

    _allowDrag = startDiff <= widget.editorProps.sideTapSize ||
        endDiff <= widget.editorProps.sideTapSize;

    if (!_allowDrag) return;

    if (localX <= _startPos.dx + widget.editorProps.sideTapSize) {
      _dragType = DraggerEditor.left;
    } else if (localX <= _endPos.dx - widget.editorProps.sideTapSize) {
      _dragType = DraggerEditor.center;
    } else {
      _dragType = DraggerEditor.right;
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_allowDrag) return;

    if (_dragType == DraggerEditor.left &&
        _startPos.dx + details.delta.dx >= 0 &&
        _startPos.dx + details.delta.dx <= _endPos.dx &&
        (_endPos.dx - _startPos.dx - details.delta.dx <= maxLengthPixels!)) {
      _startCircleSize = widget.editorProps.circleSizeOnDrag;
      _startPos += details.delta;
      _onStartDragged();
    } else if (_dragType == DraggerEditor.center &&
        _startPos.dx + details.delta.dx >= 0 &&
        _endPos.dx + details.delta.dx <= _thumbnailViewerW) {
      _startCircleSize = widget.editorProps.circleSizeOnDrag;
      _endCircleSize = widget.editorProps.circleSizeOnDrag;
      _startPos += details.delta;
      _endPos += details.delta;
      _onStartDragged();
      _onEndDragged();
    } else if (_dragType == DraggerEditor.right &&
        _endPos.dx + details.delta.dx <= _thumbnailViewerW &&
        _endPos.dx + details.delta.dx >= _startPos.dx &&
        (_endPos.dx - _startPos.dx + details.delta.dx <= maxLengthPixels!)) {
      _endCircleSize = widget.editorProps.circleSizeOnDrag;
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
      _startCircleSize = widget.editorProps.circleSize;
      _endCircleSize = widget.editorProps.circleSize;
    });

    final seekTo =
        _dragType == DraggerEditor.right ? _videoEndPos : _videoStartPos;
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
              borderWidth: widget.editorProps.borderWidth,
              scrubberWidth: widget.editorProps.scrubberWidth,
              circlePaintColor: widget.editorProps.circlePaintColor,
              borderPaintColor: widget.editorProps.borderPaintColor,
              scrubberPaintColor: widget.editorProps.scrubberPaintColor,
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(widget.shapeProps.borderRadius),
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
