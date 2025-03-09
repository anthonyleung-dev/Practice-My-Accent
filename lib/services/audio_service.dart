import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart' show Level;

class AudioService {
  final FlutterSoundPlayer _mPlayer = FlutterSoundPlayer(logLevel: Level.error);
  final FlutterSoundRecorder _mRecorder = FlutterSoundRecorder(
    logLevel: Level.error,
  );
  final Codec codecSelected = Codec.pcm16;

  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  String? _mPath;

  static const int cstINPUTSAMPLERATE = 16000;
  static const int cstOUTPUTSAMPLERATE = 24000;
  static const int cstCHANNELNB = 1;

  StreamSubscription? _recorderSubscription;
  StreamSubscription? _mRecordingDataSubscription;

  final StreamController<bool> _playbackStatusController =
      StreamController<bool>.broadcast();

  // Stream controller for audio level (for VAD)
  final StreamController<double> _audioLevelController =
      StreamController<double>.broadcast();

  Stream<bool> get playbackStatus => _playbackStatusController.stream;
  Stream<double> get audioLevelStream => _audioLevelController.stream;

  double _dbLevel = 0.0;

  // Directory for storing audio files
  Directory? _audioDirectory;

  // Method channel for audio routing
  static const MethodChannel _channel = MethodChannel('com.example.practice_my_accent/audio');

  void init() {
    _initAudioDirectory();
    _mPlayer.openPlayer().then((value) {
      _mPlayerIsInited = true;
    });

    _mPlayer.setLogLevel(Level.error);
    _mPlayer.setVolume(1.0);
    _openRecorder();
  }

  // Initialize the audio directory
  Future<void> _initAudioDirectory() async {
    try {
      // Get the application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();

      // Create a subdirectory for audio files
      _audioDirectory = Directory('${appDocDir.path}/audio_recordings');

      // Create the directory if it doesn't exist
      if (!await _audioDirectory!.exists()) {
        await _audioDirectory!.create(recursive: true);
      }

      debugPrint('Audio directory initialized: ${_audioDirectory!.path}');
    } catch (e) {
      debugPrint('Error initializing audio directory: $e');
      // Fallback to temporary directory if there's an error
      final tempDir = await getTemporaryDirectory();
      _audioDirectory = tempDir;
    }
  }

  // Get the audio directory path, initializing it if necessary
  Future<String> getAudioDirectoryPath() async {
    if (_audioDirectory == null) {
      await _initAudioDirectory();
    }
    return _audioDirectory!.path;
  }

  Future<void> _openRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _mRecorder.openRecorder();
    _mRecorder.setLogLevel(Level.error);

