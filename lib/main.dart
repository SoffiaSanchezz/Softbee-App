import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await _requestMicrophonePermission();
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _requestMicrophonePermission() async {
  final status = await Permission.microphone.status;

  if (status.isDenied) {
    await Permission.microphone.request();
  } else if (status.isPermanentlyDenied) {
    await openAppSettings();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
