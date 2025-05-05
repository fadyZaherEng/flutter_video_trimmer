/// Supported storage locations.
///
/// * [temporaryDirectory]
///
/// * [applicationDocumentsDirectory]
///
/// * [externalStorageDirectory]
///
class StorageDirection {
  const StorageDirection._(this.index);
  final int index;
  static const StorageDirection temporaryDirectory = StorageDirection._(0);
  static const StorageDirection applicationDocumentsDirectory = StorageDirection._(1);
  static const StorageDirection externalStorageDirectory = StorageDirection._(2);

  static const List<StorageDirection> values = <StorageDirection>[
    temporaryDirectory,
    applicationDocumentsDirectory,
    externalStorageDirectory,
  ];

  @override
  String toString() {
    return const <int, String>{
      0: 'temporaryDirectory',
      1: 'applicationDocumentsDirectory',
      2: 'externalStorageDirectory',
    }[index]!;
  }
}
