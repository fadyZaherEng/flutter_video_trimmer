import 'package:flutter/material.dart';
import 'package:flutter_video_trimmer/core/utils/duration_styles.dart';
import 'package:flutter_video_trimmer/core/utils/trim_area_properties.dart';
import 'package:flutter_video_trimmer/core/utils/trim_editor_properties.dart';
import 'package:flutter_video_trimmer/core/utils/viewer_type_enum.dart';
import 'package:flutter_video_trimmer/flutter_video_trimmer.dart';
import 'package:flutter_video_trimmer/presentation/widgets/fixed_trim_widget.dart';
import 'package:flutter_video_trimmer/presentation/widgets/scrollable_trim_widget.dart';

class TrimViewer extends StatefulWidget {
  /// The Trimmer controller instance.
  final FlutterVideoTrimmer trimmer;

  // --- Layout & Style ---
  final double viewerWidth;
  final double viewerHeight;
  final ViewerType type;
  final double paddingFraction;
  final bool showDuration;
  final TextStyle durationTextStyle;
  final DurationStyle durationStyle;

  // --- Trim & Editor Properties ---
  final Duration maxVideoLength;
  final TrimEditorProperties editorProperties;
  final TrimAreaProperties areaProperties;

  // --- Callbacks ---
  final Function(double startValue)? onChangeStart;
  final Function(double endValue)? onChangeEnd;
  final Function(bool isPlaying)? onChangePlaybackState;
  final VoidCallback? onThumbnailLoadingComplete;

  /// A widget to display and interact with a video timeline (thumbnails + scrubber).
  ///
  /// Automatically selects between `FixedTrimViewer` and `ScrollableTrimViewer`
  /// based on the `type` and available video length.
  ///
  /// Throws an error if `type == ViewerType.scrollable` and the video
  /// duration is shorter than `maxVideoLength + padding`.
  const TrimViewer({
    super.key,
    required this.trimmer,
    this.type = ViewerType.auto,
    this.viewerWidth = 400,
    this.viewerHeight = 50,
    this.maxVideoLength = const Duration(milliseconds: 0),
    this.paddingFraction = 0.2,
    this.showDuration = true,
    this.durationTextStyle = const TextStyle(color: Colors.white),
    this.durationStyle = DurationStyle.FORMAT_HH_MM_SS,
    this.editorProperties = const TrimEditorProperties(),
    this.areaProperties = const TrimAreaProperties(),
    this.onChangeStart,
    this.onChangeEnd,
    this.onChangePlaybackState,
    this.onThumbnailLoadingComplete,
  });

  @override
  State<TrimViewer> createState() => _TrimViewerState();
}

class _TrimViewerState extends State<TrimViewer> with TickerProviderStateMixin {
  bool? _isScrollableAllowed;

  @override
  void initState() {
    super.initState();

    widget.trimmer.eventStream.listen((event) {
      if (event == TrimmerEvent.initialized) {
        final totalDuration =
            widget.trimmer.videoPlayerController?.value.duration;
        final maxLength = widget.maxVideoLength;

        final paddedLengthMs = maxLength.inMilliseconds +
            (2 * (widget.paddingFraction * maxLength.inMilliseconds)).toInt();

        final canScroll = totalDuration != null &&
            paddedLengthMs <= totalDuration.inMilliseconds &&
            maxLength > Duration.zero;

        if (widget.type == ViewerType.scrollable && !canScroll) {
          throw Exception(
            'Video duration is shorter than maxVideoLength + padding.\n'
            'Use ViewerType.auto or reduce maxVideoLength.',
          );
        }

        setState(() => _isScrollableAllowed = canScroll);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isScrollableAllowed == null) return const SizedBox();

    final useScrollable = widget.type == ViewerType.scrollable ||
        (widget.type == ViewerType.auto && _isScrollableAllowed == true);

    final viewer = useScrollable
        ? ScrollableTrimWidget(
            flutterVideoTrimmer: widget.trimmer,
            maxVideoLength: widget.maxVideoLength,
            viewerWidth: widget.viewerWidth,
            viewerHeight: widget.viewerHeight,
            showDuration: widget.showDuration,
            durationTextStyle: widget.durationTextStyle,
            durationStyle: widget.durationStyle,
            onChangeStart: widget.onChangeStart,
            onChangeEnd: widget.onChangeEnd,
            onChangePlaybackState: widget.onChangePlaybackState,
            paddingFraction: widget.paddingFraction,
            editorProperties: widget.editorProperties,
            areaProperties: widget.areaProperties,
            onThumbnailLoadingComplete:
                widget.onThumbnailLoadingComplete ?? () {},
          )
        : FixedTrimWidget(
            trimmer: widget.trimmer,
            maxVideoLength: widget.maxVideoLength,
            viewerWidth: widget.viewerWidth,
            viewerHeight: widget.viewerHeight,
            showDuration: widget.showDuration,
            durationTextStyle: widget.durationTextStyle,
            durationStyle: widget.durationStyle,
            onStartChanged: widget.onChangeStart,
            onEndChanged: widget.onChangeEnd,
            onPlaybackStateChanged: widget.onChangePlaybackState,
            editorProperties: widget.editorProperties,
            areaProperties: FixedTrimAreaProperties(
              thumbnailFit: widget.areaProperties.thumbnailFit,
              thumbnailQuality: widget.areaProperties.thumbnailQuality,
              borderRadius: widget.areaProperties.borderRadius,
            ),
            onThumbnailsLoaded: widget.onThumbnailLoadingComplete ?? () {},
          );

    return viewer;
  }
}
