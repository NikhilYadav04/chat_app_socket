class MessageModel {
  String? messageId;
  String? chatRoomId;
  String? sender;
  String? receiver;
  String? message;
  String? messageType;
  String? fileURL;
  String? publicId;
  String? status;
  bool? isLiked;
  String? repliedMessage;
  String? repliedTo;
  bool? isEdited;
  bool? isDeleted;
  DateTime? createdAt;
  bool isMine;

  MessageModel({
    this.messageId,
    this.chatRoomId,
    this.sender,
    this.receiver,
    this.message,
    this.messageType = "text",
    this.fileURL,
    this.publicId,
    this.status,
    this.isLiked,
    this.repliedMessage,
    this.repliedTo,
    this.isEdited,
    this.isDeleted,
    this.createdAt,
    this.isMine = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {String? myUserId}) {
    String senderId = "";
    if (json["sender"] is String) {
      senderId = json["sender"];
    } else if (json["sender"] != null && json["sender"]["_id"] != null) {
      senderId = json["sender"]["_id"];
    }

    String receiverId = "";
    if (json["receiver"] is String) {
      receiverId = json["receiver"];
    } else if (json["receiver"] != null && json["receiver"]["_id"] != null) {
      receiverId = json["receiver"]["_id"];
    }

    return MessageModel(
      messageId: json["messageId"],
      chatRoomId: json["chatRoomId"],
      sender: senderId,
      receiver: receiverId,
      message: json["message"],
      messageType: json["messageType"],
      fileURL: json["fileURL"],
      publicId: json["filePublicId"],
      status: json["status"],
      isLiked: json["isLiked"],
      repliedMessage: json["repliedMessage"],
      repliedTo: json["repliedTo"],
      isEdited: json["isEdited"],
      isDeleted: json["isDeleted"],
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : DateTime.now(),
      isMine: myUserId != null && senderId == myUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "messageId": messageId,
      "chatRoomId": chatRoomId,
      "sender": sender,
      "receiver": receiver,
      "message": message,
      "messageType": messageType,
      "fileURL": fileURL,
      "status": status,
      "filePublicId": publicId,
      "isLiked": isLiked,
      "repliedMessage": repliedMessage,
      "repliedTo": repliedTo,
      "isEdited": isEdited,
      "isDeleted": isDeleted,
      "createdAt": createdAt?.toIso8601String(),
    };
  }
}
