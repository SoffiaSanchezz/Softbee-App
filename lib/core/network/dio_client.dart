import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final baseUrl = kIsWeb
      ? 'http://127.0.0.1:5000'
      : (defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:5000'
            : 'http://127.0.0.1:5000');

  final BaseOptions options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  );

  return Dio(options);
});