    _mRecorderIsInited = true;
  }

  Future<IOSink> createFile(String fileName) async {
    final dirPath = await getAudioDirectoryPath();
    _mPath = '$dirPath/$fileName.pcm';
    var outputFile = File(_mPath!);
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }
    return outputFile.openWrite();
  }

  Future<String> startRecording(String? prefix) async {
    debugPrint('startRecording $_mRecorderIsInited');
    assert(_mRecorderIsInited);
    final fileName = '${prefix ?? ''}_${DateTime.now().millisecondsSinceEpoch}';
    final dirPath = await getAudioDirectoryPath();
    _mPath = '$dirPath/$fileName.wav';

    // Set up audio level subscription for VAD
    _recorderSubscription = _mRecorder.onProgress!.listen((e) {
      _dbLevel = e.decibels ?? 0.0;
      _audioLevelController.add(_dbLevel);
    });
    await _mRecorder.setSubscriptionDuration(const Duration(milliseconds: 100));

    await _mRecorder.startRecorder(toFile: _mPath, codec: Codec.pcm16WAV);
    return _mPath!;
  }

  Future<void> startRecordingStream(
    void Function(Uint8List) onData,
    String? prefix,
  ) async {
    debugPrint('startRecording $_mRecorderIsInited');
    assert(_mRecorderIsInited);
    final fileName = '${prefix ?? ''}_${DateTime.now().millisecondsSinceEpoch}';
    var sink = await createFile(fileName);
    var recordingDataController = StreamController<Uint8List>();
    _mRecordingDataSubscription = recordingDataController.stream.listen((
      buffer,
    ) {
      sink.add(buffer);
      onData(buffer);

      // Calculate audio level from PCM data for VAD
      double level = _calculateAudioLevel(buffer);
      _audioLevelController.add(level);
    });

    await _mRecorder.startRecorder(
      toStream: recordingDataController.sink,
      codec: codecSelected,
      numChannels: cstCHANNELNB,
      sampleRate: cstINPUTSAMPLERATE,
      bufferSize: 128,
      audioSource: AudioSource.defaultSource,
    );
  }

  // Calculate audio level from PCM data
  double _calculateAudioLevel(Uint8List buffer) {
    if (buffer.isEmpty) return 0.0;

    // Convert PCM data to audio level
    double sum = 0;
    for (int i = 0; i < buffer.length; i += 2) {
      if (i + 1 < buffer.length) {
        // Convert 2 bytes to a 16-bit signed integer
        int sample = (buffer[i] & 0xFF) | ((buffer[i + 1] & 0xFF) << 8);
        // Convert to signed value
        if (sample > 32767) sample -= 65536;
        // Add absolute value to sum
        sum += sample.abs();
      }
    }

    // Calculate average and normalize to 0.0-1.0 range
    double average = sum / (buffer.length / 2);
    double normalized = average / 32768.0;

    return normalized;
  }

  Future<String> stopRecorder() async {
    await _mRecorder.stopRecorder();

    if (_mRecordingDataSubscription != null) {
      await _mRecordingDataSubscription!.cancel();
      _mRecordingDataSubscription = null;
    }

    if (_recorderSubscription != null) {
      await _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }

    return _mPath ?? '';
  }

  // Configure audio routing based on device state
  Future<void> configureAudioRouting() async {
    try {
      // Check if headphones are connected
      final bool headphonesConnected = await _channel.invokeMethod('isHeadphonesConnected');
      
      if (headphonesConnected) {
        // Use default routing if headphones are connected
        await _channel.invokeMethod('useDefaultAudioRouting');
        debugPrint('Using headphones for audio playback');
      } else {
        // Force audio to speaker if no headphones
        await _channel.invokeMethod('forceAudioToSpeaker');
        debugPrint('Forced audio to speaker');
      }
    } catch (e) {
      debugPrint('Error configuring audio routing: $e');
    }
  }

  Future<void> playAudio(String path, int sampleRate) async {
    if (!_mPlayerIsInited) {
      return;
    }
    if (_mPlayer.isPlaying) {
      await _mPlayer.stopPlayer();
    }
    
    // Configure audio routing before playback
    await configureAudioRouting();
    
    // Set volume to maximum
    await _mPlayer.setVolume(1.0);
    
    // Start playback
    await _mPlayer.startPlayer(
      fromURI: path,
      codec: codecSelected,
      sampleRate: sampleRate,
      numChannels: cstCHANNELNB,
      whenFinished: () {
        _playbackStatusController.add(false);
      },
    );
    
    debugPrint('Playing audio: $path');
  }

  Future<void> startStreamPlayer() async {
    if (!_mPlayerIsInited) {
      return;
    }
    
    // Configure audio routing before playback
    await configureAudioRouting();
    
    // Set volume to maximum
    await _mPlayer.setVolume(1.0);
    
    await _mPlayer.startPlayerFromStream(
      codec: codecSelected,
      sampleRate: 24000,
      numChannels: cstCHANNELNB,
      interleaved: true,
    );
    
    debugPrint('Started stream player');
  }

  Future<void> playStream(Uint8List audioData) async {
    if (!_mPlayerIsInited) {
      return;
    }

    await _mPlayer.feedUint8FromStream(audioData);
  }

  Future<void> stopPlayer() async {
    await _mPlayer.stopPlayer();
  }

  // Clean up old recordings to prevent excessive storage usage
  Future<void> cleanupOldRecordings({int maxAgeInDays = 30}) async {
    try {
      if (_audioDirectory == null) {
        await _initAudioDirectory();
      }

      final now = DateTime.now();
      final files = _audioDirectory!.listSync();

      int deletedCount = 0;

      for (final fileEntity in files) {
        if (fileEntity is File) {
          final file = fileEntity as File;
          final stat = await file.stat();
          final fileAge = now.difference(stat.modified);

          // Delete files older than maxAgeInDays
          if (fileAge.inDays > maxAgeInDays) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        debugPrint('Cleaned up $deletedCount old audio recordings');
      }
    } catch (e) {
      debugPrint('Error cleaning up old recordings: $e');
    }
  }

  void dispose() {
    stopPlayer();
    _mPlayer.closePlayer();

    stopRecorder();
    _mRecorder.closeRecorder();
    _recorderSubscription?.cancel();
    _playbackStatusController.close();
    _audioLevelController.close();
  }
}
