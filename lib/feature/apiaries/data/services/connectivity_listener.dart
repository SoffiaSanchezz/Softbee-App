import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:Softbee/feature/apiaries/data/services/sync_service.dart';

class ConnectivityListener {
  final SyncService syncService;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityListener({
    required this.syncService,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  /// Inicia la escucha de cambios de conectividad.
  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  /// Detiene la escucha.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final hasConnection = !results.contains(ConnectivityResult.none);

    if (hasConnection) {
      // Se recuperó la conexión: sincronizar operaciones pendientes
      await syncService.syncPendingOperations();
    }
  }
}
