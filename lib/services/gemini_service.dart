import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GeminiService {
  static const String _host = 'generativelanguage.googleapis.com';
  static const String _model = 'gemini-2.0-flash-exp';

  WebSocketChannel? _channel;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Save stream data
  final List<Uint8List> _streamData = [];

  final StreamController<Uint8List> _audioResponseController =
      StreamController<Uint8List>.broadcast();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<Uint8List> get audioResponses => _audioResponseController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  String generatePrompt(String accentCode) {
    // Prepare the system message with the accent information
    String systemPrompt =
        'You are an serious, Use concise words accent coach specializing in $accentCode English. ';
    systemPrompt +=
        'User is not a native English speaker, so please keep the sentence simple.';
    systemPrompt +=
        'Analyze the following transcription and provide feedback on pronunciation.';
    systemPrompt +=
        'Also, if user have any lazy pronunciation, please correct them.';
    systemPrompt += 'Please repeat the sentence after the user.';
    systemPrompt +=
        'Please keep simple and concise. and when user not correct more than 2 times, please speak slowly and clearly.';
    return systemPrompt;
  }

  void connect(String apiKey, String accentCode) {
    try {
      if (apiKey.isEmpty) {
        debugPrint('Gemini API key not found');
        return;
      }
      final uri = Uri.parse(
        'wss://$_host/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey',
      );

      _channel = IOWebSocketChannel.connect(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      // Setup the model
      final setupMsg = {
        'setup': {
          'model': 'models/$_model',
          'generation_config': {
            'response_modalities': ['AUDIO'],
            'speech_config': {
              "voice_config": {
                "prebuilt_voice_config": {"voice_name": "Kore"},
              },
            },
          },
          'system_instruction': {
            'parts': [
              {'text': generatePrompt(accentCode)},
            ],
            'role': 'model',
          },
        },
      };

      _channel?.sink.add(jsonEncode(setupMsg));

      _channel?.stream.listen(
        (message) {
          handleResponse(message);
        },
        onDone: () {
          debugPrint('Connection done');
          _connectionController.add(false);
          _isConnected = false;
        },
        onError: (error) {
          debugPrint('Error connecting to Gemini: $error');
          _connectionController.add(false);
          _isConnected = false;
        },
      );
      _connectionController.add(true);
      _isConnected = true;
    } catch (e) {
      debugPrint('Error connecting to Gemini: $e');
      _connectionController.add(false);
      _isConnected = false;
    }
  }

  Stream get stream => _channel?.stream ?? Stream.empty();

  Future<void> handleResponse(dynamic message) async {
    try {
      final response = jsonDecode(utf8.decode(message));
      if (!response.containsKey('serverContent')) {
        debugPrint('No serverContent in response');
        return;
      }

      // Check if turn is complete
      try {
        final turnComplete = response['serverContent']['turnComplete'];
        if (turnComplete == true) {
          debugPrint('End of turn, ${_streamData.length}');
          return;
        }
      } catch (e) {
        // Turn not complete
      }

      // Handle audio responses
      try {
        debugPrint('have audio response');
        if (response['serverContent']['modelTurn']['parts'][0].containsKey(
          'inlineData',
        )) {
          debugPrint('have audio response');
        }
        if (response['serverContent']['modelTurn']['parts'][0].containsKey(
          'text',
        )) {
          debugPrint('have text response');
          final text =
              response['serverContent']['modelTurn']['parts'][0]['text'];
          debugPrint('text: $text');
        }
        final b64data =
            response['serverContent']['modelTurn']['parts'][0]['inlineData']['data'];
        if (b64data != null) {
          final audioData = base64Decode(b64data);
          _audioResponseController.add(audioData);
        }
      } catch (e) {
        debugPrint('Error processing audio response: $e');
        // No audio in this response
      }
    } catch (e) {
      debugPrint('Error handling Gemini response: $e');
    }
  }

  Future<void> sendAudio(Uint8List audioData) async {
    if (!_isConnected) {
      debugPrint('Cannot send audio: not connected');
      return;
    }
    // debugPrint('Sending audio: ${audioData.length}');
    final msg = {
      'realtime_input': {
        'media_chunks': [
          {'data': base64Encode(audioData), 'mime_type': 'audio/pcm'},
        ],
      },
    };

    // final msg = {
    //   "client_content": {
    //     "turn_complete": true,
    //     "turns": [
    //       {
    //         "role": "user",
    //         "parts": [
    //           {
    //             "inline_data": {
    //               "data": base64Encode(audioData),
    //               "mime_type": "audio/wav",
    //             },
    //           },
    //         ],
    //       },
    //     ],
    //   },
    // };

    _channel?.sink.add(jsonEncode(msg));
    // debugPrint('Sent audio: ${audioData.length}');
  }

  Future<void> disconnect() async {
    _channel?.sink.close();
    _audioResponseController.close();
    _connectionController.add(false);
    _isConnected = false;
  }
}
