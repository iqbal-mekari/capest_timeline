// Conditional export for local storage data source
// Exports web implementation on web platform, stub implementation elsewhere

export 'local_storage_web.dart' if (dart.library.io) 'local_storage_stub.dart';