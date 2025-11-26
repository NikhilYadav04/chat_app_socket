class UserModel {
  final String? userId;
  final String? fullName;
  final String? username;
  final String? profileURL;
  final String? publicURL;
  final bool? isOnline;
  final String? lastSeen;

  const UserModel({
    // Use const constructor for efficiency
    required this.userId,
    required this.fullName,
    required this.username,
    required this.profileURL,
    required this.publicURL,
    required this.isOnline,
    required this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Note: The fields are still nullable for flexibility,
    // but the constructor requires them for internal consistency.
    return UserModel(
      userId: json['_id'] ?? json['userId'],
      fullName: json['fullName'],
      username: json['username'],
      profileURL: json['profileURL'],
      publicURL: json['publicURL'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "fullName": fullName,
      "username": username,
      "profileURL": profileURL,
      "publicURL": publicURL,
      "isOnline": isOnline,
      "lastSeen": lastSeen,
    };
  }

  // --- Copy With Method ---
  UserModel copyWith({
    String? userId,
    String? fullName,
    String? username,
    String? profileURL,
    String? publicURL,
    bool? isOnline,
    String? lastSeen,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profileURL: profileURL ?? this.profileURL,
      publicURL: publicURL ?? this.publicURL,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
