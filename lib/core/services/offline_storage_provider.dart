import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'offline_storage_service.dart';

/// Provider compartido para el servicio de almacenamiento offline.
/// Se usa tanto en el flujo de Maya Voz como en el SyncService.
final offlineStorageServiceProvider = Provider<OfflineStorageService>((ref) {
  return OfflineStorageService();
});
