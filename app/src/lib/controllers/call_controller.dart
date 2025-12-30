import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/controllers/chat_controller.dart';
import 'package:chat_app/controllers/stats_controller.dart';
import 'package:chat_app/controllers/user_controller.dart';
import 'package:chat_app/helpers/date_formatter.dart';
import 'package:chat_app/helpers/permission_helpers.dart';
import 'package:chat_app/models/call_model.dart';
import 'package:chat_app/services/socket_service.dart';
import 'package:chat_app/services/webrtc_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

class CallController extends GetxController {
  final SocketService _socketService = Get.find<SocketService>();
  late final WebRTCService webrtcService;

  final _uuid = const Uuid();

  var currentCall = Rx<CallModel?>(null);
  var callDuration = 0.obs;
  var callRingingDuration = 0.obs;
  var isRinging = false.obs;

  //* To track how much time call is ringing
  Timer? _ringingTimer;

  void _startRingingTimer() {
    _ringingTimer?.cancel();

    _ringingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isRinging.value) {
        callRingingDuration.value++;

        //* If 30 seconds pass without the call being accepted
        if (callRingingDuration.value >= 30) {
          stopAllSounds();
          timer.cancel();
          sendMissCall();
        }
      } else {
        //* If isRinging becomes false (call accepted), stop this timer
        timer.cancel();
      }
    });
  }

  //* To play audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  //* Play Sound
  Future<void> _playSound(String assetPath, {bool loop = false}) async {
    await _audioPlayer.stop();
    await _audioPlayer
        .setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
    await _audioPlayer.play(AssetSource(assetPath));
  }

  void stopAllSounds() {
    _audioPlayer.stop();
  }

  String? myUserId;
  String? myName;

  @override
  void onInit() {
    super.onInit();
  }

  //* Send Message ( Call Info in Chat )
  Future<void> sendCallMessage(
      {required String callStatus,
      required String duration,
      required String callStartTime,
      required bool isVideo}) async {
    String line1 = "";
    String line2 = "";

    final UserController _userController = Get.find<UserController>();
    String callerName = _userController.user.value?.fullName ?? "Person";

    switch (callStatus.toLowerCase()) {
      case 'missed':
        line1 = "Missed call from $callerName";
        line2 = "at $callStartTime";
        break;
      case 'busy':
        line1 = "Line Busy";
        line2 = "Called $callerName at $callStartTime";
        break;
      case 'declined':
        line1 = "Call Declined";
        line2 = "Attempted at $callStartTime";
        break;
      case 'normal':
        line1 = isVideo ? "Video Call" : "Voice Call";
        line2 = "Duration: $duration s";
        break;
      default:
        line1 = "Call Ended";
        line2 = callStartTime;
    }

    String message = "$callStatus-$line1-$line2";

    final ChatController _chatController = Get.find<ChatController>();

    _chatController.sendMessage("", "", messageText: message);
  }

  //* Initialize controller
  void setupController(String userId) {
    final AuthController _authController = Get.find<AuthController>();
    myUserId = _authController.myUserId;

    //* Initialize WebRTC service
    if (!Get.isRegistered<WebRTCService>()) {
      webrtcService = Get.put(WebRTCService());
    } else {
      webrtcService = Get.find<WebRTCService>();
    }

    _setupCallListeners();
    webrtcService.initRenderers();
  }

  //* Setup socket listeners for call events
  void _setupCallListeners() {
    final socket = _socketService.socket;

    //* Incoming call
    socket.on('incoming_call', (data) {
      _handleIncomingCall(data);
    });

    //* Call accepted
    socket.on('call_accepted', (data) {
      _handleCallAccepted(data);
    });

    //* Call rejected
    socket.on('call_rejected', (data) {
      _handleCallRejected(data);
    });

    //* Call ended
    socket.on('call_ended', (data) {
      _handleCallEnded(data);
    });

    //* Call failed
    socket.on('call_failed', (data) {
      _handleCallFailed(data);
    });

    //* WebRTC offer
    socket.on('webrtc_offer', (data) {
      _handleWebRTCOffer(data);
    });

    //* WebRTC answer
    socket.on('webrtc_answer', (data) {
      _handleWebRTCAnswer(data);
    });

    //* ICE candidate
    socket.on('webrtc_ice_candidate', (data) {
      _handleICECandidate(data);
    });

    //* Media toggled
    socket.on('call_media_toggled', (data) {
      _handleMediaToggled(data);
    });
  }

  //* Call Methods

  //* < ----------------------------------------------------->

  //* Miss call
  Future<void> sendMissCall() async {
    try {
      if (currentCall.value == null) return;

      callRingingDuration.value = 0;
      var logger = Logger();
      logger.d("Missed call: ${currentCall.value!.callId}");

      _socketService.socket.emit('call_missed', {
        'callId': currentCall.value!.callId,
      });

      final statsProvider = Get.find<StatsController>();
      statsProvider.edit(
        currentCall.value!.callId,
        status: CallStatus.missed,
        startDate: DateTime.now(),
      );
    } catch (e) {
      Logger().e("Error sending miss call status: $e");
    }
  }

  //* Initiate a call
  Future<void> initiateCall({
    required String receiverId,
    required String receiverName,
    required String receiverProfileURL,
    required CallType callType,
  }) async {
    try {
      var logger = Logger();
      logger.d("Initiating call to $receiverName");

      //* 1. Check and request permissions
      bool hasPermissions = await PermissionHelper.hasCallPermissions(
        isVideo: callType == CallType.video,
      );

      if (!hasPermissions) {
        bool granted = await PermissionHelper.requestCallPermissions(
          isVideo: callType == CallType.video,
        );

        if (!granted) {
          Get.snackbar(
            'Permissions Denied',
            'Camera and microphone permissions are required to make calls',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      final UserController _userController = Get.find<UserController>();
      final callerName = _userController.user.value!.fullName;

      //* Create local stream
      await webrtcService.createLocalStream(callType == CallType.video);

      final String generatedCallId = _uuid.v4();

      //* Create call model
      final call = CallModel(
        callId: generatedCallId,
        callerId: myUserId!,
        receiverId: receiverId,
        callerName: callerName!,
        receiverName: receiverName,
        receiverProfileURL: receiverProfileURL,
        callType: callType,
        status: CallStatus.ringing,
        isCaller: true,
        startTime: DateTime.now(),
      );

      currentCall.value = call;

      isRinging.value = true;

      //* Emit call initiate event
      _socketService.socket.emit('call_initiate', {
        'callId': generatedCallId,
        'callerId': myUserId,
        'receiverId': receiverId,
        'callType': callType == CallType.video ? 'video' : 'audio',
        'callerName': callerName,
        'receiverName': receiverName,
        'receiverProfileURL': receiverProfileURL
      });

      //* add to call history
      final statsProvider = Get.find<StatsController>();
      statsProvider.add(call);

      _startRingingTimer();
      _playSound("sound/ring.wav", loop: true);

      //* Navigate to call screen
      Get.toNamed('/call', arguments: {
        'call': call,
        'isCaller': true,
        'receiverName': receiverName,
        'receiverProfileURL': receiverProfileURL
      });
    } catch (e) {
      Logger().e("Error initiating call: $e");
      Get.snackbar('Error', 'Failed to initiate call');
    }
  }

  //* Handling incoming call
  void _handleIncomingCall(Map<String, dynamic> data) {
    var logger = Logger();
    logger.d("Incoming call: $data");

    _playSound("sound/ringtone.wav", loop: true);

    if (currentCall.value != null) return;

    final call = CallModel(
      callId: data['callId'],
      callerId: data['callerId'],
      receiverId: myUserId!,
      callerName: data['callerName'] ?? 'Unknown',
      callerFullName: data['callerFullName'],
      callerProfileURL: data['callerProfileURL'],
      callType: data['callType'] == 'video' ? CallType.video : CallType.audio,
      receiverName: data['receiverName'],
      receiverProfileURL: data['receiverProfileURL'],
      status: CallStatus.ringing,
    );

    currentCall.value = call;
    isRinging.value = true;

    final statsProvider = Get.find<StatsController>();
    statsProvider.add(call);

    //* Navigate to incoming call screen
    Get.toNamed('/incoming-call', arguments: {
      'call': call,
    });
  }

  //* Accept incoming call
  Future<void> acceptCall({
    required String receiverName,
    required String receiverProfileURL,
  }) async {
    try {
      stopAllSounds();

      if (currentCall.value == null) return;

      var logger = Logger();
      logger.d("Accepting call: ${currentCall.value!.callId}");

      //* 1. Check and request permissions
      bool hasPermissions = await PermissionHelper.hasCallPermissions(
        isVideo: currentCall.value!.callType == CallType.video,
      );

      if (!hasPermissions) {
        bool granted = await PermissionHelper.requestCallPermissions(
          isVideo: currentCall.value!.callType == CallType.video,
        );

        if (!granted) {
          rejectCall(reason: 'Permissions denied');
          return;
        }
      }

      //* Create local stream
      await webrtcService
          .createLocalStream(currentCall.value!.callType == CallType.video);

      //* Setup peer connection
      await webrtcService.setupPeerConnection(
        (offer) {
          // This is not used for receiver
        },
        (candidate) {
          _sendICECandidate(candidate);
        },
      );

      //* Emit call accept event
      _socketService.socket.emit('call_accept', {
        'callId': currentCall.value!.callId,
        'receiverId': myUserId,
      });

      //* Update call status
      currentCall.value = currentCall.value!.copyWith(
        status: CallStatus.active,
        startTime: DateTime.now(),
      );

      final statsProvider = Get.find<StatsController>();
      statsProvider.edit(currentCall.value!.callId,
          status: CallStatus.active, startDate: DateTime.now());

      _startCallTimer();

      isRinging.value = false;

      //* Start call duration timer
      _startCallTimer();

      //* Navigate to call screen
      Get.offNamed('/call', arguments: {
        'call': currentCall.value,
        'isCaller': false,
        'receiverName': receiverName,
        'receiverProfileURL': receiverProfileURL
      });
    } catch (e) {
      Logger().e("Error accepting call: $e");
      Get.snackbar('Error', 'Failed to accept call');
    }
  }

  //* Reject incoming call
  void rejectCall({String reason = 'Call declined', bool isVideo = false}) {
    stopAllSounds();

    if (currentCall.value == null) return;

    var logger = Logger();
    logger.d("Rejecting call: ${currentCall.value!.callId}");

    _socketService.socket.emit('call_reject', {
      'callId': currentCall.value!.callId,
      'receiverId': myUserId,
      'reason': reason,
    });

    final statsProvider = Get.find<StatsController>();
    statsProvider.edit(currentCall.value!.callId,
        status: CallStatus.rejected, endDate: DateTime.now());

    //* add message
    sendCallMessage(
        callStatus: "declined",
        duration: callDuration.value.toString(),
        callStartTime: formatMongoDate(DateTime.now()),
        isVideo: isVideo);

    Future.delayed(const Duration(milliseconds: 100), () {
      _cleanupCall();
      Get.back();
    });
  }

  //* End active call
  void endCall(bool isVideo) {
    stopAllSounds();

    if (currentCall.value == null) return;

    var logger = Logger();
    logger.d("Ending call: ${currentCall.value!.callId}");

    if (callDuration.value == 0) {
      _socketService.socket.emit('call_end', {
        'callId': currentCall.value!.callId,
        'status': 'isRinging',
        'userId': myUserId,
      });
    } else {
      _socketService.socket.emit('call_end', {
        'callId': currentCall.value!.callId,
        'userId': myUserId,
      });
    }

    //* add message
    sendCallMessage(
        callStatus: "normal",
        duration: callDuration.value.toString(),
        callStartTime: "",
        isVideo: isVideo);

    final statsProvider = Get.find<StatsController>();
    statsProvider.edit(currentCall.value!.callId,
        status: CallStatus.ended, endDate: DateTime.now());

    Future.delayed(const Duration(milliseconds: 100), () {
      _cleanupCall();
      if (Get.currentRoute == '/call') {
        Get.back();
      }
    });
  }

  //* Handle call accepted (caller side)
  Future<void> _handleCallAccepted(Map<String, dynamic> data) async {
    var logger = Logger();
    logger.d("Call accepted: $data");

    stopAllSounds();

    //* Setup peer connection
    await webrtcService.setupPeerConnection(
      (offer) {
        _sendOffer(offer);
      },
      (candidate) {
        _sendICECandidate(candidate);
      },
    );

    //* Create and send offer
    final offer = await webrtcService.createOffer();
    _sendOffer(offer);

    //* Update call status
    currentCall.value = currentCall.value!.copyWith(
      status: CallStatus.active,
      startTime: DateTime.now(),
    );

    final statsProvider = Get.find<StatsController>();

    statsProvider.edit(
      currentCall.value!.callId,
      status: CallStatus.active,
      startDate: DateTime.now(),
    );

    isRinging.value = false;

    //* Start call duration timer
    _startCallTimer();
  }

  //* Handle call rejected
  void _handleCallRejected(Map<String, dynamic> data) async {
    var logger = Logger();
    logger.d("Call rejected: $data");

    stopAllSounds();

    Get.snackbar(
      'Call Declined',
      data['reason'] ?? 'The user declined your call',
    );

    try {
      // 2. Wrap cleanup in try/catch so it doesn't "freeze" the app
      await Future.delayed(Duration(seconds: 2));

      final statsProvider = Get.find<StatsController>();
      statsProvider.edit(
        currentCall.value!.callId,
        status: CallStatus.rejected,
        endDate: DateTime.now(),
      );

      await _cleanupCall();
    } catch (e) {
      logger.e("Cleanup error during failure: $e");
    } finally {
      if (Get.currentRoute == '/call' || Get.currentRoute == '/incoming-call') {
        Get.back(closeOverlays: true);
      }
    }
  }

  //* Handle call ended
  void _handleCallEnded(Map<String, dynamic> data) async {
    var logger = Logger();
    logger.d("Call ended: $data");

    stopAllSounds();

    try {
      final String status = data["status"] ?? "";

      if (status == "busy") {
        await sendCallMessage(
            callStatus: "busy",
            duration: "",
            callStartTime: formatMongoDate(data["startedAt"]).toString(),
            isVideo: false);

        final statsProvider = Get.find<StatsController>();
        statsProvider.edit(
          currentCall.value!.callId,
          status: CallStatus.missed,
          startDate: DateTime.now(),
        );

        _playSound("sound/busy.mp3");

        await Future.delayed(Duration(seconds: 3));

        stopAllSounds();
      } else if (status == "missed") {
        await sendCallMessage(
            callStatus: "missed",
            duration: "",
            callStartTime: formatMongoDate(data["startedAt"]).toString(),
            isVideo: false);

        final statsProvider = Get.find<StatsController>();
        statsProvider.edit(
          currentCall.value!.callId,
          status: CallStatus.missed,
          startDate: DateTime.now(),
        );

        _playSound("sound/miss.mp3");

        await Future.delayed(Duration(seconds: 10));

        stopAllSounds();
      } else {
        // await sendCallMessage(
        //     callStatus: "normal",
        //     duration: "",
        //     callStartTime: formatMongoDate(data["startedAt"]).toString(),
        //     isVideo: false);

        final statsProvider = Get.find<StatsController>();
        statsProvider.edit(
          currentCall.value!.callId,
          status: CallStatus.ended,
          startDate: DateTime.now(),
        );
      }

      await Future.delayed(Duration(seconds: 2));

      await _cleanupCall();
    } catch (e) {
      logger.e("Cleanup error during failure: $e");
    } finally {
      if (Get.currentRoute == '/call' || Get.currentRoute == '/incoming-call') {
        Get.back(closeOverlays: true);
      }
    }
  }

  //* Handle call failed
  void _handleCallFailed(Map<String, dynamic> data) async {
    var logger = Logger();
    logger.e("Call failed: $data");

    stopAllSounds();

    Get.snackbar(
      'Call Failed',
      data['reason'] ?? 'Unable to connect',
    );

    try {
      // 2. Wrap cleanup in try/catch so it doesn't "freeze" the app
      await Future.delayed(Duration(seconds: 2));

      await _cleanupCall();
    } catch (e) {
      logger.e("Cleanup error during failure: $e");
    } finally {
      if (Get.currentRoute == '/call' || Get.currentRoute == '/incoming-call') {
        // Get.off(() => ChatDetailScreen());
        Get.back(closeOverlays: true);
      }
    }
  }

  //* Handle WebRTC offer
  Future<void> _handleWebRTCOffer(Map<String, dynamic> data) async {
    var logger = Logger();
    logger.d("Received WebRTC offer");

    final offer = RTCSessionDescription(
      data['offer']['sdp'],
      data['offer']['type'],
    );

    //* Create answer
    final answer = await webrtcService.createAnswer(offer);

    //* Send answer
    _sendAnswer(answer);
  }

  //* Handle WebRTC answer
  Future<void> _handleWebRTCAnswer(Map<String, dynamic> data) async {
    var logger = Logger();
    logger.d("Received WebRTC answer");

    final answer = RTCSessionDescription(
      data['answer']['sdp'],
      data['answer']['type'],
    );

    await webrtcService.setRemoteDescription(answer);
  }

  //* Handle ICE candidate
  Future<void> _handleICECandidate(Map<String, dynamic> data) async {
    var logger = Logger();
    logger.d("Received ICE candidate");

    final candidate = RTCIceCandidate(
      data['candidate']['candidate'],
      data['candidate']['sdpMid'],
      data['candidate']['sdpMLineIndex'],
    );

    await webrtcService.addIceCandidate(candidate);
  }

  //* Handle media toggled
  void _handleMediaToggled(Map<String, dynamic> data) {
    var logger = Logger();
    logger.d("Media toggled: $data");

    // Update UI to show remote user muted/unmuted their mic or camera
    Get.snackbar(
      'Media Update',
      '${data['mediaType']} ${data['enabled'] ? 'enabled' : 'disabled'}',
      duration: const Duration(seconds: 2),
    );
  }

  //* Send WebRTC offer
  void _sendOffer(RTCSessionDescription offer) {
    _socketService.socket.emit('webrtc_offer', {
      'callId': currentCall.value!.callId,
      'offer': offer.toMap(),
      'callerId': myUserId,
      'receiverId': currentCall.value!.receiverId,
    });
  }

  //* Send WebRTC answer
  void _sendAnswer(RTCSessionDescription answer) {
    _socketService.socket.emit('webrtc_answer', {
      'callId': currentCall.value!.callId,
      'answer': answer.toMap(),
      'receiverId': myUserId,
      'callerId': currentCall.value!.callerId,
    });
  }

  //* Send ICE candidate
  void _sendICECandidate(RTCIceCandidate candidate) {
    _socketService.socket.emit('webrtc_ice_candidate', {
      'callId': currentCall.value!.callId,
      'candidate': candidate.toMap(),
      'fromUserId': myUserId,
      'toUserId': currentCall.value!.callerId == myUserId
          ? currentCall.value!.receiverId
          : currentCall.value!.callerId,
    });
  }

  //* Toggle audio
  void toggleAudio() {
    webrtcService.toggleAudio();

    _socketService.socket.emit('call_toggle_media', {
      'callId': currentCall.value!.callId,
      'userId': myUserId,
      'mediaType': 'audio',
      'enabled': webrtcService.isAudioEnabled.value,
    });
  }

  //* Toggle video
  void toggleVideo() {
    webrtcService.toggleVideo();

    _socketService.socket.emit('call_toggle_media', {
      'callId': currentCall.value!.callId,
      'userId': myUserId,
      'mediaType': 'video',
      'enabled': webrtcService.isVideoEnabled.value,
    });
  }

  //* Switch camera
  void switchCamera() {
    webrtcService.switchCamera();
  }

  //* Start call duration timer
  Timer? _timer;

  void _startCallTimer() {
    _timer?.cancel(); // Cancel any existing timer
    callDuration.value = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentCall.value?.status == CallStatus.active) {
        callDuration.value++;
      } else {
        timer.cancel();
      }
    });
  }

  //* Cleanup call resources
  Future<void> _cleanupCall() async {
    await webrtcService.closeConnection();
    currentCall.value = null;
    callDuration.value = 0;
    isRinging.value = false;
  }

  @override
  void onClose() {
    webrtcService.onClose();
    super.onClose();
    currentCall.value = null;
    callDuration.value = 0;
    isRinging.value = false;
  }
}
