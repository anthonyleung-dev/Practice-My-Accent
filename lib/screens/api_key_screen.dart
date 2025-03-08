import 'package:flutter/material.dart';
import 'package:practice_my_accent/l10n/app_localizations.dart';
import 'package:practice_my_accent/screens/main_screen.dart';
import 'package:practice_my_accent/services/storage_service.dart';
import 'package:practice_my_accent/widgets/language_selector.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isApiKeyVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKeyAndContinue() async {
    final apiKey = _apiKeyController.text.trim();
    
    // Validate API key
    if (apiKey.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).translate('api_key_required');
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Save the API key
      await _storageService.saveApiKey('google', apiKey);
      
      // Save the AI provider as Google (default)
      await _storageService.saveAIProvider('google');
      
      // Mark first launch as complete
      await _storageService.setFirstLaunchComplete();
      
      if (!mounted) return;
      
      // Navigate to main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.translate('api_keys')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // API Key Input Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLocalizations.translate('google_api_key'),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              appLocalizations.translate('google_api_key_description'),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final Uri url = Uri.parse('https://aistudio.google.com/apikey');
                                if (!await launchUrl(url)) {
                                  // If unable to open URL, show an error message
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not open URL: $url',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                appLocalizations.translate('get_api_key_hint'),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _apiKeyController,
                              decoration: InputDecoration(
                                hintText: appLocalizations.translate('api_key_hint'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                errorText: _errorMessage,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isApiKeyVisible = !_isApiKeyVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isApiKeyVisible,
                              onChanged: (_) {
                                if (_errorMessage != null) {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveApiKeyAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: Text(
                          appLocalizations.translate('continue_button'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 