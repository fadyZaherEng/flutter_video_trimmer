🎬 fz_trimmer

A Flutter package for trimming videos with customizable features and intuitive controls.

## 📖 Table of Contents
- [Screenshots](#Screenshots)
- [Features](#Features)
- [Getting Started](#getting-started)
- [Usage](#usage)
    - [tzTrimmer](#trimmer)
 - [Example](#example)
- [Dependencies Used](#dependencies-used)
- [About the Developer](#about-the-developer)
- [License](#license)

## 🎥 Check out the video trimming in action!
## Screens
| ![Screen 1](https://raw.githubusercontent.com/fadyZaherEng/flutterVideoTrimmerTest/master/assets/1.jpg) | ![Screen 2](https://raw.githubusercontent.com/fadyZaherEng/flutterVideoTrimmerTest/master/assets/2.jpg) |  
|:-----------------------------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------------:| 

## GIF DEMO
 ![GIF DEMO](https://raw.githubusercontent.com/fadyZaherEng/flutterVideoTrimmerTest/master/assets/demo.gif) | 
 |:---------------------------------------------------------------------------------------------------------------:| 

--- 
## Features

- 🚀 Customizable Video Trimmer: Tailor the trimming interface to your needs.
- 🚀 Two Trim Viewer Modes: Choose between fixed length and scrollable viewers.
- 🚀 Video Playback Control: Play, pause, and scrub through your video.
- 🚀 Video File Management: Load and save video files seamlessly.

---
## Getting Started

1. **Add dependency:**
   In your `pubspec.yaml`:
```yaml
dependencies:
  fz_trimmer: ^0.0.5
```

2. `Install Package` In your project:
```
flutter pub get
```

3. `Android Configuration:` In your AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

in /android/app/build.gradle
```
minSdk = 24
// Prefered 
compileSdk = 34
```

4. `iOS Configuration:` In your iOS Info.plist, add:
```
<key>NSCameraUsageDescription</key>
<string>Used to demonstrate image picker plugin</string>
<key>NSMicrophoneUsageDescription</key>
<string>Used to capture audio for image picker plugin</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to demonstrate image picker plugin</string>
```
In Your Podfile

```
platform :ios, '12.0'
```
```
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        ## dart: PermissionGroup.camera
        'PERMISSION_CAMERA=1',

        ## dart: PermissionGroup.microphone
        'PERMISSION_MICROPHONE=1',
 
        ## dart: PermissionGroup.photos
        'PERMISSION_PHOTOS=1',

        ## dart: [PermissionGroup.location, PermissionGroup.locationAlways, PermissionGroup.locationWhenInUse]
         'PERMISSION_LOCATION=1',

        ## dart: PermissionGroup.mediaLibrary
        'PERMISSION_MEDIA_LIBRARY=1',
      ]
    end
  end
end
```

##  Usage

Here’s a complete example showing how to build a custom video trimming screen using
the `tz_trimmer` package.

## usage tzTrimmer
```dart
 VideoWidget(flutterVideoTrimmer: _flutterVideoTrimmer),
```
## tzTrimmer
```dart
SizedBox(
  height: 100,
  child: TrimmerWidget(
  flutterVideoTrimmer: _flutterVideoTrimmer,
  viewerWidth: MediaQuery.of(context).size.width,
  onChangeStart: (value) => _startValue = value,
  onChangeEnd: (value) {
  _endValue = value;
  if (_initialEndValue == 0.0) {
  _initialEndValue = value;
  }
  },
  ),
),
```
## Example
  
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_video_trimmer/config/theme/color_schemes.dart';
import 'package:flutter_video_trimmer/core/utils/durations.dart';
import 'package:flutter_video_trimmer/flutter_video_trimmer.dart';
import 'package:flutter_video_trimmer/presentation/widgets/trimmer_widget.dart';
import 'package:flutter_video_trimmer/presentation/widgets/video_widget.dart';

class VideoTrimmerScreen extends StatefulWidget {
  final File file;
  final int maxDuration;

  const VideoTrimmerScreen({
    super.key,
    required this.file,
    required this.maxDuration,
  });

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  final FlutterVideoTrimmer _trimmer = FlutterVideoTrimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;
  double _initialEndValue = 0.0;
  bool _isPlaying = false;
  bool _progressVisibility = false;

  Future<String?> _saveVideo() async {
    setState(() => _progressVisibility = true);
    String? value;

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (String? outputPath) {
        value = outputPath;
        Navigator.pop(context, value);
        debugPrint('OUTPUT PATH: $value');
        const snackBar = SnackBar(content: Text('Video Saved successfully'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
    ).then((_) {
      setState(() => _progressVisibility = false);
    });

    return value;
  }

  void _loadVideo() => _trimmer.loadVideo(videoFile: widget.file);

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(child: VideoViewer(trimmer: _trimmer)),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: TrimmerWidget(
                flutterVideoTrimmer: _trimmer,
                viewerHeight: 60.0,
                showDuration: true,
                durationStyle: DurationStyle.FORMAT_HH_MM_SS,
                durationTextStyle: const TextStyle(color: Colors.black),
                viewerWidth: MediaQuery
                    .of(context)
                    .size
                    .width,
                onChangeStart: (value) => _startValue = value,
                onChangeEnd: (value) {
                  _endValue = value;
                  if (_initialEndValue == 0.0) _initialEndValue = value;
                },
                onChangePlaybackState: (value) =>
                    setState(() => _isPlaying = value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorSchemes.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.white)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorSchemes.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text("SAVE", style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        if (!_progressVisibility) {
                          if (Duration(
                              milliseconds: (_endValue - _startValue).toInt())
                              .inSeconds >
                              widget.maxDuration) {
                            _showMessageDialog();
                          } else {
                            await _saveVideo();
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showMessageDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            content: Text(
              "Keep It Short And Sweet — Videos Are Best At ${widget
                  .maxDuration} Seconds Or Less. Thanks!",
            ),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
    );
  }
}
```
## Example_Full_Code
[You Can Find The Full Code Here](https://github.com/fadyZaherEng/flutterVideoTrimmer)
## Dependencies Used
## This package uses (You do not have to import them):
    flutter_native_video_trimmer:
    video_thumbnail: 
    video_player: 
    path_provider: 
    intl: 
    transparent_image: 
    image: 
    path: 

```
Before using this example directly in a Flutter app, don't forget to add the tz_trimmer &
image_picker packages to your pubspec.yaml file.
You can try out this example by replacing the entire content of main.dart file of a newly created
Flutter project.
```

## About the Developer
Hello! 👋 I'm Fady Zaher, a Mid Level Flutter Developer with extensive experience in building high-quality mobile applications.
- 📧 Email: fedo.zaher@gmail.com
---
If you like this package, feel free to ⭐️ the repo and share it!

📝 License
MIT License

Copyright (c) 2025 [Fady Zaher]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

