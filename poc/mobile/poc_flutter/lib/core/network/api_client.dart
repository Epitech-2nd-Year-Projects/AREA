import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

class ApiClient {
  final Dio dio;
  final PersistCookieJar cookieJar;

  ApiClient._internal(this.dio, this.cookieJar);

  static Future<ApiClient> create(String baseUrl) async {
    final dio = Dio(BaseOptions(baseUrl: baseUrl));

    final dir = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage("${dir.path}/.cookies"),
    );

    dio.interceptors.add(CookieManager(cookieJar));

    return ApiClient._internal(dio, cookieJar);
  }
}