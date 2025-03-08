import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:practice_my_accent/l10n/app_localizations.dart';
import 'package:practice_my_accent/services/audio_service.dart';
import 'package:practice_my_accent/services/gemini_service.dart';
import 'package:practice_my_accent/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? audioPath;
  final String? translationKey;
  final Map<String, String>? translationParams;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.audioPath,
    this.translationKey,
    this.translationParams,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert ChatMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'audioPath': audioPath,
      'translationKey': translationKey,
      'translationParams': translationParams,
    };
  }

  // Create ChatMessage from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      audioPath: json['audioPath'] as String?,
      translationKey: json['translationKey'] as String?,
      translationParams: json['translationParams'] != null 
          ? Map<String, String>.from(json['translationParams']) 
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GeminiService _geminiService = GeminiService();
  final AudioService _audioService = AudioService();
  final StorageService _storageService = StorageService();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isPlaying = false;
  StreamSubscription? _textSubscription;
  StreamSubscription? _audioSubscription;
  StreamSubscription? _vadSubscription;

  // For VAD (Voice Activity Detection)
  Timer? _silenceTimer;
  bool _isSpeaking = false;
  int _silenceCount = 0;
  static const int _silenceThreshold =
      8; // Number of silent chunks to trigger segment end (reduced for better responsiveness)
  static const double _audioThreshold =
      0.015; // Threshold for audio level to detect speech (slightly reduced)

  // For segment recording
  bool _isRecordingSegment = false;
  String? _currentSegmentPath;
  List<Uint8List> _currentSegmentData = [];
  int _segmentCount = 0;

  // For collecting complete audio response data
  final List<Uint8List> _currentResponseChunks = [];
  bool _isCollectingResponse = false;
  Timer? _responseCollectionTimer;

  // For playing audio
  String? _currentPlayingPath;

  @override
  void initState() {
    super.initState();
    _audioService.init();
    _loadSavedMessages();
    _storageService.getApiKey('google').then((apiKey) {
      _storageService.getAccent().then((accentCode) {
        debugPrint('accentCode: $accentCode');
        debugPrint('apiKey: $apiKey');
        if (accentCode != null && apiKey != null) {
          debugPrint('Connecting to Gemini');
          _geminiService.connect(apiKey, accentCode);
        }
      });
    });
    _geminiService.connectionStream.listen((isConnected) {
      debugPrint('isConnected: $isConnected');
      setState(() {
        _isConnected = isConnected;
      });
    });

    _geminiService.audioResponses.listen((audioData) {
      debugPrint('Received audio data: ${audioData.length} bytes');
      _collectAudioChunk(audioData);
    });

    // Listen to playback status
    _audioService.playbackStatus.listen((isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
    });
  }

  // Load saved messages from storage
  Future<void> _loadSavedMessages() async {
    try {
      final savedMessages = await _storageService.getChatMessages();
      if (savedMessages.isNotEmpty) {
        setState(() {
          _messages.addAll(
            savedMessages.map((json) => ChatMessage.fromJson(json)).toList(),
          );
        });

        // Scroll to bottom after messages are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved messages: $e');
    }
  }

  // Save messages to storage
  Future<void> _saveMessages() async {
    try {
      final messagesToSave =
          _messages.map((message) => message.toJson()).toList();
      await _storageService.saveChatMessages(messagesToSave);
    } catch (e) {
      debugPrint('Error saving messages: $e');
    }
  }

  // Collect audio chunks
  void _collectAudioChunk(Uint8List audioData) {
    // Start collecting new response
    if (!_isCollectingResponse) {
      _isCollectingResponse = true;
      _currentResponseChunks.clear();
    }

    // Add new audio chunk
    _currentResponseChunks.add(audioData);

    // Reset timer
    _responseCollectionTimer?.cancel();
    _responseCollectionTimer = Timer(const Duration(milliseconds: 500), () {
      // When timer triggers, consider the current response complete
      _finalizeAndPlayResponse();
    });
  }

  // Finalize response collection and play
  Future<void> _finalizeAndPlayResponse() async {
    if (_currentResponseChunks.isEmpty) return;

    try {
      // Merge all audio chunks
      final totalLength = _currentResponseChunks.fold<int>(
        0,
        (sum, chunk) => sum + chunk.length,
      );

      final mergedAudio = Uint8List(totalLength);
      int offset = 0;

      for (final chunk in _currentResponseChunks) {
        mergedAudio.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      // Save merged audio to file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'ai_response_${DateTime.now().millisecondsSinceEpoch}.wav';
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(mergedAudio);

      // Add AI message to chat using translation key
      if (mounted) {
        _addMessage(
          'AI voice message', // Default text as fallback
          false,
          audioPath: filePath,
          translationKey: 'ai_voice_message',
        );
      }

      // Play complete audio response
      if (!_isPlaying) {
        await _audioService.playAudio(filePath, 24000);
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('Error processing audio response: $e');
    } finally {
      // Reset state
      _isCollectingResponse = false;
      _currentResponseChunks.clear();
    }
  }

  void _addMessage(String text, bool isUser, {String? audioPath, String? translationKey, Map<String, String>? translationParams}) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: isUser,
          audioPath: audioPath,
          translationKey: translationKey,
          translationParams: translationParams,
        ),
      );
    });

    // Save messages after adding a new one
    _saveMessages();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    if (_isRecording) {
      await _stopRecording();
      return;
    }

    // If currently playing, stop playback first
    if (_isPlaying) {
      await _stopPlaying();
    }

    // Reset VAD variables
    _isSpeaking = false;
    _silenceCount = 0;
    _segmentCount = 0;
    _currentSegmentData.clear();
    _isRecordingSegment = false;

    await _audioService.startStreamPlayer();

    // Start VAD monitoring
    _vadSubscription = _audioService.audioLevelStream.listen((level) {
      _detectVoiceActivity(level);
    });

    await _audioService.startRecordingStream((data) {
      // Add data to current segment if we're recording a segment
      if (_isRecordingSegment) {
        _currentSegmentData.add(data);
      }

      // Always send data to Gemini for real-time processing
      _geminiService.sendAudio(data);
    }, 'user');

    setState(() {
      _isRecording = true;
    });

    // Start silence timer for segment detection
    _silenceTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_isRecording) {
        if (_isSpeaking && _silenceCount >= _silenceThreshold) {
          // End of segment detected
          if (_isRecordingSegment && _currentSegmentData.isNotEmpty) {
            _finalizeSegment();
          }
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _detectVoiceActivity(double level) {
    if (!_isRecording) return;

    if (level > _audioThreshold) {
      // Voice detected
      if (!_isSpeaking) {
        debugPrint('VAD: Speech started, level: $level');
        _isSpeaking = true;
        // Start a new segment if not already recording one
        if (!_isRecordingSegment) {
          _startNewSegment();
        }
      }
      _silenceCount = 0;
    } else {
      // Silence detected
      if (_isSpeaking) {
        _silenceCount++;
        if (_silenceCount % 2 == 0) {
          // Only log every other count to reduce spam
          debugPrint(
            'VAD: Silence detected, count: $_silenceCount / $_silenceThreshold',
          );
        }
      }
    }
  }

  void _startNewSegment() {
    _isRecordingSegment = true;
    _currentSegmentData = [];
    _segmentCount++;
    debugPrint('Starting new segment: $_segmentCount');
  }

  Future<void> _finalizeSegment() async {
    if (_currentSegmentData.isEmpty) return;

    try {
      debugPrint('Finalizing segment: $_segmentCount');

      // Merge all segment data
      final totalLength = _currentSegmentData.fold<int>(
        0,
        (sum, chunk) => sum + chunk.length,
      );

      if (totalLength == 0) return;

      final mergedAudio = Uint8List(totalLength);
      int offset = 0;

      for (final chunk in _currentSegmentData) {
        mergedAudio.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      // Save segment to file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'segment_${DateTime.now().millisecondsSinceEpoch}.pcm';
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(mergedAudio);

      // For PCM files, we need to remember they're PCM format
      _currentSegmentPath = filePath;

      // Add user message with audio using translation key
      if (mounted) {
        // Use translation key and parameters instead of directly using translated text
        _addMessage(
          'Voice segment $_segmentCount', // Default text as fallback
          true,
          audioPath: _currentSegmentPath,
          translationKey: 'voice_segment_with_number',
          translationParams: {'number': _segmentCount.toString()},
        );
      }

      // Reset for next segment
      _isRecordingSegment = false;
      _currentSegmentData = [];
      _silenceCount = 0;

      // Reset speaking state to allow detection of next segment
      _isSpeaking = false;

      debugPrint('Segment $_segmentCount finalized and ready for next segment');
    } catch (e) {
      debugPrint('Error finalizing segment: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    // Finalize current segment if any
    if (_isRecordingSegment && _currentSegmentData.isNotEmpty) {
      await _finalizeSegment();
    }

    // Cancel VAD monitoring
    _vadSubscription?.cancel();
    _silenceTimer?.cancel();

    final filePath = await _audioService.stopRecorder();
    debugPrint('Final recording path: $filePath');
    setState(() {
      _isRecording = false;
      _isProcessing = false;
    });
  }

  Future<void> _playMessage(ChatMessage message) async {
    try {
      if (message.audioPath == null) return;
      setState(() {
        _isPlaying = true;
        _currentPlayingPath = message.audioPath;
      });

      // Determine if this is a PCM file or WAV file based on extension
      final bool isPcm = message.audioPath!.endsWith('.pcm');
      final int sampleRate = isPcm ? 16000 : (message.isUser ? 16000 : 24000);

      // Play audio file
      await _audioService.playAudio(message.audioPath!, sampleRate);
      _audioSubscription = _audioService.playbackStatus.listen((isPlaying) {
        debugPrint('isPlaying: $isPlaying');
        setState(() {
          _isPlaying = isPlaying;
        });
      });
    } catch (e) {
      debugPrint('Error playing message audio: $e');
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _stopPlaying() async {
    if (!_isPlaying) return;

    await _audioService.stopPlayer();

    setState(() {
      _isPlaying = false;
      _currentPlayingPath = null;
    });
  }

  @override
  void dispose() {
    debugPrint('ChatScreen dispose');
    // Save messages before disposing
    _saveMessages();

    _geminiService.disconnect();
    _textSubscription?.cancel();
    _audioSubscription?.cancel();
    _vadSubscription?.cancel();
    _silenceTimer?.cancel();
    _responseCollectionTimer?.cancel();
    _audioService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.translate('chat_with_gemini')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          // Clear chat button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: appLocalizations.translate('clear_chat'),
            onPressed: _messages.isEmpty ? null : _showClearChatDialog,
          ),
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color:
                      _isConnected
                          ? Colors.green
                          : _isConnecting
                          ? Colors.amber
                          : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        // Theme background color
        decoration: BoxDecoration(
          color: theme.colorScheme.background.withOpacity(0.95),
        ),
        child: Column(
          children: [
            // Chat message list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message, theme);
                },
              ),
            ),

            // Bottom recording button area
            Container(
              width: double.infinity, // Ensure full width
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Center align
                children: [
                  // Recording button - full width button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _startRecording();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isRecording
                                ? theme.colorScheme.errorContainer
                                : theme.colorScheme.primaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color:
                                _isRecording
                                    ? theme.colorScheme.onErrorContainer
                                    : theme.colorScheme.onPrimaryContainer,
                            size: 24.0,
                          ),
                          const SizedBox(width: 12.0),
                          Text(
                            _isRecording
                                ? appLocalizations.translate(
                                  'stop_talking_to_teacher',
                                )
                                : appLocalizations.translate(
                                  'start_talking_to_teacher',
                                ),
                            style: TextStyle(
                              color:
                                  _isRecording
                                      ? theme.colorScheme.onErrorContainer
                                      : theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Status text below the button with consistent padding
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      _isRecording
                          ? appLocalizations.translate(
                            _isSpeaking
                                ? 'segment_recording'
                                : _isRecordingSegment
                                ? 'segment_paused'
                                : 'recording_in_progress',
                          )
                          : _isProcessing
                          ? appLocalizations.translate('processing')
                          : _isPlaying
                          ? appLocalizations.translate('playing')
                          : ' ', // Space instead of empty string to ensure height
                      style: TextStyle(
                        color:
                            _isRecording
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                        fontSize: 13.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    final isUser = message.isUser;
    final hasAudio = message.audioPath != null;
    final isPlayingThisMessage =
        _isPlaying && _currentPlayingPath == message.audioPath;
    
    // Get localization instance
    final appLocalizations = AppLocalizations.of(context);
    
    // If there's a translation key, use the translated text
    String displayText = message.text;
    if (message.translationKey != null) {
      displayText = appLocalizations.translate(message.translationKey!);
      
      // If there are parameters, replace them in the text
      if (message.translationParams != null) {
        message.translationParams!.forEach((key, value) {
          displayText = displayText.replaceAll('{$key}', value);
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: _buildAvatar(isUser, theme),
            ),

          Flexible(
            child: GestureDetector(
              onTap: hasAudio ? () => _playMessage(message) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color:
                      isUser
                          ? theme.colorScheme.primary.withOpacity(0.9)
                          : theme.colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16.0),
                    topRight: const Radius.circular(16.0),
                    bottomLeft: Radius.circular(isUser ? 16.0 : 4.0),
                    bottomRight: Radius.circular(isUser ? 4.0 : 16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                  children: [
                    if (hasAudio)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUser)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(
                                isPlayingThisMessage
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                size: 28,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),

                          Flexible(
                            child: Text(
                              displayText,
                              style: TextStyle(
                                color:
                                    isUser
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          if (!isUser)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Icon(
                                isPlayingThisMessage
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                size: 28,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      )
                    else
                      Text(
                        displayText,
                        style: TextStyle(
                          color:
                              isUser
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                        ),
                      ),

                    // Add timestamp in small text
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 4.0,
                        left: 4.0,
                        right: 4.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 11.0,
                              color:
                                  isUser
                                      ? theme.colorScheme.onPrimary.withOpacity(
                                        0.7,
                                      )
                                      : theme.colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                            ),
                          ),
                          if (isUser)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Icon(
                                Icons.done_all,
                                size: 14.0,
                                color: theme.colorScheme.onPrimary.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: _buildAvatar(isUser, theme),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser, ThemeData theme) {
    return CircleAvatar(
      backgroundColor:
          isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.secondaryContainer,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color:
            isUser
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSecondaryContainer,
        size: 18.0,
      ),
    );
  }

  // Format timestamp like WhatsApp (HH:MM)
  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Show dialog to confirm clearing chat
  void _showClearChatDialog() {
    final appLocalizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(appLocalizations.translate('clear_chat_title')),
            content: Text(
              appLocalizations.translate('clear_chat_confirmation'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appLocalizations.translate('cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearChat();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(appLocalizations.translate('clear')),
              ),
            ],
          ),
    );
  }

  // Clear all chat messages
  Future<void> _clearChat() async {
    setState(() {
      _messages.clear();
    });
    await _storageService.clearChatMessages();
  }
}
