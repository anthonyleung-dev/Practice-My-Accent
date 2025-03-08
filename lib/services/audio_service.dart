import 'dart:async';
import 'dart:io';
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

  void init() {
    _mPlayer.openPlayer().then((value) {
      _mPlayerIsInited = true;
    });
    _mPlayer.setLogLevel(Level.error);
    _openRecorder();
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
    var tempDir = await getTemporaryDirectory();
    _mPath = '${tempDir.path}/$fileName.pcm';
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
    var tempDir = await getTemporaryDirectory();
    _mPath = '${tempDir.path}/$fileName.wav';
    
    // Set up audio level subscription for VAD
    _recorderSubscription = _mRecorder.onProgress!.listen((e) {
      _dbLevel = e.decibels ?? 0.0;
      _audioLevelController.add(_dbLevel);
    });
    await _mRecorder.setSubscriptionDuration(
      const Duration(milliseconds: 100),
    );
    
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

  Future<void> playAudio(String path, int sampleRate) async {
    if (!_mPlayerIsInited) {
      return;
    }
    if (_mPlayer.isPlaying) {
      await _mPlayer.stopPlayer();
    }
    await _mPlayer.startPlayer(
      fromURI: path,
      codec: codecSelected,
      sampleRate: sampleRate,
      numChannels: cstCHANNELNB,
      whenFinished: () {
        _playbackStatusController.add(false);
      },
    );
  }

  Future<void> startStreamPlayer() async {
    if (!_mPlayerIsInited) {
      return;
    }
    await _mPlayer.startPlayerFromStream(
      codec: codecSelected,
      sampleRate: 24000,
      numChannels: cstCHANNELNB,
      interleaved: true,
    );
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
