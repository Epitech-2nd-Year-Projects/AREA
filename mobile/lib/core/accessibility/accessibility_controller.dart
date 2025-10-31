import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../features/settings/domain/use_cases/get_color_blind_mode.dart';
import '../../features/settings/domain/use_cases/get_screen_reader_enabled.dart';
import '../../features/settings/domain/use_cases/set_color_blind_mode.dart';
import '../../features/settings/domain/use_cases/set_screen_reader_enabled.dart';
import 'text_to_speech_service.dart';

class AccessibilityPreferences {
  final bool isColorBlindModeEnabled;
  final bool isScreenReaderEnabled;

  const AccessibilityPreferences({
    required this.isColorBlindModeEnabled,
    required this.isScreenReaderEnabled,
  });

  AccessibilityPreferences copyWith({
    bool? isColorBlindModeEnabled,
    bool? isScreenReaderEnabled,
  }) {
    return AccessibilityPreferences(
      isColorBlindModeEnabled:
          isColorBlindModeEnabled ?? this.isColorBlindModeEnabled,
      isScreenReaderEnabled:
          isScreenReaderEnabled ?? this.isScreenReaderEnabled,
    );
  }
}

class AccessibilityController extends ChangeNotifier {
  static const List<double> _colorBlindMatrix = <double>[
    0.8,
    0.2,
    0.0,
    0,
    0,
    0.2,
    0.7,
    0.1,
    0,
    0,
    0.0,
    0.3,
    0.7,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  final GetColorBlindMode _getColorBlindMode;
  final SetColorBlindMode _setColorBlindMode;
  final GetScreenReaderEnabled _getScreenReaderEnabled;
  final SetScreenReaderEnabled _setScreenReaderEnabled;
  final TextToSpeechService _textToSpeech;
  Future<String?> Function()? _currentSummaryProvider;
  String? _lastAnnouncement;

  AccessibilityPreferences _preferences =
      const AccessibilityPreferences(isColorBlindModeEnabled: false, isScreenReaderEnabled: false);
  bool _isInitialized = false;

  AccessibilityController({
    required GetColorBlindMode getColorBlindMode,
    required SetColorBlindMode setColorBlindMode,
    required GetScreenReaderEnabled getScreenReaderEnabled,
    required SetScreenReaderEnabled setScreenReaderEnabled,
    required TextToSpeechService textToSpeechService,
  })  : _getColorBlindMode = getColorBlindMode,
        _setColorBlindMode = setColorBlindMode,
        _getScreenReaderEnabled = getScreenReaderEnabled,
        _setScreenReaderEnabled = setScreenReaderEnabled,
        _textToSpeech = textToSpeechService;

  bool get isInitialized => _isInitialized;

  bool get isColorBlindModeEnabled =>
      _preferences.isColorBlindModeEnabled;

  bool get isScreenReaderEnabled =>
      _preferences.isScreenReaderEnabled;

  AccessibilityPreferences get preferences => _preferences;

  ColorFilter? get colorBlindFilter =>
      isColorBlindModeEnabled ? const ColorFilter.matrix(_colorBlindMatrix) : null;

  Future<void> load() async {
    final colorBlind = _getColorBlindMode();
    final screenReader = _getScreenReaderEnabled();
    await _textToSpeech.updateLocale(
      PlatformDispatcher.instance.locale,
    );
    _preferences = AccessibilityPreferences(
      isColorBlindModeEnabled: colorBlind,
      isScreenReaderEnabled: screenReader,
    );
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> updateColorBlindMode(bool enabled) async {
    if (_preferences.isColorBlindModeEnabled == enabled) {
      return;
    }
    _preferences = _preferences.copyWith(
      isColorBlindModeEnabled: enabled,
    );
    await _setColorBlindMode(enabled);
    notifyListeners();
  }

  Future<void> updateScreenReaderEnabled(
    bool enabled, {
    String? feedbackMessage,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    if (_preferences.isScreenReaderEnabled == enabled) {
      if (feedbackMessage != null) {
        await announce(feedbackMessage, textDirection: textDirection);
      }
      return;
    }
    _preferences = _preferences.copyWith(isScreenReaderEnabled: enabled);
    await _setScreenReaderEnabled(enabled);
    notifyListeners();
    if (feedbackMessage != null) {
      await announce(feedbackMessage, textDirection: textDirection);
    }
    if (enabled) {
      await _announceFromCurrentRoute();
    } else {
      await _textToSpeech.stop();
      _lastAnnouncement = null;
    }
  }

  Future<void> announce(
    String message, {
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    if (!_preferences.isScreenReaderEnabled) return;
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    if (_lastAnnouncement == trimmed) return;
    _lastAnnouncement = trimmed;
    await _textToSpeech.speak(trimmed);
  }

  Future<void> stopSpeaking() async {
    _lastAnnouncement = null;
    await _textToSpeech.stop();
  }

  Future<void> updateSpeechLocale(Locale locale) =>
      _textToSpeech.updateLocale(locale);

  void setCurrentSummaryProvider(
    Future<String?> Function()? provider,
  ) {
    _currentSummaryProvider = provider;
  }

  Future<void> _announceFromCurrentRoute() async {
    if (!_preferences.isScreenReaderEnabled) return;
    final provider = _currentSummaryProvider;
    if (provider == null) return;
    final summary = await provider();
    if (summary == null || summary.trim().isEmpty) return;
    await announce(summary);
  }
}
