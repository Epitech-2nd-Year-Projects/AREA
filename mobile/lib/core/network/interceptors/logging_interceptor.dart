import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../api_config.dart';

class LoggingInterceptor extends Interceptor {
    final Logger _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 5,
        lineLength: 100,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );

    @override
    void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
        if (ApiConfig.enableLogging) {
          _logger.i("➡️ [${options.method}] ${options.uri}\n"
            "Headers: ${options.headers}\n"
            "Data: ${options.data}");
        }
        super.onRequest(options, handler);
    }

    @override
    void onResponse(Response response, ResponseInterceptorHandler handler) {
        if (ApiConfig.enableLogging) {
          _logger.i("✅ [${response.statusCode}] ${response.requestOptions.uri}\n"
              "Headers: ${response.headers}\n"
              "Body: ${response.data}");
        }
        super.onResponse(response, handler);
    }

    @override
    void onError(DioException err, ErrorInterceptorHandler handler) {
        if (ApiConfig.enableLogging) {
          _logger.e("⛔ [${err.response?.statusCode}] ${err.requestOptions.uri}\n"
            "Error: ${err.message}");
        }
        super.onError(err, handler);
    }
}