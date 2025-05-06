import 'package:flutter/material.dart';
import 'package:flutter_video_trimmer_ios_android/core/utils/viewer_type_enum.dart';
import 'package:flutter_video_trimmer_ios_android/flutter_video_trimmer.dart';
import 'package:video_player/video_player.dart';

class VideoWidget extends StatefulWidget {
  final FlutterVideoTrimmer trimmer;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;

  const VideoWidget({
    super.key,
    required this.trimmer,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
    this.padding = const EdgeInsets.all(0.0),
  });

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
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
