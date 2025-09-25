// Conditional export for local storage data source
// Exports web implementation on web platform, stub implementation elsewhere

export 'local_storage_web.dart' if (dart.library.io) 'local_storage_stub.dart';

// Always export from web version for shared constants and types
export 'local_storage_web.dart' show StorageKeys, StorageInfo;