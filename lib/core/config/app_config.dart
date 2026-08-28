import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Entornos disponibles para la app.
enum Environment { dev, qa, prod }
class AppConfig {
  AppConfig._();

  static late Environment environment;
  static Future<void> load() async {
    environment = _resolveEnvironment();
    await dotenv.load(fileName: _envFileName(environment));
  }

  static Environment _resolveEnvironment() {
    const raw = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (raw.toLowerCase().trim()) {
      case 'prod':
      case 'production':
        return Environment.prod;
      case 'qa':
      case 'staging':
        return Environment.qa;
      case 'dev':
      case 'development':
      default:
        return Environment.dev;
    }
  }

  static String _envFileName(Environment env) {
    switch (env) {
      case Environment.dev:
        return '.env.dev';
      case Environment.qa:
        return '.env.qa';
      case Environment.prod:
        return '.env.prod';
    }
  }

  static String get backUrl {
    final raw = (dotenv.env['backURL'] ?? '').trim();
    return _resolveLocalhost(raw);
  }

  static String _resolveLocalhost(String url) {
    if (url.isEmpty) return url;

    final isLocalhost =
        url.contains('localhost') || url.contains('127.0.0.1');
    if (!isLocalhost) return url;

    // En web y en iOS 'localhost' apunta correctamente al host.
    if (kIsWeb) return url;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return url
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }

    return url;
  }

  static bool get isDev => environment == Environment.dev;
  static bool get isQa => environment == Environment.qa;
  static bool get isProd => environment == Environment.prod;
}
