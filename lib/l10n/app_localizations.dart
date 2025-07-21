import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get hello => locale.languageCode == 'hi' ? 'नमस्ते' : 'Hello';
  String get settings => locale.languageCode == 'hi' ? 'सेटिंग्स' : 'Settings';
  String get darkMode => locale.languageCode == 'hi' ? 'डार्क मोड' : 'Dark Mode';
  String get language => locale.languageCode == 'hi' ? 'भाषा' : 'Language';
  String get voiceActivation => locale.languageCode == 'hi' ? 'वॉयस एक्टिवेशन' : 'Voice Activation';
  String get welcomeBack => locale.languageCode == 'hi' ? 'वापसी पर स्वागत है सर!' : 'Welcome back sir!';
  String get wrongPassword => locale.languageCode == 'hi' ? 'गलत पासवर्ड' : 'Wrong password';
  String get typeMessage => locale.languageCode == 'hi' ? 'एक संदेश टाइप करें...' : 'Type a message...';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}