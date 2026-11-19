import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../core/livekit_service.dart';
import '../core/tts_service.dart';
import '../models/exercise.dart';
import '../widgets/phoneme_highlighter.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/score_card.dart';
import '../widgets/prosody_ribbon.dart';

class PracticeScreen extends StatefulWidget {
  final String backendBaseUrl;

  const PracticeScreen({
    Key? key,
    this.backendBaseUrl = 'http://localhost:8000',
  }) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int _currentExerciseIndex = 0;
  List<Exercise> _exercises = Exercise.defaultExercises;
  bool _isLoadingToken = false;
  String _selectedAccent = '🇺🇸 General American';
  late String _serverUrl;

  Exercise get _currentExercise => _exercises[_currentExerciseIndex];

  @override
  void initState() {
    super.initState();
    _serverUrl = widget.backendBaseUrl;
    _fetchExercisesFromBackend();
  }

  Future<void> _fetchExercisesFromBackend() async {
    try {
      final res = await http.get(Uri.parse('$_serverUrl/api/exercises'));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        setState(() {
          _exercises = list.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (_) {
      // Fallback to default local exercises if backend is starting up
    }
  }

  void _showServerSettings() {
    final controller = TextEditingController(text: _serverUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Backend Server URL", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "To use on friends' phones, paste your public server URL (e.g. via Cloudflare tunnel, ngrok, or local IP):",
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                hintText: "http://192.168.1.X:8000 or https://...",
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () {
              setState(() {
                _serverUrl = controller.text.trim();
              });
              Navigator.pop(ctx);
              _fetchExercisesFromBackend();
              _showSnackBar("Updated server URL to $_serverUrl");
            },
            child: const Text("Save & Connect"),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePractice(LiveKitService liveKit) async {
    if (liveKit.status == LiveKitConnectionStatus.connected ||
        liveKit.status == LiveKitConnectionStatus.evaluating) {
      await liveKit.stopSession();
      return;
    }

    setState(() => _isLoadingToken = true);

    try {
      // 1. Request room credentials & LiveKit JWT token from FastAPI server
      // Recommended Endpoint: GET /api/v1/rooms/join-token
      final tokenUri = Uri.parse('$_serverUrl/api/v1/rooms/join-token').replace(
        queryParameters: {
          'room_name': 'practice-room-1',
          'name': 'Learner',
        },
      );
      final tokenRes = await http.get(tokenUri);

      if (tokenRes.statusCode == 200) {
        final data = json.decode(tokenRes.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        final liveKitUrl = data['livekit_url'] as String;

        // 2. Connect to LiveKit SFU and publish WebRTC stream
        await liveKit.startSession(
          liveKitUrl: liveKitUrl,
          token: token,
          initialSentence: _currentExercise.sentence,
        );
      } else {
        _showSnackBar('Backend error: ${tokenRes.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Cannot connect to backend: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingToken = false);
      }
    }
  }

  void _nextExercise(LiveKitService liveKit) {
    if (liveKit.status != LiveKitConnectionStatus.disconnected) {
      liveKit.stopSession();
    }
    setState(() {
      _currentExerciseIndex = (_currentExerciseIndex + 1) % _exercises.length;
    });
  }

  void _prevExercise(LiveKitService liveKit) {
    if (liveKit.status != LiveKitConnectionStatus.disconnected) {
      liveKit.stopSession();
    }
    setState(() {
      _currentExerciseIndex =
          (_currentExerciseIndex - 1 + _exercises.length) % _exercises.length;
    });
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _showAccentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final accents = [
          '🇺🇸 General American',
          '🇬🇧 British (RP)',
          '🇦🇺 Australian English',
          '🇨🇦 Canadian English'
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Target Accent",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...accents.map((accent) => ListTile(
                    title: Text(accent, style: const TextStyle(color: Colors.white70)),
                    trailing: _selectedAccent == accent
                        ? const Icon(Icons.check, color: Color(0xFF10B981))
                        : null,
                    onTap: () {
                      setState(() => _selectedAccent = accent);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveKit = Provider.of<LiveKitService>(context);
    final tts = Provider.of<TtsService>(context);
    final isStreaming = liveKit.status == LiveKitConnectionStatus.connected ||
        liveKit.status == LiveKitConnectionStatus.evaluating;
    final feedback = liveKit.currentFeedback;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16), // Deep midnight aesthetic
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.graphic_eq, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              "PronounceAI",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Target Accent Selector Pill
          GestureDetector(
            onTap: _showAccentPicker,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedAccent, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Settings button to configure server URL for friends' phones
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54, size: 20),
            tooltip: "Server Configuration",
            onPressed: _showServerSettings,
          ),
          const SizedBox(width: 4),
          // LiveKit Connection Status Pill
          Container(
            margin: const EdgeInsets.fromLTRB(0, 12, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isStreaming
                  ? const Color(0xFF10B981).withOpacity(0.18)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isStreaming ? const Color(0xFF10B981) : Colors.white24,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 3.5,
                  backgroundColor: isStreaming ? const Color(0xFF10B981) : Colors.white38,
                ),
                const SizedBox(width: 6),
                Text(
                  isStreaming ? "Streaming" : "Standby",
                  style: TextStyle(
                    fontSize: 11,
                    color: isStreaming ? const Color(0xFF10B981) : Colors.white60,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gamified Progress Bar / Streak
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF97316).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: const [
                            Text("🔥", style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              "5 Day Streak",
                              style: TextStyle(color: Color(0xFFFB923C), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "Sentence ${_currentExerciseIndex + 1} of ${_exercises.length}",
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Main Exercise Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currentExercise.title,
                          style: const TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _currentExercise.difficulty,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Phoneme Highlighter Widget (Tappable sounds)
                    PhonemeHighlighterWidget(
                      words: feedback.words,
                      fallbackSentence: _currentExercise.sentence,
                    ),
                    const SizedBox(height: 14),
                    // IPA Transcription
                    Text(
                      _currentExercise.ipaDisplay,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white54,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentExercise.hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.3),
                    ),
                    const SizedBox(height: 16),
                    // Native Speaker Audio Replay Button
                    GestureDetector(
                      onTap: () => tts.speakSentence(
                        _currentExercise.sentence,
                        accent: _selectedAccent,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: tts.isSpeaking
                              ? const Color(0xFF6366F1).withOpacity(0.3)
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: tts.isSpeaking
                                ? const Color(0xFF818CF8)
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tts.isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                              size: 16,
                              color: tts.isSpeaking ? const Color(0xFF818CF8) : Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tts.isSpeaking ? "Playing Native Audio..." : "Hear Native Pronunciation",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tts.isSpeaking ? const Color(0xFF818CF8) : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Audio Waveform Visualizer
              AudioVisualizerWidget(isRecording: isStreaming),

              const SizedBox(height: 16),

              // Pitch & Prosody Ribbon (Shown if score evaluated or streaming)
              if (feedback.overallScore > 0) ...[
                ProsodyRibbonWidget(
                  prosodyScore: feedback.prosody,
                  sentence: _currentExercise.sentence,
                ),
                const SizedBox(height: 16),
                // Multi-Arc Radial Score Gauge & AI Articulation Tips
                ScoreCardWidget(feedback: feedback),
                const SizedBox(height: 20),
              ],

              // Central Floating Record Button & Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous Exercise Button
                  IconButton(
                    onPressed: () => _prevExercise(liveKit),
                    icon: const Icon(Icons.skip_previous, color: Colors.white60, size: 26),
                    tooltip: "Previous Sentence",
                  ),
                  const SizedBox(width: 14),
                  // Primary Glowing Mic Button
                  GestureDetector(
                    onTap: _isLoadingToken ? null : () => _togglePractice(liveKit),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isStreaming
                              ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                              : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isStreaming
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF6366F1))
                                .withOpacity(0.45),
                            blurRadius: 22,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoadingToken
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                            : Icon(
                                isStreaming ? Icons.stop : Icons.mic,
                                color: Colors.white,
                                size: 36,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Next Exercise Button
                  IconButton(
                    onPressed: () => _nextExercise(liveKit),
                    icon: const Icon(Icons.skip_next, color: Colors.white60, size: 26),
                    tooltip: "Next Sentence",
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isStreaming
                    ? "LiveKit SFU streaming active • Speak naturally"
                    : "Tap mic and speak sentence aloud to evaluate",
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
