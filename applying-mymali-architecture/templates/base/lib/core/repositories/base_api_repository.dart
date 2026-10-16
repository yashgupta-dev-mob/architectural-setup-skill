// GENERIC: per app. One Dio per ApiHost, with that host's base URL and the timeouts the app had.
import 'package:dio/dio.dart';
import 'package:mymali/core/services/networking/endpoints.dart';
import 'package:mymali/core/services/networking/networking.dart';

class BaseApiRepo {
  /// One client per host. Put here, on that host's `BaseOptions`, exactly the
  /// timeouts the app used before (none if it had none).
  final Map<ApiHost, Dio> dios = {
    ApiHost.supabase: Dio(BaseOptions(baseUrl: Endpoints.baseUrlMain)),
  };
}
