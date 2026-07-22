import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioClientProvider = Provider<Dio>((ref) {
  const baseUrl = 'https://argument-exempt-textile-graphs.trycloudflare.com';

  final BaseOptions options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  );
  return Dio(options);
});
