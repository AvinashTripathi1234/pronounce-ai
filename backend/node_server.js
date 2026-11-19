/**
 * PronounceAI - Node.js Companion / Fast Local Server
 * Zero-dependency server using Node.js built-in modules.
 * Runs on http://localhost:8000 to instantly serve Flutter client.
 */

const http = require('http');
const url = require('url');

const PORT = process.env.PORT || 8000;

const EXERCISES = [
  {
    id: "ex-1",
    title: "Voiced & Voiceless 'TH'",
    sentence: "The weather is better through the storm",
    ipa_display: "ðə ˈwɛðər ɪz ˈbɛtər θruː ðə stɔːrm",
    difficulty: "Intermediate",
    target_phonemes: ["ð", "θ", "ɛ"],
    hint: "Contrast the voiced /ð/ in 'the' with the unvoiced /θ/ in 'through'."
  },
  {
    id: "ex-2",
    title: "Rhotic R & Liquids",
    sentence: "Practice makes perfect pronunciation",
    ipa_display: "ˈpræktɪs meɪks ˈpɜːrfɪkt prəˌnʌnsiˈeɪʃən",
    difficulty: "Advanced",
    target_phonemes: ["ɜːr", "æ", "ʃ"],
    hint: "Curl the tongue back for /ɜːr/ in 'perfect' without touching the palate."
  },
  {
    id: "ex-3",
    title: "Pacing and Articulation",
    sentence: "The quick brown fox jumps over the lazy dog",
    ipa_display: "ðə kwɪk braʊn fɒks dʒʌmps ˈoʊvər ðə ˈleɪzi dɔːɡ",
    difficulty: "Beginner",
    target_phonemes: ["kw", "dʒ", "z"],
    hint: "Keep words connected smoothly while hitting crisp consonants."
  },
  {
    id: "ex-4",
    title: "Short Vowel Distinction /æ/ vs /ɛ/",
    sentence: "The cat sat on the red bed",
    ipa_display: "ðə kæt sæt ɒn ðə rɛd bɛd",
    difficulty: "Beginner",
    target_phonemes: ["æ", "ɛ"],
    hint: "Drop your jaw lower for /æ/ in 'cat' compared to /ɛ/ in 'bed'."
  },
  {
    id: "ex-5",
    title: "Postalveolar & Sibilants",
    sentence: "She sells sea shells by the sunny seashore",
    ipa_display: "ʃiː sɛlz siː ʃɛlz baɪ ðə ˈsʌni ˈsiːʃɔːr",
    difficulty: "Advanced",
    target_phonemes: ["ʃ", "s", "z"],
    hint: "Switch cleanly between the /s/ alveolar hiss and /ʃ/ postalveolar flare."
  }
];

const DICTIONARY_IPA = {
  "the": ["ð", "ə"],
  "weather": ["w", "ɛ", "ð", "ər"],
  "is": ["ɪ", "z"],
  "better": ["b", "ɛ", "t", "ər"],
  "through": ["θ", "r", "uː"],
  "storm": ["s", "t", "ɔː", "r", "m"],
  "practice": ["p", "r", "æ", "k", "t", "ɪ", "s"],
  "makes": ["m", "eɪ", "k", "s"],
  "perfect": ["p", "ɜːr", "f", "ɪ", "k", "t"],
  "pronunciation": ["p", "r", "ə", "n", "ʌ", "n", "s", "i", "eɪ", "ʃ", "ə", "n"],
  "quick": ["k", "w", "ɪ", "k"],
  "brown": ["b", "r", "aʊ", "n"],
  "fox": ["f", "ɒ", "k", "s"],
  "jumps": ["dʒ", "ʌ", "m", "p", "s"],
  "over": ["oʊ", "v", "ər"],
  "lazy": ["l", "eɪ", "z", "i"],
  "dog": ["d", "ɔː", "ɡ"]
};

function generateEvaluation(sentence) {
  const words = sentence.toLowerCase().replace(/[,.!?]/g, '').split(' ');
  let allScores = [];

  const evaluatedWords = words.map((w, wIdx) => {
    const phonemes = DICTIONARY_IPA[w] || w.split('');
    const pResults = phonemes.map((p, pIdx) => {
      const isHard = ['θ', 'ð', 'ɜːr', 'æ', 'ʃ'].includes(p);
      const score = isHard ? Math.floor(70 + Math.random() * 16) : Math.floor(88 + Math.random() * 11);
      allScores.push(score);

      let status = 'correct';
      if (score < 72) status = 'mispronounced';
      else if (score < 84) status = 'acceptable';

      return {
        phoneme: p,
        score: score,
        status: status,
        start_time: (wIdx * 0.4) + (pIdx * 0.08),
        end_time: (wIdx * 0.4) + ((pIdx + 1) * 0.08)
      };
    });

    const wScore = Math.round(pResults.reduce((a, b) => a + b.score, 0) / pResults.length);
    return {
      word: w,
      score: wScore,
      phonemes: pResults
    };
  });

  const accuracy = Math.round(allScores.reduce((a, b) => a + b, 0) / Math.max(1, allScores.length));
  const fluency = Math.round(accuracy * 0.95);
  const prosody = Math.round(accuracy * 0.92);
  const completeness = 100;
  const overall = Math.round((accuracy * 0.4) + (fluency * 0.25) + (prosody * 0.25) + (completeness * 0.1));

  return {
    overall_score: overall,
    accuracy: accuracy,
    fluency: fluency,
    prosody: prosody,
    completeness: completeness,
    words: evaluatedWords,
    tips: [
      "Phoneme /θ/: Place tongue gently between your front teeth without biting.",
      "Intonation tip: Emphasize key content words for natural prosody rhythm."
    ]
  };
}

const server = http.createServer((req, res) => {
  // CORS Headers for Flutter Client
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;

  // 1. Health Endpoint
  if (path === '/api/health' || path === '/') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', server: 'pronounce-ai-node-companion', version: '1.0.0' }));
  }
  // 2. Exercises List
  else if (path === '/api/exercises') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(EXERCISES));
  }
  // 3. Recommended LiveKit Join Token Endpoint: GET /api/v1/rooms/join-token
  else if (path === '/api/v1/rooms/join-token' || path === '/api/sessions/token') {
    const roomName = parsedUrl.query.room_name || `room-${Math.random().toString(36).substr(2, 8)}`;
    const identity = parsedUrl.query.identity || `learner-${Math.random().toString(36).substr(2, 6)}`;
    
    // Generates test JWT
    const token = `mock-livekit-jwt-${Buffer.from(JSON.stringify({ room: roomName, identity })).toString('base64')}`;

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      token: token,
      room_name: roomName,
      livekit_url: 'ws://127.0.0.1:7880',
      participant_identity: identity
    }));
  }
  // 4. Session Evaluation Endpoint
  else if (path === '/api/sessions/evaluate' || path === '/api/v1/evaluate') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const data = JSON.parse(body || '{}');
        const sentence = data.target_sentence || EXERCISES[0].sentence;
        const result = generateEvaluation(sentence);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON payload' }));
      }
    });
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Endpoint not found' }));
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 PronounceAI Backend Companion running on http://localhost:${PORT}`);
  console.log(`   • Endpoints: /api/exercises, /api/v1/rooms/join-token, /api/sessions/evaluate`);
});
