import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  final FlutterTts _tts = FlutterTts();
  Locale? _currentLocale;

  TextToSpeechService() {
    _configureDefaults();
  }

  Future<void> _configureDefaults() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);

    final locale = PlatformDispatcher.instance.locale;
    await updateLocale(locale);
  }

  Future<void> updateLocale(Locale locale) async {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    final languageCode = locale.countryCode?.isNotEmpty == true
        ? '${locale.languageCode}-${locale.countryCode}'
        : locale.languageCode;
    try {
      await _tts.setLanguage(languageCode);
    } catch (error) {
      if (kDebugMode) {
        print('⚠️ Failed to set TTS language $languageCode: $error');
      }
      await _tts.setLanguage('en-US');
    }
  }

  Future<void> speak(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    await _tts.stop();
    await _tts.speak(trimmed);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _tts.awaitSpeakCompletion(false);
  }
}
