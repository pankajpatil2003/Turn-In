import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_constants.dart';

part 'dio_client.g.dart';

// 1. Create a Riverpod provider for the secure storage
@Riverpod(keepAlive: true)
// FIX: Using Ref instead of the deprecated SecureStorageRef type alias
FlutterSecureStorage secureStorage(Ref ref) { 
  return const FlutterSecureStorage();
}

// 2. Create the main Dio client provider
@Riverpod(keepAlive: true)
// FIX: Using Ref instead of the deprecated DioClientRef type alias
Dio dioClient(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: kBaseUrl,
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // 3. Add Interceptor to attach the JWT Token
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Read the token from the secure storage provider
        final token = await ref.read(secureStorageProvider).read(key: 'auth_token');
        
        // If a token exists, add it to the Authorization header
        if (token != null) {
          options.headers['Authorization'] = 'Token $token';
        }
        handler.next(options);
      },
      // Optional: Add logic here to handle 401 responses and force logout
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          // If you have an AuthNotifier, you would call logout here:
          // ref.read(authProvider.notifier).logout();
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
}
