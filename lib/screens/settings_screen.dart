import 'package:flutter/material.dart';
import 'package:practice_my_accent/l10n/app_localizations.dart';
import 'package:practice_my_accent/models/accent.dart';
import 'package:practice_my_accent/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:practice_my_accent/providers/language_provider.dart';
import 'package:practice_my_accent/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _openaiApiKeyController = TextEditingController();
  final TextEditingController _googleApiKeyController = TextEditingController();

  String? _selectedAccentCode;
  String? _selectedProviderId;
  bool _isGoogleKeyVisible = false;
  bool _isLoading = true;
  bool _hasChanges = false;

  final List<Accent> _accents = Accent.getAccents();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final accentCode = await _storageService.getAccent();
    final providerId = await _storageService.getAIProvider();
    final openaiApiKey = await _storageService.getApiKey('chatgpt');
    final googleApiKey = await _storageService.getApiKey('google');

    setState(() {
      _selectedAccentCode = accentCode;
      _selectedProviderId = providerId;
      _openaiApiKeyController.text = openaiApiKey ?? '';
      _googleApiKeyController.text = googleApiKey ?? '';
      _isLoading = false;
      _hasChanges = false;
    });
  }

  @override
  void dispose() {
    _openaiApiKeyController.dispose();
    _googleApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    if (_selectedAccentCode != null) {
      await _storageService.saveAccent(_selectedAccentCode!);
    }

    if (_selectedProviderId != null) {
      await _storageService.saveAIProvider(_selectedProviderId!);
    }

    if (_openaiApiKeyController.text.isNotEmpty) {
      await _storageService.saveApiKey('chatgpt', _openaiApiKeyController.text);
    }

    if (_googleApiKeyController.text.isNotEmpty) {
      await _storageService.saveApiKey('google', _googleApiKeyController.text);
    }

    setState(() {
      _isLoading = false;
      _hasChanges = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).translate('settings_saved')),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.translate('settings')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          // Save button
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: appLocalizations.translate('save_settings'),
              onPressed: _isLoading ? null : _saveSettings,
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Language settings
                      Text(
                        appLocalizations.translate('language'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [_buildLanguageDropdown(context)],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Accent settings
                      Text(
                        appLocalizations.translate('accent_settings'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                appLocalizations.translate(
                                  'select_accent_subtitle',
                                ),
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedAccentCode,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                items:
                                    _accents.map((accent) {
                                      return DropdownMenuItem<String>(
                                        value: accent.code,
                                        child: Row(
                                          children: [
                                            Text(accent.flag),
                                            const SizedBox(width: 8),
                                            Text(
                                              appLocalizations.translate(
                                                accent.name.toLowerCase(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAccentCode = value;
                                    _markAsChanged();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // API Keys Section
                      Text(
                        appLocalizations.translate('api_keys'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Google API Key (default to Google)
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
                                appLocalizations.translate(
                                  'google_api_key_description',
                                ),
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
                                controller: _googleApiKeyController,
                                decoration: InputDecoration(
                                  hintText: appLocalizations.translate(
                                    'api_key_hint',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isGoogleKeyVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isGoogleKeyVisible =
                                            !_isGoogleKeyVisible;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_isGoogleKeyVisible,
                                onChanged: (value) => _markAsChanged(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildLanguageDropdown(BuildContext context) {
    final provider = Provider.of<LanguageProvider>(context);
    final currentLocale = provider.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('language'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Locale>(
          value: currentLocale,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          items:
              L10n.all.map((locale) {
                return DropdownMenuItem<Locale>(
                  value: locale,
                  child: Row(
                    children: [
                      _getLanguageFlag(locale),
                      const SizedBox(width: 8),
                      Text(_getLanguageName(locale)),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (locale) {
            if (locale != null) {
              provider.setLocale(locale);
            }
          },
        ),
      ],
    );
  }

  Widget _getLanguageFlag(Locale locale) {
    String flagText;

    if (locale.languageCode == 'zh' && locale.countryCode == 'TW') {
      flagText = '🇹🇼';
    } else if (locale.languageCode == 'zh' && locale.countryCode == 'HK') {
      flagText = '🇭🇰';
    } else if (locale.languageCode == 'zh') {
      flagText = '🇨🇳';
    } else if (locale.languageCode == 'en') {
      flagText = '🇺🇸';
    } else {
      flagText = '🌐';
    }

    return Text(flagText, style: const TextStyle(fontSize: 24));
  }

  String _getLanguageName(Locale locale) {
    if (locale.languageCode == 'zh' && locale.countryCode == 'TW') {
      return '繁體中文 (台灣)';
    } else if (locale.languageCode == 'zh' && locale.countryCode == 'HK') {
      return '繁體中文 (香港)';
    } else if (locale.languageCode == 'zh') {
      return '简体中文';
    } else if (locale.languageCode == 'en') {
      return 'English';
    } else {
      return 'Unknown';
    }
  }
}
