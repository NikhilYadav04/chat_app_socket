import 'package:chat_app/constants/colors.dart';
import 'package:flutter/material.dart';
// ALIAS IS REQUIRED: 'rec' alias prevents conflict with Dart's built-in 'Record' type
import 'package:record/record.dart' as rec;
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:ui';

class AudioRecordingDialog extends StatefulWidget {
  const AudioRecordingDialog({Key? key}) : super(key: key);

  @override
  State<AudioRecordingDialog> createState() => _AudioRecordingDialogState();
}

class _AudioRecordingDialogState extends State<AudioRecordingDialog> {
  // FIXED: Use the aliased 'rec.Record' class (Version 4 syntax)
  final rec.Record _recorder = rec.Record();

  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _audioPath;
  static const int maxDuration = 20;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        _audioPath =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // FIXED: Version 4 syntax
        // arguments are passed directly, not inside a RecordConfig object
        await _recorder.start(
          path: _audioPath,
          encoder: rec.AudioEncoder.aacLc, // Use the alias here too
          bitRate: 128000,
          samplingRate: 44100,
        );

        setState(() => _isRecording = true);

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration++);

          if (_recordDuration >= maxDuration) {
            _stopRecording();
          }
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    // FIXED: Version 4 .stop() returns String? (the path)
    final path = await _recorder.stop();

    setState(() => _isRecording = false);

    if (mounted) {
      if (path != null) {
        Navigator.of(context).pop(path);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _cancelRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    setState(() => _isRecording = false);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Recording Audio',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            // Animated recording indicator
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.accent.withOpacity(0.3)
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red : AppColors.primary,
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Timer
            Text(
              _formatDuration(_recordDuration),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDuration(maxDuration - _recordDuration)} remaining',
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar
            LinearProgressIndicator(
              value: _recordDuration / maxDuration,
              backgroundColor: AppColors.border.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                _recordDuration >= maxDuration * 0.8
                    ? Colors.red
                    : AppColors.accent,
              ),
            ),
            const SizedBox(height: 32),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel button
                TextButton.icon(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.close, color: AppColors.textDim),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textDim),
                  ),
                ),
                // Stop button
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : null,
                  icon: const Icon(Icons.stop, color: AppColors.white),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
