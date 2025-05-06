// ignore_for_file: constant_identifier_names

enum DurationStyle {
  FORMAT_HH_MM_SS,
  FORMAT_MM_SS,
  FORMAT_SS,
  FORMAT_HH_MM_SS_MS,
  FORMAT_MM_SS_MS,
  FORMAT_SS_MS,
}

extension DurationFormatExt on Duration {
  String format(DurationStyle style) {
    final totalMilliseconds = inMilliseconds;

    final hours = _getHours(totalMilliseconds);
    final minutes = _getMinutes(totalMilliseconds);
    final seconds = _getSeconds(totalMilliseconds);
    final milliseconds = _getMilliseconds(totalMilliseconds);

    switch (style) {
      case DurationStyle.FORMAT_HH_MM_SS:
        return '${_pad(hours)}:${_pad(minutes)}:${_pad(seconds)}';
      case DurationStyle.FORMAT_MM_SS:
        final totalMinutes = inMinutes;
        final remainingSeconds = inSeconds % 60;
        return '${_pad(totalMinutes)}:${_pad(remainingSeconds)}';
      case DurationStyle.FORMAT_SS:
        return inSeconds.toString();
      case DurationStyle.FORMAT_HH_MM_SS_MS:
        return '${_pad(hours)}:${_pad(minutes)}:${_pad(seconds)}.${_pad(milliseconds)}';
      case DurationStyle.FORMAT_MM_SS_MS:
        final totalMinutes = inMinutes;
        final remainingSeconds = inSeconds % 60;
        return '${_pad(totalMinutes)}:${_pad(remainingSeconds)}.${_pad(milliseconds)}';
      case DurationStyle.FORMAT_SS_MS:
        return '${_pad(inSeconds)}.${_pad(milliseconds)}';
    }
  }

  int _getHours(int ms) => (ms ~/ Duration.millisecondsPerHour);

  int _getMinutes(int ms) => (ms ~/ Duration.millisecondsPerMinute) % 60;

  int _getSeconds(int ms) => (ms ~/ Duration.millisecondsPerSecond) % 60;

  int _getMilliseconds(int ms) => (ms % 1000) ~/ 10;

  String _pad(int value) => value.toString().padLeft(2, '0');
}
