# 📲 How to Build the APK & Share PronounceAI with Friends

To share PronounceAI so friends can install it on their Android phones, there are two quick parts:
1. **Generating the `.apk` file** (the installable Android app)
2. **Making your backend reachable by their phones** (since their phones can't reach your PC's `localhost`)

---

## 🏗️ Part 1: How to Generate the `.apk` File

### Method A: Zero-Install Cloud Build via GitHub (Easiest & Fastest)
You don't need to install 15GB of Android Studio, Gradle, or Java on your PC. We created an automated GitHub Actions pipeline in [`.github/workflows/build_apk.yml`](file:///C:/Users/avina/.gemini/antigravity/scratch/pronounce-ai/.github/workflows/build_apk.yml).

1. Push this `pronounce-ai` folder to a GitHub repository:
   ```bash
   git init
   git add .
   git commit -m "PronounceAI Initial Release"
   git branch -M main
   git remote add origin https://github.com/<YOUR_USERNAME>/pronounce-ai.git
   git push -u origin main
   ```
2. Go to your GitHub repository in your browser ➔ Click the **Actions** tab.
3. The **"Build Android APK"** action will run automatically (~3 minutes).
4. When finished, click the build run ➔ Under **Artifacts**, download `pronounce-ai-apk.zip`.
5. Inside is `app-arm64-v8a-release.apk`! Send this file directly to friends.

---

### Method B: Build Locally on Your PC (If Flutter & Android SDK are installed)
```powershell
cd C:\Users\avina\.gemini\antigravity\scratch\pronounce-ai\client
flutter build apk --release --split-per-abi
```
Your compiled `.apk` will be waiting at:
`C:\Users\avina\.gemini\antigravity\scratch\pronounce-ai\client\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`

---

## 🌐 Part 2: Letting Friends' Phones Reach Your Backend

When your friends open the app on their phone, `http://localhost:8000` won't work because `localhost` refers to their phone, not your computer.

### Option 1: Quick Free Public Tunnel (1 Command)
Run this in PowerShell to give your running backend a free public HTTPS web address:
```powershell
npx localtunnel --port 8000
```
It will output a link like:
`https://clean-badger-22.loca.lt`

### Option 2: Same Wi-Fi Network (LAN)
If you and your friends are on the same home or office Wi-Fi, find your computer's local IP address:
```powershell
ipconfig
```
Look for `IPv4 Address` (e.g. `192.168.1.15`). Your backend is reachable at:
`http://192.168.1.15:8000`

---

## ⚙️ How Friends Connect Inside the App

We added a **⚙️ Server Settings** icon directly in the top right of the app bar in [`practice_screen.dart`](file:///C:/Users/avina/.gemini/antigravity/scratch/pronounce-ai/client/lib/screens/practice_screen.dart):
1. Friends tap the **⚙️** icon.
2. Paste the public URL (e.g. `https://clean-badger-22.loca.lt` or `http://192.168.1.15:8000`).
3. Tap **Save & Connect**. The app immediately connects and fetches exercises!

---

## 📤 Part 3: Sending the App to Friends

1. Send `app-arm64-v8a-release.apk` via:
   * **Google Drive / Dropbox link**
   * **WhatsApp Document attachment**
   * **Telegram / Discord file send**
2. On their Android phone, they tap the `.apk` file and select **Install**.
   *(If prompted, tap "Settings" and toggle "Allow from this source")*.
3. Open **PronounceAI** and practice speaking!
