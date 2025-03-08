import 'package:flutter/material.dart';
import 'package:practice_my_accent/l10n/app_localizations.dart';
import 'package:practice_my_accent/screens/chat_screen.dart';
import 'package:practice_my_accent/services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  String? _accentCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final accentCode = await _storageService.getAccent();

    setState(() {
      _accentCode = accentCode;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.translate('home_title')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.05),
                      theme.colorScheme.background,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome and accent info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.language,
                                size: 32,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appLocalizations.translate(
                                      'welcome_to_practice_my_accent',
                                    ),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${appLocalizations.translate('your_target_accent')}: ${_getAccentName(_accentCode)}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // AI info
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.smart_toy,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${appLocalizations.translate('powered_by')}: Gemini 2.0 Stream Live',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Start practicing button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to the chat screen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ChatScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  appLocalizations.translate(
                                    'start_practicing',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  String _getAccentName(String? code) {
    switch (code) {
      case 'US':
        return 'American English 🇺🇸';
      case 'UK':
        return 'British English 🇬🇧';
      case 'AU':
        return 'Australian English 🇦🇺';
      case 'CA':
        return 'Canadian English 🇨🇦';
      case 'IE':
        return 'Irish English 🇮🇪';
      case 'NZ':
        return 'New Zealand English 🇳🇿';
      default:
        return 'Not Selected';
    }
  }
}
