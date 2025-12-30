import 'package:chat_app/models/chat_room_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService extends GetxService {
  static CacheService get to => Get.find();

  late SharedPreferences _prefs;

  //* In-memory cache for faster access
  final Map<String, UserModel> _userCache = {};
  final Map<String, ChatRoomModel> _chatRoomCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  //* Cache expiration times (in minutes)
  static const int USER_CACHE_DURATION = 30;
  static const int CHAT_ROOM_CACHE_DURATION = 5;
  static const int ALL_USERS_CACHE_DURATION = 60;

  //* Keys for SharedPreferences
  static const String KEY_CHAT_ROOMS = 'cached_chat_rooms';
  static const String KEY_ALL_USERS = 'cached_all_users';
  static const String KEY_USER_PREFIX = 'cached_user_';
  static const String KEY_TIMESTAMP_PREFIX = 'timestamp_';

  Future<CacheService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  //* ============ USER CACHING ============

  //* Cache a single user
  Future<void> cacheUser(UserModel user) async {
    if (user.userId == null) return;

    _userCache[user.userId!] = user;
    _cacheTimestamps['${KEY_USER_PREFIX}${user.userId}'] = DateTime.now();

    await _prefs.setString(
      '${KEY_USER_PREFIX}${user.userId}',
      jsonEncode(user.toJson()),
    );
    await _prefs.setString(
      '${KEY_TIMESTAMP_PREFIX}${KEY_USER_PREFIX}${user.userId}',
      DateTime.now().toIso8601String(),
    );
  }

  //* Get cached user
  UserModel? getCachedUser(String userId) {
    //* Check in-memory cache first
    if (_userCache.containsKey(userId)) {
      if (_isCacheValid('${KEY_USER_PREFIX}$userId', USER_CACHE_DURATION)) {
        return _userCache[userId];
      }
    }

    //* Check persistent cache
    final String? cached = _prefs.getString('${KEY_USER_PREFIX}$userId');
    if (cached != null &&
        _isCacheValid('${KEY_USER_PREFIX}$userId', USER_CACHE_DURATION)) {
      try {
        final user = UserModel.fromJson(jsonDecode(cached));
        _userCache[userId] = user;
        return user;
      } catch (e) {
        print('Error parsing cached user: $e');
      }
    }

    return null;
  }

  //* Cache all users list
  Future<void> cacheAllUsers(List<UserModel> users) async {
    //* Cache in memory
    for (var user in users) {
      if (user.userId != null) {
        _userCache[user.userId!] = user;
      }
    }

    //* Cache in persistent storage
    final List<Map<String, dynamic>> usersJson =
        users.map((u) => u.toJson()).toList();

    await _prefs.setString(KEY_ALL_USERS, jsonEncode(usersJson));
    await _prefs.setString(
      '${KEY_TIMESTAMP_PREFIX}$KEY_ALL_USERS',
      DateTime.now().toIso8601String(),
    );
    _cacheTimestamps[KEY_ALL_USERS] = DateTime.now();
  }

  //* Get all cached users
  List<UserModel>? getCachedAllUsers() {
    if (!_isCacheValid(KEY_ALL_USERS, ALL_USERS_CACHE_DURATION)) {
      return null;
    }

    final String? cached = _prefs.getString(KEY_ALL_USERS);
    if (cached != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cached);
        return decoded.map((json) => UserModel.fromJson(json)).toList();
      } catch (e) {
        print('Error parsing cached users: $e');
      }
    }

    return null;
  }

  //* ============ CHAT ROOM CACHING ============

  //* Cache chat rooms
  Future<void> cacheChatRooms(List<ChatRoomModel> rooms) async {
    //* Cache in memory
    for (var room in rooms) {
      if (room.userId != null) {
        _chatRoomCache[room.userId!] = room;
      }
    }

    //* Cache in persistent storage
    final List<Map<String, dynamic>> roomsJson =
        rooms.map((r) => _chatRoomToJson(r)).toList();

    await _prefs.setString(KEY_CHAT_ROOMS, jsonEncode(roomsJson));
    await _prefs.setString(
      '${KEY_TIMESTAMP_PREFIX}$KEY_CHAT_ROOMS',
      DateTime.now().toIso8601String(),
    );
    _cacheTimestamps[KEY_CHAT_ROOMS] = DateTime.now();
  }

  //* Get cached chat rooms
  List<ChatRoomModel>? getCachedChatRooms() {
    if (!_isCacheValid(KEY_CHAT_ROOMS, CHAT_ROOM_CACHE_DURATION)) {
      return null;
    }

    final String? cached = _prefs.getString(KEY_CHAT_ROOMS);
    if (cached != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cached);
        return decoded.map((json) => ChatRoomModel.fromJson(json)).toList();
      } catch (e) {
        print('Error parsing cached chat rooms: $e');
      }
    }

    return null;
  }

  //* Update a specific chat room in cache
  Future<void> updateChatRoomInCache(ChatRoomModel room) async {
    if (room.userId == null) return;

    _chatRoomCache[room.userId!] = room;

    //* Update in persistent storage
    List<ChatRoomModel>? rooms = getCachedChatRooms();
    if (rooms != null) {
      int index = rooms.indexWhere((r) => r.userId == room.userId);
      if (index != -1) {
        rooms[index] = room;
        await cacheChatRooms(rooms);
      }
    }
  }

  //* ============ HELPER METHODS ============

  //* Check if cache is still valid
  bool _isCacheValid(String key, int durationMinutes) {
    //* Check in-memory timestamp first
    if (_cacheTimestamps.containsKey(key)) {
      final timestamp = _cacheTimestamps[key]!;
      return DateTime.now().difference(timestamp).inMinutes < durationMinutes;
    }

    //* Check persistent timestamp
    final String? timestampStr =
        _prefs.getString('${KEY_TIMESTAMP_PREFIX}$key');
    if (timestampStr != null) {
      try {
        final timestamp = DateTime.parse(timestampStr);
        final isValid =
            DateTime.now().difference(timestamp).inMinutes < durationMinutes;
        if (isValid) {
          _cacheTimestamps[key] = timestamp;
        }
        return isValid;
      } catch (e) {
        print('Error parsing timestamp: $e');
      }
    }

    return false;
  }

  //* Convert ChatRoomModel to JSON
  Map<String, dynamic> _chatRoomToJson(ChatRoomModel room) {
    return {
      'userId': room.userId,
      'username': room.username,
      'fullName': room.fullName,
      'profileURL': room.profileURL,
      'chatRoomId': room.chatRoomId,
      'latestMessage': room.latestMessage,
      'latestMessageTime': room.latestMessageTime,
      'latestMessageStatus': room.latestMessageStatus,
      'messageId': room.messageId,
      'unreadCount': room.unreadCount,
    };
  }

  //* Clear specific cache
  Future<void> clearUserCache(String userId) async {
    _userCache.remove(userId);
    await _prefs.remove('${KEY_USER_PREFIX}$userId');
    await _prefs.remove('${KEY_TIMESTAMP_PREFIX}${KEY_USER_PREFIX}$userId');
  }

  Future<void> clearChatRoomsCache() async {
    _chatRoomCache.clear();
    await _prefs.remove(KEY_CHAT_ROOMS);
    await _prefs.remove('${KEY_TIMESTAMP_PREFIX}$KEY_CHAT_ROOMS');
  }

  Future<void> clearAllUsersCache() async {
    await _prefs.remove(KEY_ALL_USERS);
    await _prefs.remove('${KEY_TIMESTAMP_PREFIX}$KEY_ALL_USERS');
  }

  //* Clear all cache (e.g., on logout)
  Future<void> clearAllCache() async {
    _userCache.clear();
    _chatRoomCache.clear();
    _cacheTimestamps.clear();
    await _prefs.clear();
  }

  //* Force refresh by invalidating cache
  void invalidateCache(String key) {
    _cacheTimestamps.remove(key);
    _prefs.remove('${KEY_TIMESTAMP_PREFIX}$key');
  }

  //* Get cache statistics (for debugging)
  Map<String, dynamic> getCacheStats() {
    return {
      'usersInMemory': _userCache.length,
      'chatRoomsInMemory': _chatRoomCache.length,
      'timestamps': _cacheTimestamps.length,
    };
  }
}
