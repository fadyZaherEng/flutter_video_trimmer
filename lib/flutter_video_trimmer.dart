library flutter_video_trimmer;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_video_trimmer_ios_android/core/utils/storage_direction.dart';
import 'package:flutter_video_trimmer_ios_android/core/utils/viewer_type_enum.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_native_video_trimmer/flutter_native_video_trimmer.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class FlutterVideoTrimmer {
  final _eventController = StreamController<TrimmerEvent>.broadcast();
  final _videoTrimmer = VideoTrimmer();

  VideoPlayerController? _videoPlayerController;
  File? _currentVideoFile;

  Stream<TrimmerEvent> get eventStream => _eventController.stream;

  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  File? get currentVideoFile => _currentVideoFile;

  Future<void> loadVideo({required File videoFile}) async {
    if (!videoFile.existsSync()) {
      throw Exception("Video file not found: ${videoFile.path}");
    }

    _currentVideoFile = videoFile;
    _videoPlayerController = VideoPlayerController.file(videoFile);
    await _videoPlayerController!.initialize();

    _eventController.add(TrimmerEvent.initialized);
  }

  Future<void> saveTrimmedVideo({
    required double startValue,
    required double endValue,
    required Function(String? path) onSave,
    OutputType outputType = OutputType.video,
    int fpsGIF = 10,
    int scaleGIF = 480,
    int qualityGIF = 50,
    String videoFolderName = 'Trimmer',
    String? videoFileName,
    StorageDirection? storageDir,
  }) async {
    if (_currentVideoFile == null) {
      throw Exception('No video loaded');
    }

    final path = _currentVideoFile!.path;
    final baseName = basenameWithoutExtension(path);
    final ext = outputType == OutputType.gif ? '.gif' : extension(path);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final safeFileName = videoFileName ??
        '${baseName}_trimmed_$timestamp'.replaceAll(RegExp(r'\s+'), '_');
    final outputDir = await _getStorageDirectory(videoFolderName, storageDir);
    final outputPath = '$outputDir$safeFileName$ext';

    if (outputType == OutputType.gif) {
      final gifPath = await _generateGif(
        videoPath: path,
        fps: fpsGIF,
        width: scaleGIF,
        quality: qualityGIF,
        start: startValue,
        end: endValue,
        outputPath: outputPath,
      );
      onSave(gifPath);
    } else {
      await _videoTrimmer.loadVideo(path);
      final trimmedPath = await _videoTrimmer.trimVideo(
        startTimeMs: startValue.toInt(),
        endTimeMs: endValue.toInt(),
      );
      if (trimmedPath == null) {
        throw Exception('Video trimming failed.');
      }
      final savedPath = await File(trimmedPath).copy(outputPath);
      onSave(savedPath.path);
    }
  }

  Future<bool> videoPlaybackControl({
    required double startValue,
    required double endValue,
  }) async {
    final controller = _videoPlayerController;
    if (controller == null) return false;

    if (controller.value.isPlaying) {
      await controller.pause();
      return false;
    }

    if (controller.value.position.inMilliseconds >= endValue.toInt()) {
      await controller.seekTo(Duration(milliseconds: startValue.toInt()));
    }

    await controller.play();
    return true;
  }

  Future<String> _getStorageDirectory(
    String folderName,
    StorageDirection? storageDir,
  ) async {
    Directory baseDir;

    switch (storageDir) {
      case StorageDirection.temporaryDirectory:
        baseDir = await getTemporaryDirectory();
        break;
      case StorageDirection.externalStorageDirectory:
        baseDir = (await getExternalStorageDirectory())!;
        break;
      case StorageDirection.applicationDocumentsDirectory:
      default:
        baseDir = await getApplicationDocumentsDirectory();
    }

    final directory = Directory('${baseDir.path}/$folderName/');
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  Future<List<Uint8List>> _generateThumbnails({
    required String videoPath,
    required int fps,
    required int width,
    required int quality,
    required double start,
    required double end,
  }) async {
    if (fps > 30) throw ArgumentError('GIF FPS cannot be greater than 30');

    final frameInterval = (1000 / fps).round();
    final thumbnails = <Uint8List>[];

    for (int timeMs = start.toInt();
        timeMs <= end.toInt();
        timeMs += frameInterval) {
      final thumb = await VideoThumbnail.thumbnailData(
        video: videoPath,
        timeMs: timeMs,
        imageFormat: ImageFormat.JPEG,
        maxWidth: width,
        quality: quality,
      );
      if (thumb != null) thumbnails.add(thumb);
    }

    return thumbnails;
  }

  Future<String> _generateGif({
    required String videoPath,
    required int fps,
    required int width,
    required int quality,
    required double start,
    required double end,
    required String outputPath,
  }) async {
    final frames = await _generateThumbnails(
      videoPath: videoPath,
      fps: fps,
      width: width,
      quality: quality,
      start: start,
      end: end,
    );

    if (frames.isEmpty) throw Exception('No frames generated for GIF.');

    final gifEncoder = img.GifEncoder(repeat: 0);
    for (final bytes in frames) {
      final frame = img.decodeImage(bytes);
      if (frame != null) {
        gifEncoder.addFrame(frame, duration: (100 / fps).round());
      }
    }

    final gifBytes = gifEncoder.finish();
    if (gifBytes == null) throw Exception('GIF encoding failed');

    final file = File(outputPath);
    await file.writeAsBytes(gifBytes);
    return file.path;
  }

  void dispose() {
    _eventController.close();
    _videoPlayerController?.dispose();
  }
}
