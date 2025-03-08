import 'package:flutter/material.dart';
import 'package:practice_my_accent/l10n/app_localizations.dart';
import 'package:practice_my_accent/models/accent.dart';
import 'package:practice_my_accent/screens/api_key_screen.dart';
import 'package:practice_my_accent/services/storage_service.dart';
import 'package:practice_my_accent/widgets/language_selector.dart';

class AccentSelectionScreen extends StatefulWidget {
  const AccentSelectionScreen({super.key});

  @override
  State<AccentSelectionScreen> createState() => _AccentSelectionScreenState();
}

class _AccentSelectionScreenState extends State<AccentSelectionScreen> {
  final StorageService _storageService = StorageService();
  String? _selectedAccentCode;
  final List<Accent> _accents = Accent.getAccents();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.translate('select_accent_title')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              appLocalizations.translate('select_accent_subtitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: _accents.length,
              itemBuilder: (context, index) {
                final accent = _accents[index];
                final isSelected = accent.code == _selectedAccentCode;
                
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAccentCode = accent.code;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              accent.flag,
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appLocalizations.translate(accent.name.toLowerCase()),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  appLocalizations.translate('${accent.name.toLowerCase()}_description'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: _selectedAccentCode == null
                  ? null
                  : () async {
                      // Save the selected accent
                      await _storageService.saveAccent(_selectedAccentCode!);
                      
                      if (!mounted) return;
                      
                      // Navigate to API key screen
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const ApiKeyScreen(),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor: theme.colorScheme.surfaceVariant,
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
    );
  }
} 