import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/models/call_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Widget buildCallItem(CallModel call) {
  final isIncoming = !call.isCaller;
  final isMissed = call.status == CallStatus.missed;
  final isRejected = call.status == CallStatus.rejected;

  final displayName = call.isCaller
      ? (call.receiverName)
      : (call.callerFullName ?? call.callerName);

  final profileURL =
      call.isCaller ? call.receiverProfileURL : call.callerProfileURL;

  final hasProfileImage = profileURL != null && profileURL.isNotEmpty;

  final duration = _getCallDuration(call);
  final timeString = _formatCallTime(call.startTime ?? call.endTime);

  return Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isMissed
            ? AppColors.accent.withOpacity(0.3)
            : AppColors.border.withOpacity(0.5),
        width: 1,
      ),
      boxShadow: [
        if (isMissed)
          BoxShadow(
            color: AppColors.accent.withOpacity(0.05),
            blurRadius: 10,
          ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              //* Profile Avatar with Call Type Indicator
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: hasProfileImage
                          ? null
                          : const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: hasProfileImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: CachedNetworkImage(
                              imageUrl: profileURL,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.accent
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    displayName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.accent
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    displayName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              displayName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                  ),
                  // Call Type Badge
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        call.callType == CallType.video
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                        size: 12,
                        color: call.callType == CallType.video
                            ? AppColors.primary
                            : AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Call Direction Icon
                        Icon(
                          _getCallDirectionIcon(call),
                          size: 16,
                          color: isMissed || isRejected
                              ? AppColors.accent
                              : isIncoming
                                  ? Colors.green
                                  : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isMissed ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.text,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeString,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isMissed ? FontWeight.w600 : FontWeight.normal,
                            color: isMissed
                                ? AppColors.accent
                                : AppColors.textLight,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getCallStatusText(call),
                            style: TextStyle(
                              fontSize: 13,
                              color: isMissed || isRejected
                                  ? AppColors.accent
                                  : AppColors.textLight,
                              fontWeight: isMissed || isRejected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        if (duration != null && !isMissed && !isRejected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              duration,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Call Again Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    call.callType == CallType.video
                        ? Icons.videocam_rounded
                        : Icons.call_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    // Initiate call again
                  },
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _getCallStatusText(CallModel call) {
  if (call.status == CallStatus.missed) {
    return 'Missed call';
  } else if (call.status == CallStatus.rejected) {
    return 'Rejected';
  } else if (call.isCaller) {
    return 'Outgoing';
  } else {
    return 'Incoming';
  }
}

String? _getCallDuration(CallModel call) {
  if (call.startTime == null || call.endTime == null) {
    return null;
  }

  final duration = call.endTime!.difference(call.startTime!);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  } else {
    return '${seconds}s';
  }
}

String _formatCallTime(DateTime? time) {
  if (time == null) return "";

  final now = DateTime.now();
  final localTime = time.toLocal();

  if (localTime.day == now.day &&
      localTime.month == now.month &&
      localTime.year == now.year) {
    return DateFormat('HH:mm').format(localTime);
  }

  if (localTime.day == now.day - 1 &&
      localTime.month == now.month &&
      localTime.year == now.year) {
    return 'Yesterday';
  }

  if (now.difference(localTime).inDays < 7) {
    return DateFormat('EEE').format(localTime);
  }

  return DateFormat('MMM dd').format(localTime);
}

IconData _getCallDirectionIcon(CallModel call) {
  if (call.status == CallStatus.missed) {
    return Icons.call_missed_rounded;
  } else if (call.status == CallStatus.rejected) {
    return Icons.call_missed_outgoing_rounded;
  } else if (call.isCaller) {
    return Icons.call_made_rounded;
  } else {
    return Icons.call_received_rounded;
  }
}
