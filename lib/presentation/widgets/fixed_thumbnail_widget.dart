import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_video_trimmer/core/utils/trimmer_utils.dart';
import 'package:transparent_image/transparent_image.dart';


class FixedThumbnailWidget extends StatelessWidget {
  /// The video file from which thumbnails are generated.
  final File videoFile;
  /// The total duration of the video in milliseconds.
  final int videoDuration;
  /// The height of each thumbnail.
  final double thumbnailHeight;
  /// How the thumbnails should be inscribed into the allocated space.
  final BoxFit fit;
  /// The number of thumbnails to generate.
  final int numberOfThumbnails;
  /// Callback function that is called when thumbnail loading is complete.
  final VoidCallback onThumbnailLoadingComplete;
  /// The quality of the generated thumbnails.
  final int quality;

  const FixedThumbnailWidget({
    super.key,
    required this.videoFile,
    required this.videoDuration,
    required this.thumbnailHeight,
    required this.numberOfThumbnails,
    required this.fit,
    required this.onThumbnailLoadingComplete,
    this.quality = 75,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Uint8List?>>(
      stream: generateThumbnail(
        videoPath: videoFile.path,
        videoDuration: videoDuration,
        numberOfThumbnails: numberOfThumbnails,
        thumbnailHeight: thumbnailHeight,
        quality: quality,
        onThumbnailLoadingComplete: onThumbnailLoadingComplete,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final imageBytes = snapshot.data!;
          return Row(
            mainAxisSize: MainAxisSize.max,
            children: List.generate(
              numberOfThumbnails,
                  (index) => _buildThumbnail(imageBytes, index),
            ),
          );
        }

        return Container(
          color: Colors.grey.shade900,
          height: thumbnailHeight,
          width: double.infinity,
        );
      },
    );
  }

  Widget _buildThumbnail(List<Uint8List?> imageBytes, int index) {
    final placeholderImage = Image.memory(
      imageBytes.isNotEmpty ? imageBytes[0] ?? kTransparentImage : kTransparentImage,
      fit: fit,
      opacity: const AlwaysStoppedAnimation(0.2),
    );

    return SizedBox(
      height: thumbnailHeight,
      width: thumbnailHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          placeholderImage,
          if (index < imageBytes.length && imageBytes[index] != null)
            FadeInImage(
              placeholder: MemoryImage(kTransparentImage),
              image: MemoryImage(imageBytes[index]!),
              fit: fit,
            ),
        ],
      ),
    );
  }
}
