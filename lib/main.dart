import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'services/database_service.dart';
import 'services/voice_service.dart';
import 'services/ai_service.dart';
import 'services/device_service.dart';
import 'services/security_service.dart';
import 'providers/app_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/voice_provider.dart';
import 'providers/security_provider.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize core services
  await _initializeServices();

  runApp(const NexusAssistantApp());
}

Future<void> _initializeServices() async {
  try {
    // Initialize database first
    await DatabaseService().initialize();
    
    // Initialize other services
    await VoiceService().initialize();
    await SecurityService().initializeCamera();
    await DeviceService().requestPermissions();
    
    // Update AI service with settings
    final settings = DatabaseService().getAppSettings();
    AIService().updateSettings(settings);
    
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
}

class NexusAssistantApp extends StatelessWidget {
  const NexusAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'Nexus Assistant',
            debugShowCheckedModeBanner: false,
            
            // Theme configuration
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            
            // Localization
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('hi', ''), // Hindi
            ],
            locale: Locale(appProvider.languageCode, ''),
            
            // Initial route
            home: const SplashScreen(),
            
            // Global error handling
            builder: (context, widget) {
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                return Container(
                  color: Theme.of(context).colorScheme.error,
                  child: Center(
                    child: Text(
                      'Something went wrong!\n${errorDetails.exception}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              };
              return widget!;
            },
          );
        },
      ),
    );
  }
}