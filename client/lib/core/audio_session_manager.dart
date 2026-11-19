import 'dart:developer' as dev;
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioSessionManager {
  static final AudioSessionManager _instance = AudioSessionManager._internal();
  factory AudioSessionManager() => _instance;
  AudioSessionManager._internal();

  AudioSession? _session;
  bool _isConfigured = false;

  /// Requests microphone hardware permissions.
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Configures system audio session for real-time speech recording & WebRTC focus.
  Future<bool> configureForSpeechCapture() async {
    try {
      final hasPermission = await requestMicrophonePermission();
      if (!hasPermission) {
        dev.log('Microphone permission denied', name: 'AudioSessionManager');
        return false;
      }

      _session = await AudioSession.instance;

      // Configure system audio session for speech recognition & WebRTC focus
      // Uses the canonical speech configuration provided by audio_session
      await _session!.configure(const AudioSessionConfiguration.speech());

      // Listen for interruptions (e.g. incoming phone call)
      _session!.interruptionEventStream.listen((event) {
        if (event.begin) {
          dev.log('Audio interruption began', name: 'AudioSessionManager');
        } else {
          dev.log('Audio interruption ended', name: 'AudioSessionManager');
        }
      });

      _isConfigured = true;
      dev.log('Audio session configured for low-latency speech capture', name: 'AudioSessionManager');
      return true;
    } catch (e) {
      dev.log('Failed to configure audio session: $e', name: 'AudioSessionManager');
      return false;
    }
  }

  /// Activates the configured audio session before starting WebRTC audio stream.
  Future<void> activate() async {
    if (_session != null && _isConfigured) {
      await _session!.setActive(true);
    }
  }

  /// Deactivates the audio session when practice stops.
  Future<void> deactivate() async {
    if (_session != null) {
      await _session!.setActive(false);
    }
  }
}
