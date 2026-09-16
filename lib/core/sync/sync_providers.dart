import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_queue.dart';

/// Cola de sincronización compartida por todas las features.
final syncQueueProvider = Provider<SyncQueue>((ref) {
  return SyncQueueImpl();
});
