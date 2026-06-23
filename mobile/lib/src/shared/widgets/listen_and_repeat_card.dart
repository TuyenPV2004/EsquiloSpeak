
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ListenAndRepeatCard extends StatefulWidget {
  final String audioUrl;
  final String transcript;
  final VoidCallback onComplete;

  const ListenAndRepeatCard({
    super.key,
    required this.audioUrl,
    required this.transcript,
    required this.onComplete,
  });

  @override
  State<ListenAndRepeatCard> createState() => _ListenAndRepeatCardState();
}

class _ListenAndRepeatCardState extends State<ListenAndRepeatCard> {
  late AudioPlayer _samplePlayer;
  late AudioPlayer _recordingPlayer;
  late AudioRecorder _recorder;

  bool _isRecording = false;
  bool _isPlayingSample = false;
  bool _isPlayingRecording = false;
  String? _recordedFilePath;
  bool _hasPermission = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _samplePlayer = AudioPlayer();
    _recordingPlayer = AudioPlayer();
    _recorder = AudioRecorder();

    // Listen to play states to dynamically update UI
    _samplePlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingSample = state.playing && state.processingState != ProcessingState.completed;
        });
      }
    });

    _recordingPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingRecording = state.playing && state.processingState != ProcessingState.completed;
        });
      }
    });
  }

  @override
  void dispose() {
    // Safely stop and dispose all resources on destroy
    _stopAllActions();
    _samplePlayer.dispose();
    _recordingPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _stopAllActions() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    try {
      await _samplePlayer.stop();
    } catch (_) {}
    try {
      await _recordingPlayer.stop();
    } catch (_) {}
  }

  Future<void> _playSample() async {
    // Mutual Exclusion check
    if (_isRecording || _isPlayingRecording || widget.audioUrl.isEmpty) return;

    setState(() {
      _errorMessage = null;
    });

    try {
      await _recordingPlayer.stop();
      await _samplePlayer.stop();
      await _samplePlayer.setUrl(widget.audioUrl);
      await _samplePlayer.play();
    } catch (e) {
      setState(() {
        _errorMessage = "Không thể phát âm thanh mẫu. Bạn vẫn có thể đọc transcript.";
      });
    }
  }

  Future<void> _startRecording() async {
    // Mutual Exclusion check
    if (_isPlayingSample || _isPlayingRecording || _isRecording) return;

    setState(() {
      _errorMessage = null;
    });

    try {
      // 1. Request microphone permission
      _hasPermission = await _recorder.hasPermission();
      if (!_hasPermission) {
        setState(() {
          _errorMessage = "Chưa cấp quyền Microphone. Vui lòng bật trong Cài đặt thiết bị để luyện nói.";
        });
        return;
      }

      // 2. Start recording into a temporary file
      final tempDir = await getTemporaryDirectory();
      final path = p.join(tempDir.path, 'speaking_record_${DateTime.now().millisecondsSinceEpoch}.m4a');
      
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100, bitRate: 128000),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordedFilePath = path;
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
        _errorMessage = "Lỗi khởi động ghi âm: $e";
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _recordedFilePath = path;
        }
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
        _errorMessage = "Lỗi dừng ghi âm: $e";
      });
    }
  }

  Future<void> _playRecording() async {
    // Mutual Exclusion check
    if (_isRecording || _isPlayingSample || _recordedFilePath == null) return;

    setState(() {
      _errorMessage = null;
    });

    try {
      await _samplePlayer.stop();
      await _recordingPlayer.stop();
      await _recordingPlayer.setFilePath(_recordedFilePath!);
      await _recordingPlayer.play();
    } catch (e) {
      setState(() {
        _errorMessage = "Không thể phát lại bản ghi: $e";
      });
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _recordingPlayer.stop();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPlaySample = !_isRecording && !_isPlayingRecording;
    final canRecord = !_isPlayingSample && !_isPlayingRecording;
    final canPlayRecording = !_isRecording && !_isPlayingSample && _recordedFilePath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Instructions
        Center(
          child: Text(
            'Nghe câu mẫu, nhấn Mic để ghi âm và đọc theo:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),

        // 2. Sample Audio playback & Transcript display
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                IconButton(
                  icon: _isPlayingSample
                      ? const Icon(Icons.stop_circle_rounded, color: Colors.green)
                      : Icon(Icons.volume_up_rounded, color: canPlaySample ? theme.colorScheme.primary : Colors.grey),
                  iconSize: 40,
                  onPressed: canPlaySample
                      ? (_isPlayingSample ? () => _samplePlayer.stop() : _playSample)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.transcript,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nhấn loa để nghe phát âm mẫu',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 3. Microphone & Local Recording Control
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mic Record Button
            GestureDetector(
              onTap: canRecord
                  ? (_isRecording ? _stopRecording : _startRecording)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? Colors.red.withOpacity(0.2)
                      : (canRecord ? theme.colorScheme.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isRecording
                        ? Colors.red
                        : (canRecord ? theme.colorScheme.primary : Colors.grey.withOpacity(0.3)),
                    width: 3,
                  ),
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: _isRecording ? Colors.red : (canRecord ? theme.colorScheme.primary : Colors.grey),
                  size: 44,
                ),
              ),
            ),
            const SizedBox(width: 32),

            // Playback User Recording Button
            IconButton(
              icon: _isPlayingRecording
                  ? const Icon(Icons.stop_circle_outlined, color: Colors.orange)
                  : Icon(Icons.play_circle_fill_rounded,
                      color: canPlayRecording ? Colors.orange : Colors.grey.withOpacity(0.4)),
              iconSize: 56,
              onPressed: canPlayRecording
                  ? (_isPlayingRecording ? _stopPlayback : _playRecording)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _isRecording
                ? 'Đang ghi âm... Nhấn nút vuông để dừng.'
                : (_recordedFilePath != null ? 'Đã thu âm xong. Nhấn nút cam để nghe lại.' : 'Nhấn nút Mic để bắt đầu nói.'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _isRecording ? Colors.red : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 4. Error / Warning Banner
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.orange.shade900),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        const Spacer(),

        // 5. Done Button
        ElevatedButton(
          onPressed: _isRecording ? null : widget.onComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Tôi đã đọc xong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
