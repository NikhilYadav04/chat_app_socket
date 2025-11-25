import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.56.1:3000/api';

  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  final _storage = const FlutterSecureStorage();

  ApiService() {
    //* INTERCEPTOR: This adds the Token to every request automatically
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        print(
            "API Error: ${e.response?.data} | Status: ${e.response?.statusCode}");
        return handler.next(e);
      },
    ));
  }

  //* --- AUTHENTICATION ---

  Future<Response> register(String username, String password) async {
    try {
      return await _dio.post('/users/register', data: {
        'username': username,
        'password': password,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> login(String username, String password) async {
    try {
      return await _dio.post('/users/login', data: {
        'username': username,
        'password': password,
      });
    } catch (e) {
      rethrow;
    }
  }

  //* --- CHAT DATA ---

  //* Fetch list of previous conversations
  Future<Response> getChatRooms() async {
    try {
      return await _dio.get('/chat/chat-room');
    } catch (e) {
      rethrow;
    }
  }

  //* Fetch message history for a specific person
  Future<Response> getMessages(
      String senderId, String receiverId, int page) async {
    try {
      return await _dio.get('/chat/messages', queryParameters: {
        'senderId': senderId,
        'receiverId': receiverId,
        'page': page,
        'limit': 20,
      });
    } catch (e) {
      rethrow;
    }
  }

  //* Fetch all users to start a new chat
  Future<Response> getAllUsers() async {
    try {
      return await _dio.get('/users/users');
    } catch (e) {
      rethrow;
    }
  }
}
