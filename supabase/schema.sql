-- Supabase / PostgreSQL Schema for PronounceAI

-- 1. Profiles Table (linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    display_name TEXT,
    native_language TEXT DEFAULT 'en',
    target_accent TEXT DEFAULT 'General American',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Exercises Table
CREATE TABLE IF NOT EXISTS public.exercises (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    sentence TEXT NOT NULL,
    ipa_display TEXT NOT NULL,
    difficulty TEXT CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')),
    target_phonemes TEXT[] NOT NULL DEFAULT '{}',
    hint TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Practice Sessions Table (Stores LiveKit WebRTC Session Results)
CREATE TABLE IF NOT EXISTS public.practice_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    exercise_id TEXT REFERENCES public.exercises(id) ON DELETE SET NULL,
    room_name TEXT NOT NULL,
    overall_score NUMERIC(5, 2) NOT NULL,
    accuracy_score NUMERIC(5, 2) NOT NULL,
    fluency_score NUMERIC(5, 2) NOT NULL,
    prosody_score NUMERIC(5, 2) NOT NULL,
    completeness_score NUMERIC(5, 2) NOT NULL,
    audio_duration_seconds NUMERIC(6, 2),
    coaching_tips TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Phoneme Score Details (Detailed phonetic breakdown per session)
CREATE TABLE IF NOT EXISTS public.phoneme_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.practice_sessions(id) ON DELETE CASCADE,
    word TEXT NOT NULL,
    phoneme TEXT NOT NULL,
    score NUMERIC(5, 2) NOT NULL,
    status TEXT CHECK (status IN ('correct', 'acceptable', 'mispronounced')),
    start_time NUMERIC(6, 3),
    end_time NUMERIC(6, 3)
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.phoneme_scores ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Public exercises are viewable by everyone" 
ON public.exercises FOR SELECT USING (true);

CREATE POLICY "Users can view own profile" 
ON public.profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own practice sessions" 
ON public.practice_sessions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own practice sessions" 
ON public.practice_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view phoneme scores of their sessions" 
ON public.phoneme_scores FOR SELECT 
USING (session_id IN (SELECT id FROM public.practice_sessions WHERE user_id = auth.uid()));

-- Insert Initial Seed Data
INSERT INTO public.exercises (id, title, sentence, ipa_display, difficulty, target_phonemes, hint)
VALUES 
('ex-1', 'Voiced & Voiceless TH', 'The weather is better through the storm', 'ðə ˈwɛðər ɪz ˈbɛtər θruː ðə stɔːrm', 'Intermediate', ARRAY['ð', 'θ', 'ɛ'], 'Contrast voiced /ð/ in the with unvoiced /θ/ in through.'),
('ex-2', 'Rhotic R & Liquids', 'Practice makes perfect pronunciation', 'ˈpræktɪs meɪks ˈpɜːrfɪkt prəˌnʌnsiˈeɪʃən', 'Advanced', ARRAY['ɜːr', 'æ', 'ʃ'], 'Curl the tongue back for /ɜːr/ in perfect without touching the palate.'),
('ex-3', 'Pacing & Articulation', 'The quick brown fox jumps over the lazy dog', 'ðə kwɪk braʊn fɒks dʒʌmps ˈoʊvər ðə ˈleɪzi dɔːɡ', 'Beginner', ARRAY['kw', 'dʒ', 'z'], 'Keep words connected smoothly while hitting crisp consonants.')
ON CONFLICT (id) DO NOTHING;
