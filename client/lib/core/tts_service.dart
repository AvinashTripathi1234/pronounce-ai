import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService extends ChangeNotifier {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal() {
    _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  void _initTts() async {
    try {
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      // Pacing calibrated for language learners (0.46 = clear and deliberate)
      await _flutterTts.setSpeechRate(0.46);
      await _flutterTts.setLanguage("en-US");

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        dev.log("TTS Error: $msg", name: "TtsService");
        _isSpeaking = false;
        notifyListeners();
      });
    } catch (e) {
      dev.log("Failed to initialize FlutterTts: $e", name: "TtsService");
    }
  }

  String _mapAccentToLocale(String accentLabel) {
    if (accentLabel.contains('British') || accentLabel.contains('GB')) {
      return 'en-GB';
    } else if (accentLabel.contains('Australian') || accentLabel.contains('AU')) {
      return 'en-AU';
    } else if (accentLabel.contains('Canadian')) {
      return 'en-CA';
    }
    return 'en-US';
  }

  /// Speaks the target sentence with native cadence and selected accent
  Future<void> speakSentence(String sentence, {String accent = '🇺🇸 General American'}) async {
    try {
      if (_isSpeaking) {
        await stop();
        return;
      }
      final locale = _mapAccentToLocale(accent);
      await _flutterTts.setLanguage(locale);
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.speak(sentence);
    } catch (e) {
      dev.log("Error in speakSentence: $e", name: "TtsService");
      _isSpeaking = false;
      notifyListeners();
    }
  }

  /// Speaks an isolated word or phonemic drill slowly
  Future<void> speakWord(String word, {String accent = '🇺🇸 General American'}) async {
    try {
      final locale = _mapAccentToLocale(accent);
      await _flutterTts.setLanguage(locale);
      // Slower rate for phonetic precision
      await _flutterTts.setSpeechRate(0.35);
      await _flutterTts.speak(word);
    } catch (e) {
      dev.log("Error in speakWord: $e", name: "TtsService");
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      dev.log("Error stopping TTS: $e", name: "TtsService");
    }
  }
}
