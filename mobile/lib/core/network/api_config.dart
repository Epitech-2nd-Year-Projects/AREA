class ApiConfig {
    static const String baseUrl = "http://10.0.2.2:8080";
    static const Duration connectTimeout = Duration(seconds: 15);
    static const Duration receiveTimeout = Duration(seconds: 20);

    static const Map<String, String> defaultHeaders = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    static const bool enableLogging = true;

    static const String callbackBaseUrl = "http://localhost:8080";

    static String getOAuthCallbackUrl(String provider) {
      return "$callbackBaseUrl/oauth/$provider/callback";
    }

    static String getServiceCallbackUrl(String provider) {
      return "$callbackBaseUrl/services/$provider/callback";
    }
}