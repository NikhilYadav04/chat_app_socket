class CallModel {
  final String callId;
  final String callerId;
  final String receiverId;

  final String callerName;
  final String receiverName;

  final String? callerFullName;

  final String? callerProfileURL;
  final String? receiverProfileURL;

  final bool isCaller;

  final CallType callType;
  CallStatus status;
  DateTime? startTime;
  DateTime? endTime;

  CallModel({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.callerName,
    required this.receiverName,
    this.callerFullName,
    this.callerProfileURL,
    this.receiverProfileURL,
    this.isCaller = false,
    required this.callType,
    required this.status,
    this.startTime,
    this.endTime,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      callId: json['callId'] ?? '',
      callerId: json['callerId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      callerName: json['callerName'] ?? '',
      receiverName: json['receiverName'] ?? '',
      callerFullName: json['callerFullName'],
      callerProfileURL: json['callerProfileURL'],
      receiverProfileURL: json['receiverProfileURL'],
      isCaller: json['isCaller'] ?? false,
      callType: json['callType'] == 'video' ? CallType.video : CallType.audio,
      status: _parseStatus(json['status']),
      startTime:
          json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    );
  }

  static CallStatus _parseStatus(String? status) {
    switch (status) {
      case 'ringing':
        return CallStatus.ringing;
      case 'active':
        return CallStatus.active;
      case 'ended':
        return CallStatus.ended;
      case 'rejected':
        return CallStatus.rejected;
      case 'missed':
        return CallStatus.missed;
      default:
        return CallStatus.ringing;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'callerId': callerId,
      'receiverId': receiverId,
      'callerName': callerName,
      'receiverName': receiverName, // Added
      'callerFullName': callerFullName,
      'callerProfileURL': callerProfileURL,
      'receiverProfileURL': receiverProfileURL, // Added
      'isCaller': isCaller,
      'callType': callType == CallType.video ? 'video' : 'audio',
      'status': status.toString().split('.').last,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  CallModel copyWith({
    String? callId,
    String? callerId,
    String? receiverId,
    String? callerName,
    String? receiverName,
    String? callerFullName,
    String? callerProfileURL,
    String? receiverProfileURL,
    bool? isCaller,
    CallType? callType,
    CallStatus? status,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      callerName: callerName ?? this.callerName,
      receiverName: receiverName ?? this.receiverName,
      callerFullName: callerFullName ?? this.callerFullName,
      callerProfileURL: callerProfileURL ?? this.callerProfileURL,
      receiverProfileURL: receiverProfileURL ?? this.receiverProfileURL,
      isCaller: isCaller ?? this.isCaller,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

enum CallType {
  audio,
  video,
}

enum CallStatus {
  ringing,
  active,
  ended,
  rejected,
  missed,
}
