import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:practice_my_accent/l10n/app_localizations.dart';
import 'package:practice_my_accent/l10n/l10n.dart';
import 'package:practice_my_accent/providers/language_provider.dart';
import 'package:practice_my_accent/screens/main_screen.dart';
import 'package:practice_my_accent/screens/welcome_screen.dart';
import 'package:practice_my_accent/services/storage_service.dart';

void main() async {
  // Ensure Flutter is initialized before using plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  bool _isFirstLaunch = true;
  
  // Define the custom coral color
  static const Color customCoral = Color(0xFFFE7D48);

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final isFirstLaunch = await _storageService.isFirstLaunch();
    setState(() {
      _isFirstLaunch = isFirstLaunch;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LanguageProvider>(context);
    
    return MaterialApp(
      title: 'Practice My Accent',
      debugShowCheckedModeBanner: false,
      locale: provider.locale,
      supportedLocales: L10n.all,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: customCoral,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: const CardTheme(
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: customCoral,
          brightness: Brightness.dark,
          primary: customCoral.withOpacity(0.8),
          onPrimary: Colors.white,
          secondary: Colors.amber,
          surface: const Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: customCoral.withOpacity(0.8),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          color: Colors.grey.shade900,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        dialogTheme: const DialogTheme(
          backgroundColor: Color(0xFF1E1E1E),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: _isLoading
          ? const _LoadingScreen()
          : _isFirstLaunch
              ? const WelcomeScreen()
              : const MainScreen(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
