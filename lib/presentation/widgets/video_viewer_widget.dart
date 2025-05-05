import 'package:flutter/material.dart';
import 'package:flutter_video_trimmer/core/utils/viewer_type_enum.dart';
import 'package:flutter_video_trimmer/flutter_video_trimmer.dart';
import 'package:video_player/video_player.dart';

class VideoViewer extends StatefulWidget {
  final FlutterVideoTrimmer trimmer;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;

  const VideoViewer({
    super.key,
    required this.trimmer,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
    this.padding = const EdgeInsets.all(0.0),
  });

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  late final Stream<TrimmerEvent> _eventStream;
  late final FlutterVideoTrimmer _trimmer;

  @override
  void initState() {
    super.initState();
    _trimmer = widget.trimmer;
    _eventStream = _trimmer.eventStream;

    _eventStream.listen((event) {
      if (event == TrimmerEvent.initialized) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _trimmer.videoPlayerController;

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(backgroundColor: Colors.white),
      );
    }

    return Padding(
      padding: widget.padding,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.borderColor,
                width: widget.borderWidth,
              ),
            ),
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }
}
