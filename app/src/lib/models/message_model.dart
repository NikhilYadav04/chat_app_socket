class MessageModel {
  String? messageId;
  String? chatRoomId;
  String? sender;
  String? receiver;
  String? message;
  String? status;
  DateTime? createdAt;
  bool isMine;
  MessageModel({
    this.messageId,
    this.chatRoomId,
    this.sender,
    this.receiver,
    this.message,
    this.status,
    this.createdAt,
    this.isMine = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {String? myUserId}) {
    // logic to extract sender ID safely
    String senderId;
    if (json['sender'] is String) {
      senderId = json['sender'];
    } else if (json['sender'] != null && json['sender']['_id'] != null) {
      senderId = json['sender']['_id'];
    } else {
      senderId = '';
    }

    return MessageModel(
      messageId: json['messageId'],
      chatRoomId: json['chatRoomId'],
      sender: senderId,
      receiver: json['receiver'],
      message: json['message'],
      status: json['status'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      isMine: json['isMine'] ?? (myUserId != null && senderId == myUserId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "messageId": messageId,
      "roomId": chatRoomId,
      "sender": sender,
      "receiver": receiver,
      "message": message,
      "status": status,
      "createdAt": createdAt?.toIso8601String(),
    };
  }
}
