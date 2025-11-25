class UserModel {
  String? userId;
  String? username;
  bool? isOnline;
  String? lastSeen;

  UserModel({
    this.userId,
    this.username,
    this.isOnline,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['_id'] ?? json['userId'],
      username: json['username'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "username": username,
      "isOnline": isOnline,
      "lastSeen": lastSeen,
    };
  }
}
