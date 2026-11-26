import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'sse.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage: storage);
});

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(401, message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiClient {
  final String baseUrl;
  final SecureStorageService storage;
  final http.Client _client;

  ApiClient({
    this.baseUrl = AppConstants.defaultBaseUrl,
    required this.storage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, String>> _buildHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await storage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(includeAuth: requireAuth);
      var response = await _client.get(uri, headers: headers);

      if (response.statusCode == 401 && requireAuth) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final newHeaders = await _buildHeaders(includeAuth: true);
          response = await _client.get(uri, headers: newHeaders);
        }
      }

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('Không thể kết nối đến máy chủ. Vui lòng kiểm tra Internet.');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, bool requireAuth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(includeAuth: requireAuth);
      var response = await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      if (response.statusCode == 401 && requireAuth) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final newHeaders = await _buildHeaders(includeAuth: true);
          response = await _client.post(
            uri,
            headers: newHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
        }
      }

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('Không thể kết nối đến máy chủ. Vui lòng kiểm tra Internet.');
    }
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    required String fileField,
    required String filePath,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      final headers = await _buildHeaders(includeAuth: requireAuth);
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      if (fields != null) {
        request.fields.addAll(fields);
      }
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

      final streamed = await _client.send(request).timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 401 && requireAuth) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final retryReq = http.MultipartRequest('POST', uri);
          final newHeaders = await _buildHeaders(includeAuth: true);
          newHeaders.remove('Content-Type');
          retryReq.headers.addAll(newHeaders);
          if (fields != null) {
            retryReq.fields.addAll(fields);
          }
          retryReq.files.add(await http.MultipartFile.fromPath(fileField, filePath));
          final retryStreamed = await _client.send(retryReq).timeout(const Duration(seconds: 15));
          final retryResp = await http.Response.fromStream(retryStreamed);
          return _handleResponse(retryResp);
        }
      }

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('Không thể kết nối đến máy chủ. Vui lòng kiểm tra Internet.');
    }
  }

  /// Gửi POST và nhận phản hồi dạng Server-Sent Events (vd. trợ lý AI trả lời từng đoạn).
  ///
  /// Tự gắn Bearer token, tự refresh token khi gặp 401 rồi gửi lại một lần.
  /// Lỗi HTTP (4xx/5xx) được ném ra dưới dạng [ApiException] trước khi stream bắt đầu.
  Stream<SseEvent> postStream(String endpoint, {Map<String, dynamic>? body}) async* {
    Future<http.StreamedResponse> send() async {
      final request = http.Request('POST', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll(await _buildHeaders(includeAuth: true));
      request.headers['Accept'] = 'text/event-stream';
      if (body != null) request.body = jsonEncode(body);
      return _client.send(request);
    }

    try {
      var response = await send();
      if (response.statusCode == 401) {
        await response.stream.drain<void>();
        if (!await _refreshToken()) {
          throw UnauthorizedException('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
        }
        response = await send();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _handleResponse(await http.Response.fromStream(response));
      }
      yield* parseSse(response.stream);
    } on SocketException {
      throw NetworkException('Không thể kết nối đến máy chủ. Vui lòng kiểm tra Internet.');
    } on http.ClientException {
      throw NetworkException('Mất kết nối tới máy chủ. Vui lòng thử lại.');
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null) return false;

      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['access_token'];
        if (newToken != null) {
          await storage.saveToken(newToken);
          // Server xoay vòng refresh token: token cũ bị thu hồi sau mỗi lần refresh,
          // nên phải lưu lại refresh token mới để lần sau còn dùng được.
          final newRefreshToken = data['refresh_token'];
          if (newRefreshToken is String && newRefreshToken.isNotEmpty) {
            await storage.saveRefreshToken(newRefreshToken);
          }
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 401) {
      throw UnauthorizedException('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    } else {
      String message = 'Đã có lỗi xảy ra (${response.statusCode})';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body.containsKey('detail')) {
          message = body['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(response.statusCode, message);
    }
  }
}
