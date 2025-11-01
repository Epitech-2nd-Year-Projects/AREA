import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static late final String baseUrl;
  static late final Duration connectTimeout;
  static late final Duration receiveTimeout;
  static late final bool enableLogging;
  static late final String callbackBaseUrl;

  static const Map<String, String> defaultHeaders = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  static void initialize() {
    baseUrl = dotenv.get('API_BASE_URL', fallback: 'http://10.0.2.2:8080');
    callbackBaseUrl = dotenv.get(
      'CALLBACK_BASE_URL',
      fallback: 'http://localhost:8080',
    );
    enableLogging =
        dotenv.get('ENABLE_LOGGING', fallback: 'true').toLowerCase() == 'true';

    final connectTimeoutSeconds =
        int.tryParse(dotenv.get('CONNECT_TIMEOUT_SECONDS', fallback: '15')) ??
        15;
    final receiveTimeoutSeconds =
        int.tryParse(dotenv.get('RECEIVE_TIMEOUT_SECONDS', fallback: '20')) ??
        20;

    connectTimeout = Duration(seconds: connectTimeoutSeconds);
    receiveTimeout = Duration(seconds: receiveTimeoutSeconds);
  }

  static String getOAuthCallbackUrl(String provider) {
    return "$callbackBaseUrl/oauth/$provider/callback";
  }

  static String getServiceCallbackUrl(String provider) {
    if (provider == "spotify") {
      return "http://127.0.0.1:8080/services/$provider/callback";
    }
    return "$callbackBaseUrl/services/$provider/callback";
  }
}
