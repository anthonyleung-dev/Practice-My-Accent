import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:practice_my_accent/l10n/app_localizations.dart';
import 'package:practice_my_accent/screens/accent_selection_screen.dart';
import 'package:practice_my_accent/widgets/language_selector.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _micPermissionRequested = false;

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    setState(() {
      _micPermissionRequested = true;
    });

    if (status.isGranted) {
      _navigateToAccentSelection();
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    }
  }

  void _navigateToAccentSelection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AccentSelectionScreen()),
    );
  }

  void _showPermissionDeniedDialog() {
    final appLocalizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(appLocalizations.translate('mic_permission_required')),
            content: Text(
              appLocalizations.translate('mic_permission_explanation'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appLocalizations.translate('cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: Text(appLocalizations.translate('open_settings')),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? [Colors.deepPurple.shade900, Colors.black]
                    : [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.record_voice_over,
                  size: 100,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(height: 40),
                Text(
                  appLocalizations.translate('welcome_title'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  appLocalizations.translate('welcome_subtitle'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: .7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Colors.black.withValues(alpha: .3)
                            : Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.mic, color: theme.colorScheme.onPrimary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          appLocalizations.translate('mic_permission_info'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed:
                      _micPermissionRequested
                          ? _navigateToAccentSelection
                          : _requestMicrophonePermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode
                            ? Colors.deepPurple.shade300
                            : theme.colorScheme.surface,
                    foregroundColor:
                        isDarkMode ? Colors.black : theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    _micPermissionRequested
                        ? appLocalizations.translate('continue_button')
                        : appLocalizations.translate('allow_mic_access'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_micPermissionRequested)
                  TextButton(
                    onPressed: () => openAppSettings(),
                    child: Text(
                      appLocalizations.translate('change_permission_settings'),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: .8,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
