import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:practice_my_accent/l10n/l10n.dart';
import 'package:practice_my_accent/providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LanguageProvider>(context);
    final locale = provider.locale;
    return PopupMenuButton<Locale>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language, color: Theme.of(context).colorScheme.onPrimary),
          const SizedBox(width: 4),
          Text(
            _getLanguageName(locale),
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ],
      ),
      onSelected: (Locale locale) {
        provider.setLocale(locale);
      },
      itemBuilder:
          (context) =>
              L10n.all
                  .map(
                    (locale) => PopupMenuItem<Locale>(
                      value: locale,
                      child: Row(
                        children: [
                          Text(_getLanguageFlag(locale)),
                          const SizedBox(width: 8),
                          Text(_getLanguageName(locale)),
                          if (locale.languageCode ==
                              provider.locale.languageCode)
                            const Spacer()
                          else
                            const SizedBox.shrink(),
                          if (locale.languageCode ==
                              provider.locale.languageCode)
                            const Icon(Icons.check, color: Colors.green)
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  )
                  .toList(),
    );
  }

  String _getLanguageFlag(Locale locale) {
    if (locale.languageCode == 'zh' && locale.countryCode == 'TW') {
      return '🇹🇼';
    }

    if (locale.languageCode == 'zh' && locale.countryCode == 'HK') {
      return '🇭🇰';
    }

    switch (locale.languageCode) {
      case 'en':
        return '🇺🇸';
      case 'zh':
        return '🇨🇳';
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      default:
        return '🌐';
    }
  }

  String _getLanguageName(Locale locale) {
    if (locale.languageCode == 'zh' && locale.countryCode == 'TW') {
      return '繁體中文 (台灣)';
    }

    if (locale.languageCode == 'zh' && locale.countryCode == 'HK') {
      return '繁體中文 (香港)';
    }

    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '简体中文';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return 'Unknown';
    }
  }
}
