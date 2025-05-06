import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fz_trimmer/core/utils/trimmer_utils.dart';
import 'package:transparent_image/transparent_image.dart';

/// A scrollable view displaying video thumbnails frame by frame.
class ScrollThumbnailWidget extends StatelessWidget {
  /// The video file from which thumbnails are generated.
  final File videoFile;

  /// The total duration of the video in milliseconds.
  final int videoDuration;

  /// The height of each thumbnail.
  final double thumbnailHeight;

  /// The number of thumbnails to generate.
  final int numberOfThumbnails;

  /// How the thumbnails should be inscribed into the allocated space.
  final BoxFit fit;

  /// The scroll controller for the scrollable thumbnail view.
  final ScrollController scrollController;

  /// Callback function that is called when thumbnail loading is complete.
  final VoidCallback onThumbnailLoadingComplete;

  /// The quality of the generated thumbnails, ranging from 0 to 100.
  /// Defaults to 75.
  final int quality;

  /// Creates a [ScrollableThumbnailViewer] widget.
  ///
  /// - [videoFile] is the video file from which thumbnails are generated.
  /// - [videoDuration] is the total duration of the video in milliseconds.
  /// - [thumbnailHeight] is the height of each thumbnail.
  /// - [numberOfThumbnails] is the number of thumbnails to generate.
  /// - [fit] is how the thumbnails should be inscribed into the allocated space.
  /// - [scrollController] is the scroll controller for the scrollable thumbnail view.
  /// - [onThumbnailLoadingComplete] is the callback function that is called when thumbnail loading is complete.
  /// - [quality] is the quality of the generated thumbnails, ranging from 0 to 100. Defaults to 75.
  const ScrollThumbnailWidget({
    super.key,
    required this.videoFile,
    required this.videoDuration,
    required this.thumbnailHeight,
    required this.numberOfThumbnails,
    required this.fit,
    required this.scrollController,
    required this.onThumbnailLoadingComplete,
    this.quality = 75,
  });

  @override
  Widget build(BuildContext context) {
    final double totalWidth = numberOfThumbnails * thumbnailHeight;

    return IgnorePointer(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: scrollController,
        child: SizedBox(
          width: totalWidth,
          height: thumbnailHeight,
          child: StreamBuilder<List<Uint8List?>>(
            stream: generateThumbnail(
              videoPath: videoFile.path,
              videoDuration: videoDuration,
              numberOfThumbnails: numberOfThumbnails,
              thumbnailHeight: thumbnailHeight,
              quality: quality,
              onThumbnailLoadingComplete: onThumbnailLoadingComplete,
            ),
            builder: (context, snapshot) {
              final thumbnails = snapshot.data;

              if (thumbnails != null && thumbnails.isNotEmpty) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  children: List.generate(numberOfThumbnails, (index) {
                    final imageData =
                        index < thumbnails.length ? thumbnails[index] : null;
                    return SizedBox(
                      width: thumbnailHeight,
                      height: thumbnailHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Placeholder fallback
                          Opacity(
                            opacity: 0.2,
                            child: Image.memory(
                              thumbnails.first ?? kTransparentImage,
                              fit: fit,
                            ),
                          ),
                          // Actual thumbnail
                          if (imageData != null)
                            FadeInImage(
                              placeholder: MemoryImage(kTransparentImage),
                              image: MemoryImage(imageData),
                              fit: fit,
                            ),
                        ],
                      ),
                    );
                  }),
                );
              } else {
                return Container(
                  color: Colors.grey[900],
                  width: totalWidth,
                  height: thumbnailHeight,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
