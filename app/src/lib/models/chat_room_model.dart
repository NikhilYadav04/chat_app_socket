class ChatRoomModel {
  String? userId;
  String? username;
  String? chatRoomId;
  String? latestMessage;
  String? latestMessageTime;
  String? latestMessageStatus;
  String? messageId;
  int? unreadCount;

  ChatRoomModel({
    this.userId,
    this.username,
    this.latestMessage,
    this.chatRoomId,
    this.latestMessageTime,
    this.latestMessageStatus,
    this.messageId,
    this.unreadCount,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      userId: json['userId'],
      username: json['username'],
      chatRoomId: json['chatRoomId'],
      latestMessage: json['latestMessage'],
      latestMessageTime: json['latestMessageTime'],
      messageId: json['messageId'] ?? json['latestMessageId'],
      latestMessageStatus: json['latestMessageStatus'],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
