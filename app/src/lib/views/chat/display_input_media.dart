//* Inline Image Preview Widget
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:flutter/material.dart';

class ImagePreviewInline extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const ImagePreviewInline({
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.path.split('/').last,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text(
                'Image',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDim, size: 20),
          onPressed: onRemove,
        ),
      ],
    );
  }
}

//* Inline Audio Preview Widget

class AudioPreviewInline extends StatefulWidget {
  final File file;
  final VoidCallback onRemove;

  const AudioPreviewInline({
    Key? key,
    required this.file,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<AudioPreviewInline> createState() => _AudioPreviewInlineState();
}

class _AudioPreviewInlineState extends State<AudioPreviewInline> {
  final AudioPlayer _audioPlayer = AudioPlayer(); 
  bool isPlaying = false;
  double progress = 0.0; 
  String durationText = "0:00";
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); 
    super.dispose();
  }

  Future<void> _initAudio() async {
    //* 1. Set the source so we can get the duration
    await _audioPlayer.setSource(DeviceFileSource(widget.file.path));

    //* 2. Listen to Duration changes
    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _totalDuration = d;
        durationText = _formatDuration(d);
      });
    });

    //* 3. Listen to Position changes (for the waveform progress)
    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _currentPosition = p;
        // Calculate percentage (0.0 to 1.0)
        progress = _totalDuration.inMilliseconds > 0
            ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
            : 0.0;
      });
    });

    //* 4. Listen to Player State (Playing/Paused/Completed)
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    //* 5. Reset when audio finishes
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        progress = 0.0;
        _currentPosition = Duration.zero;
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inMinutes}:$twoDigitSeconds";
  }

  Future<void> _togglePlay() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Waveform and duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform visualization
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: List.generate(30, (index) {
                      double height = 4 + (index % 5) * 3.0;
                    
                      bool isActive = progress > (index / 30);
                      
                      return Container(
                        width: 3,
                        height: height,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textDim.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),

                // Duration
                Text(
                  durationText,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Close button
          GestureDetector(
            onTap: () {
               _audioPlayer.stop(); // Stop audio before removing
               widget.onRemove();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.textDim.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.textDim,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}