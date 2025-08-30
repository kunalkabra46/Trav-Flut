import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _defaultBaseUrl = 'http://localhost:3000/api';

  // API Configuration
  static String get apiBaseUrl {
    final url = dotenv.env['API_BASE_URL'] ?? _defaultBaseUrl;
    if (kDebugMode) {
      debugPrint('[AppConfig] Using API base URL: $url');
    }
    return url;
  }

  // Environment
  static String get environment {
    return dotenv.env['ENVIRONMENT'] ?? 'development';
  }

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // API Endpoints (for easy access)
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String tripsEndpoint = '/trips';
  static const String feedEndpoint = '/feed';
  static const String discoverEndpoint = '/discover';
  static const String followEndpoint = '/follow';

  // Validation
  static bool get isValid {
    try {
      final url = Uri.parse(apiBaseUrl);
      return url.hasScheme && url.hasAuthority;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppConfig] Invalid API base URL: $apiBaseUrl');
      }
      return false;
    }
  }

  // Initialize environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      if (kDebugMode) {
        debugPrint('[AppConfig] Environment configuration loaded successfully');
        debugPrint('[AppConfig] API Base URL: $apiBaseUrl');
        debugPrint('[AppConfig] Environment: $environment');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppConfig] Failed to load .env file: $e');
        debugPrint('[AppConfig] Using default configuration');
      }
    }
  }
}
