import 'dart:async';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel msg;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onCallTap;

  const MessageBubble({
    Key? key,
    required this.msg,
    this.onEdit,
    this.onDelete,
    this.onReply,
    this.onCallTap,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;

  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool get _isSending => widget.msg.status == 'sending';
  bool get _isDeleted => widget.msg.isDeleted ?? false;
  bool get _isEdited => widget.msg.isEdited ?? false;
  bool get _isLiked => widget.msg.isLiked ?? false;
  bool get _hasReply =>
      (widget.msg.repliedTo != null && widget.msg.repliedTo != "") &&
      (widget.msg.repliedMessage != null && widget.msg.repliedMessage != "");

  @override
  void initState() {
    super.initState();
    if (widget.msg.messageType == 'audio' && !_isDeleted) {
      _initializeAudio();
      _durationSub = _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted) setState(() => _duration = duration);
      });
      _positionSub = _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) setState(() => _position = position);
      });
      _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool wasSending = oldWidget.msg.status == 'sending';
    bool isNowSent = widget.msg.status != 'sending';
    bool urlChanged = oldWidget.msg.fileURL != widget.msg.fileURL;

    if ((wasSending && isNowSent) || urlChanged) {
      if (!mounted) return;
      setState(() {
        _position = Duration.zero;
        _isPlaying = false;
        _duration = Duration.zero;
      });
      _initializeAudio();
    }
  }

  Future<void> _initializeAudio() async {
    if (_isSending ||
        widget.msg.fileURL == null ||
        widget.msg.fileURL!.isEmpty) {
      return;
    }
    try {
      await _audioPlayer.setSourceUrl(widget.msg.fileURL!);
      final duration = await _audioPlayer.getDuration();
      if (duration != null && mounted) {
        setState(() => _duration = duration);
      }
    } catch (e) {
      print('Error loading audio duration: $e');
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_isSending) return;
    if (widget.msg.fileURL == null || widget.msg.fileURL!.isEmpty) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        if (!mounted) return;
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.play(UrlSource(widget.msg.fileURL!));
        if (!mounted) return;
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      print("Audio Playback Error: $e");
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final round = BorderRadius.circular(20).topLeft;
    final sharp = BorderRadius.circular(4).topLeft;
    final isMine = widget.msg.isMine;

    // Special handling for call messages
    if (widget.msg.messageType == 'call') {
      return _buildCallMessage();
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress:
                isMine ? _showMessageOptions : _showMessageOptionsPartner,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: round,
                  topRight: round,
                  bottomLeft: isMine ? round : sharp,
                  bottomRight: isMine ? sharp : round,
                ),
                gradient: isMine
                    ? LinearGradient(
                        colors: _isSending
                            ? [
                                AppColors.primary.withOpacity(0.6),
                                AppColors.accent.withOpacity(0.6)
                              ]
                            : [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMine ? null : AppColors.receivedMsgBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // REPLY SECTION
                  if (_hasReply && !_isDeleted) ...[
                    _buildReplySection(isMine),
                    const SizedBox(height: 8),
                  ],

                  // CONTENT SECTION
                  if (_isDeleted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.block,
                          size: 16,
                          color: isMine
                              ? AppColors.white.withOpacity(0.7)
                              : AppColors.textLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'This message was deleted',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: isMine
                                ? AppColors.white.withOpacity(0.7)
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Text Message
                    if (widget.msg.messageType == 'text' ||
                        widget.msg.messageType == null)
                      Text(
                        widget.msg.message ?? "",
                        style: TextStyle(
                          fontSize: 15,
                          color: isMine
                              ? AppColors.white
                                  .withOpacity(_isSending ? 0.9 : 1.0)
                              : AppColors.text,
                          height: 1.4,
                        ),
                      ),

                    // Image Message
                    if (widget.msg.messageType == 'image')
                      _isSending
                          ? _buildSendingImagePlaceholder()
                          : _buildNetworkImage(),

                    // Audio Message
                    if (widget.msg.messageType == 'audio')
                      _isSending
                          ? _buildSendingAudioRow()
                          : _buildInteractiveAudioRow(),
                  ],

                  const SizedBox(height: 4),

                  // STATUS / FOOTER
                  _isSending ? _buildSendingStatus() : _buildSentStatus(isMine),
                ],
              ),
            ),
          ),

          // LIKE HEART ICON
          if (_isLiked && !_isDeleted)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8, left: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // NEW: Build Call Message Widget
  Widget _buildCallMessage() {
    final isMine = widget.msg.isMine;
    final callData = _parseCallMessage(widget.msg.message ?? "");

    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: widget.onCallTap, // Allow tapping on call messages
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Call Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCallColor(callData['status']).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCallIcon(callData['status'], callData['isVideo']),
                  color: _getCallColor(callData['status']),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Call Details
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      callData['line1'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      callData['line2'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Parse call message format: "status-line1-line2"
  Map<String, dynamic> _parseCallMessage(String message) {
    final parts = message.split('-');
    if (parts.length >= 3) {
      return {
        'status': parts[0],
        'line1': parts[1],
        'line2': parts[2],
        'isVideo': parts[1].toLowerCase().contains('video'),
      };
    }
    return {
      'status': 'normal',
      'line1': 'Call',
      'line2': message,
      'isVideo': false,
    };
  }

  IconData _getCallIcon(String status, bool isVideo) {
    if (status.toLowerCase() == 'missed') {
      return Icons.phone_missed;
    } else if (status.toLowerCase() == 'declined') {
      return Icons.call_end;
    } else if (isVideo) {
      return Icons.videocam;
    }
    return Icons.phone;
  }

  Color _getCallColor(String status) {
    switch (status.toLowerCase()) {
      case 'missed':
        return Colors.red;
      case 'declined':
        return Colors.orange;
      case 'busy':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  // Reply Section Widget
  Widget _buildReplySection(bool isMine) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.black.withOpacity(0.15)
            : Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMine ? AppColors.white : AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (!isMine && widget.msg.repliedTo == "Me")
                ? 'Replied to himself'
                : 'Replied to ${widget.msg.repliedTo}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isMine
                  ? AppColors.white
                  : const Color.fromARGB(255, 193, 161, 248),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.msg.repliedMessage ?? '',
            style: TextStyle(
              fontSize: 13,
              color: isMine
                  ? AppColors.white.withOpacity(0.8)
                  : AppColors.text.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 200,
            height: 200,
            child: Image.network(
              widget.msg.fileURL ?? "",
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image,
                    size: 40, color: Colors.grey),
              ),
            ),
          ),
        ),
        if (widget.msg.message != null && widget.msg.message!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              widget.msg.message!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSendingImagePlaceholder() {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      ),
    );
  }

  Widget _buildInteractiveAudioRow() {
    final isMine = widget.msg.isMine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _toggleAudio,
              icon: Icon(
                _isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: isMine ? AppColors.white : AppColors.primary,
                size: 32,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0.0,
                    backgroundColor: isMine
                        ? AppColors.white.withOpacity(0.3)
                        : AppColors.textLight.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation(
                      isMine ? AppColors.white : AppColors.primary,
                    ),
                    minHeight: 3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / ${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isMine
                          ? AppColors.white.withOpacity(0.7)
                          : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (widget.msg.message != null && widget.msg.message!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              widget.msg.message!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isMine ? AppColors.white : AppColors.text,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSendingAudioRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_circle_filled,
          color: AppColors.white.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Text(
          'Audio message',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildSentStatus(bool isMine) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.msg.createdAt != null
              ? DateFormat('HH:mm').format(widget.msg.createdAt!.toLocal())
              : "",
          style: TextStyle(
            fontSize: 11,
            color:
                isMine ? AppColors.white.withOpacity(0.7) : AppColors.textLight,
          ),
        ),
        if (_isEdited && !_isDeleted) ...[
          const SizedBox(width: 4),
          Text(
            'Edited',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: isMine
                  ? AppColors.white.withOpacity(0.6)
                  : AppColors.textLight.withOpacity(0.8),
            ),
          ),
        ],
        if (isMine) ...[
          const SizedBox(width: 4),
          Icon(
            _getStatusIcon(widget.msg.status),
            size: 16,
            color: widget.msg.status == 'read'
                ? const Color(0xFF00E5FF)
                : AppColors.white.withOpacity(0.6),
          )
        ]
      ],
    );
  }

  Widget _buildSendingStatus() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sending...',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.access_time,
          size: 14,
          color: AppColors.white.withOpacity(0.7),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String? status) {
    if (status == 'read' || status == 'delivered')
      return Icons.done_all_rounded;
    if (status == 'sent') return Icons.check_rounded;
    return Icons.access_time_rounded;
  }

  void _showMessageOptions() {
    if (_isDeleted || _isSending) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              if (widget.msg.isMine)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Edit Message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onEdit?.call();
                  },
                ),
              if (widget.msg.isMine)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Delete Message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation();
                  },
                ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.reply_outlined,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Reply Message',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onReply?.call();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Message?',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'This message will be deleted for everyone.',
          style: TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptionsPartner() {
    if (_isDeleted || _isSending) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.reply_outlined,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Reply Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onReply?.call();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
