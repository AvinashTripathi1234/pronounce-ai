import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import '../models/phoneme_feedback.dart';
import 'audio_session_manager.dart';

enum LiveKitConnectionStatus {
  disconnected,
  connecting,
  connected,
  evaluating,
  error,
}

class LiveKitService extends ChangeNotifier {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  LocalAudioTrack? _audioTrack;

  LiveKitConnectionStatus _status = LiveKitConnectionStatus.disconnected;
  LiveKitConnectionStatus get status => _status;

  PronunciationFeedback _currentFeedback = PronunciationFeedback.empty();
  PronunciationFeedback get currentFeedback => _currentFeedback;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final AudioSessionManager _audioSessionManager = AudioSessionManager();

  /// Connects to the LiveKit SFU room, activates the audio session,
  /// and publishes the microphone track.
  Future<bool> startSession({
    required String liveKitUrl,
    required String token,
    required String initialSentence,
  }) async {
    try {
      _setStatus(LiveKitConnectionStatus.connecting);

      // 1. Configure audio hardware session first
      final configured = await _audioSessionManager.configureForSpeechCapture();
      if (!configured) {
        _setError('Failed to obtain microphone permission or configure audio session');
        return false;
      }
      await _audioSessionManager.activate();

      // 2. Initialize LiveKit Room
      _room = Room();
      _listener = _room!.createListener();
      _setupRoomListeners();

      // 3. Connect to LiveKit SFU
      await _room!.connect(
        liveKitUrl,
        token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );

      // 4. Enable Microphone (WebRTC Audio Stream)
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      // 5. Notify agent of the initial target sentence via Data Channel
      await sendTargetSentence(initialSentence);

      _setStatus(LiveKitConnectionStatus.connected);
      dev.log('Connected to LiveKit and streaming WebRTC audio', name: 'LiveKitService');
      return true;
    } catch (e) {
      dev.log('LiveKit connection failed: $e', name: 'LiveKitService');
      _setError('LiveKit error: $e');
      return false;
    }
  }

  /// Sends control message (e.g. exercise sentence) to the backend agent
  Future<void> sendTargetSentence(String sentence) async {
    if (_room == null || _room!.localParticipant == null) return;
    try {
      final payload = json.encode({
        'type': 'set_exercise',
        'sentence': sentence,
      });
      await _room!.localParticipant!.publishData(
        utf8.encode(payload),
      );
    } catch (e) {
      dev.log('Failed to send target sentence over DataChannel: $e', name: 'LiveKitService');
    }
  }

  /// Listens to incoming real-time phoneme feedback packets over the DataChannel
  void _setupRoomListeners() {
    _listener?.on<DataReceivedEvent>((event) {
      try {
        final rawString = utf8.decode(event.data);
        final map = json.decode(rawString) as Map<String, dynamic>;

        if (map['type'] == 'phoneme_feedback') {
          final feedbackData = map['data'] as Map<String, dynamic>;
          final isFinal = map['is_final'] as bool? ?? false;
          _currentFeedback = PronunciationFeedback.fromJson(feedbackData, isFinal: isFinal);
          _setStatus(LiveKitConnectionStatus.evaluating);
          notifyListeners();
        }
      } catch (e) {
        dev.log('Error parsing DataChannel packet: $e', name: 'LiveKitService');
      }
    });

    _listener?.on<RoomDisconnectedEvent>((event) {
      dev.log('Disconnected from room: ${event.reason}', name: 'LiveKitService');
      _setStatus(LiveKitConnectionStatus.disconnected);
    });
  }

  /// Disconnects from the room and releases audio resources
  Future<void> stopSession() async {
    try {
      if (_room != null) {
        await _room!.localParticipant?.setMicrophoneEnabled(false);
        await _room!.disconnect();
        await _room!.dispose();
        _room = null;
      }
      _listener?.dispose();
      _listener = null;

      await _audioSessionManager.deactivate();
      _setStatus(LiveKitConnectionStatus.disconnected);
    } catch (e) {
      dev.log('Error stopping LiveKit session: $e', name: 'LiveKitService');
    }
  }

  void _setStatus(LiveKitConnectionStatus newStatus) {
    _status = newStatus;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _status = LiveKitConnectionStatus.error;
    notifyListeners();
  }

  @override
  void dispose() {
    stopSession();
    super.dispose();
  }
}
