import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _accentKey = 'selected_accent';
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _aiProviderKey = 'selected_ai_provider';
  static const String _openaiApiKey = 'openai_api_key';
  static const String _googleApiKey = 'google_api_key';
  static const String _chatMessagesKey = 'chat_messages';

  // Save the selected accent
  Future<bool> saveAccent(String accentCode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_accentKey, accentCode);
  }

  // Get the selected accent
  Future<String?> getAccent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accentKey);
  }

  // Save the selected AI provider
  Future<bool> saveAIProvider(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_aiProviderKey, providerId);
  }

  // Get the selected AI provider
  Future<String?> getAIProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_aiProviderKey);
  }

  // Save API key for a specific provider
  Future<bool> saveApiKey(String providerId, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = providerId == 'chatgpt' ? _openaiApiKey : _googleApiKey;
    return prefs.setString(key, apiKey);
  }

  // Get API key for a specific provider
  Future<String?> getApiKey(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = providerId == 'chatgpt' ? _openaiApiKey : _googleApiKey;
    return prefs.getString(key);
  }

  // Check if it's the first launch
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  // Set first launch to false
  Future<bool> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_isFirstLaunchKey, false);
  }

  // Save chat messages
  Future<bool> saveChatMessages(List<Map<String, dynamic>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(messages);
    return prefs.setString(_chatMessagesKey, jsonString);
  }

  // Get chat messages
  Future<List<Map<String, dynamic>>> getChatMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_chatMessagesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error decoding chat messages: $e');
      return [];
    }
  }

  // Clear chat messages
  Future<bool> clearChatMessages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_chatMessagesKey);
  }
} 