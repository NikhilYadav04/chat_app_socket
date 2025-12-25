import 'package:get/get.dart' as getx;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';

class WebRTCService extends getx.GetxService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  var isAudioEnabled = true.obs;
  var isVideoEnabled = true.obs;
  var isFrontCamera = true.obs;

  //* Ice Servers Configuration ( STUN / TURN )
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ]
  };

  final _sdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  var logger = Logger();

  //* Initialize renderers
  Future<void> initRenderers() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      logger.d("✅ Renderers initialized");
    } catch (e) {
      logger.e("❌ Error initializing renderers: $e");
    }
  }

  //* Dispose renderers
  Future<void> disposeRenderers() async {
    try {
      await localRenderer.dispose();
      await remoteRenderer.dispose();
      logger.d("✅ Renderers disposed");
    } catch (e) {
      logger.e("❌ Error disposing renderers: $e");
    }
  }

  //* Create local media stream (audio/video)
  Future<MediaStream> createLocalStream(bool isVideo) async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': isVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      };

      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;

      isAudioEnabled.value = true;
      isVideoEnabled.value = isVideo;

      logger.d("✅ Local stream created (Video: $isVideo)");

      return _localStream!;
    } catch (e) {
      logger.e("❌ Error creating local stream: $e");
      rethrow;
    }
  }

  //* Create peer connection
  Future<void> setupPeerConnection(
    Function(RTCSessionDescription) onOfferCreated,
    Function(RTCIceCandidate) onIceCandidate,
  ) async {
    try {
      _peerConnection =
          await createPeerConnection(_iceServers, _sdpConstraints);

      //* Add local stream tracks to peer connection
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }

      //* Handle remote stream
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        logger.d("📥 Received remote track: ${event.track.kind}");
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          remoteRenderer.srcObject = _remoteStream;
          logger.d("✅ Remote stream set to renderer");
        }
      };

      //* Handle ICE candidates
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate != null) {
          logger.d("🧊 ICE Candidate generated");
          onIceCandidate(candidate);
        }
      };

      //* Handle connection state changes
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        logger.d("🔗 Connection state: $state");
      };

      //* Handle ICE connection state
      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        logger.d("🧊 ICE Connection state: $state");
      };

      logger.d("✅ Peer connection created");
    } catch (e) {
      logger.e("❌ Error creating peer connection: $e");
      rethrow;
    }
  }

  //* Create and send offer (caller)
  Future<RTCSessionDescription> createOffer() async {
    try {
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      logger.d("✅ Offer created and set as local description");
      return offer;
    } catch (e) {
      logger.e("❌ Error creating offer: $e");
      rethrow;
    }
  }

  //* Handle incoming offer and create answer (receiver)
  Future<RTCSessionDescription> createAnswer(
      RTCSessionDescription offer) async {
    try {
      await _peerConnection!.setRemoteDescription(offer);
      logger.d("✅ Remote description set from offer");

      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      logger.d("✅ Answer created and set as local description");

      return answer;
    } catch (e) {
      logger.e("❌ Error creating answer: $e");
      rethrow;
    }
  }

  //* Handle incoming answer (caller)
  Future<void> setRemoteDescription(RTCSessionDescription answer) async {
    try {
      await _peerConnection!.setRemoteDescription(answer);
      logger.d("✅ Remote description set from answer");
    } catch (e) {
      logger.e("❌ Error setting remote description: $e");
      rethrow;
    }
  }

  //* Add ICE candidate
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    try {
      await _peerConnection!.addCandidate(candidate);
      logger.d("✅ ICE candidate added");
    } catch (e) {
      logger.e("❌ Error adding ICE candidate: $e");
    }
  }

  //* Toggle audio
  void toggleAudio() {
    try {
      if (_localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        if (audioTracks.isNotEmpty) {
          final audioTrack = audioTracks[0];
          audioTrack.enabled = !audioTrack.enabled;
          isAudioEnabled.value = audioTrack.enabled;
          logger.d("🎤 Audio ${audioTrack.enabled ? 'enabled' : 'disabled'}");
        }
      }
    } catch (e) {
      logger.e("❌ Error toggling audio: $e");
    }
  }

  //* Toggle video
  void toggleVideo() {
    try {
      if (_localStream != null) {
        final videoTracks = _localStream!.getVideoTracks();
        if (videoTracks.isNotEmpty) {
          final videoTrack = videoTracks[0];
          videoTrack.enabled = !videoTrack.enabled;
          isVideoEnabled.value = videoTrack.enabled;
          logger.d("📹 Video ${videoTrack.enabled ? 'enabled' : 'disabled'}");
        }
      }
    } catch (e) {
      logger.e("❌ Error toggling video: $e");
    }
  }

  //* Switch camera
  Future<void> switchCamera() async {
    try {
      if (_localStream != null) {
        final videoTracks = _localStream!.getVideoTracks();
        if (videoTracks.isNotEmpty) {
          final videoTrack = videoTracks[0];
          await Helper.switchCamera(videoTrack);
          isFrontCamera.value = !isFrontCamera.value;
          logger.d(
              "📷 Camera switched to ${isFrontCamera.value ? 'front' : 'back'}");
        }
      }
    } catch (e) {
      logger.e("❌ Error switching camera: $e");
    }
  }

  //* Close connection and cleanup
  Future<void> closeConnection() async {
    try {
      logger.d("🧹 Starting cleanup...");

      //* Stop all tracks
      _localStream?.getTracks().forEach((track) {
        track.stop();
        logger.d("⏹️ Stopped track: ${track.kind}");
      });

      _remoteStream?.getTracks().forEach((track) {
        track.stop();
      });

      //* Close peer connection
      await _peerConnection?.close();
      logger.d("🔌 Peer connection closed");

      //* Dispose streams
      await _localStream?.dispose();
      await _remoteStream?.dispose();

      //* Clear references
      _localStream = null;
      _remoteStream = null;
      _peerConnection = null;

      //* Reset renderer sources
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;

      //* Reset states
      isAudioEnabled.value = true;
      isVideoEnabled.value = true;

      logger.d("✅ Cleanup complete");
    } catch (e) {
      logger.e("❌ Error closing connection: $e");
    }
  }

  @override
  void onClose() {
    closeConnection();
    disposeRenderers();
    super.onClose();
  }
}
