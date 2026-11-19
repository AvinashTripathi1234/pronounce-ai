const fs = require('fs');
const path = require('path');

const clientDir = __dirname;
const androidDir = path.join(clientDir, 'android');
const appDir = path.join(androidDir, 'app');

console.log('--- Patching Android Project for LiveKit & WebRTC (SDK 36, minSdk 24) ---');

// 1. Detect and patch build.gradle or build.gradle.kts
let gradlePath = path.join(appDir, 'build.gradle');
let isKts = false;
if (!fs.existsSync(gradlePath)) {
  gradlePath = path.join(appDir, 'build.gradle.kts');
  isKts = true;
}

if (fs.existsSync(gradlePath)) {
  console.log(`Found Gradle file: ${path.basename(gradlePath)} (isKts: ${isKts})`);
  let gradleContent = fs.readFileSync(gradlePath, 'utf8');

  if (isKts) {
    // Kotlin DSL - target SDK 36 for livekit_client, flutter_webrtc, flutter_tts compatibility
    gradleContent = gradleContent.replace(/compileSdk\s*=.*$/m, 'compileSdk = 36');
    gradleContent = gradleContent.replace(/minSdk\s*=.*$/m, 'minSdk = 24');
    gradleContent = gradleContent.replace(/targetSdk\s*=.*$/m, 'targetSdk = 36');
    
    if (!gradleContent.includes('multiDexEnabled')) {
      gradleContent = gradleContent.replace(
        /(defaultConfig\s*\{[\s\S]*?)(versionName\s*=.*$)/m,
        '$1$2\n        multiDexEnabled = true'
      );
    }
    
    // Ensure release uses debug signing and no shrinking
    if (gradleContent.includes('buildTypes {')) {
      gradleContent = gradleContent.replace(
        /buildTypes\s*\{[\s\S]*?release\s*\{[\s\S]*?\}/m,
        `buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }`
      );
    }
  } else {
    // Groovy DSL - target SDK 36 for livekit_client, flutter_webrtc, flutter_tts compatibility
    gradleContent = gradleContent.replace(/compileSdkVersion\s+.*$/m, 'compileSdkVersion 36');
    gradleContent = gradleContent.replace(/compileSdk\s*=.*$/m, 'compileSdk = 36');
    gradleContent = gradleContent.replace(/minSdkVersion\s+.*$/m, 'minSdkVersion 24');
    gradleContent = gradleContent.replace(/minSdk\s*=.*$/m, 'minSdk = 24');
    gradleContent = gradleContent.replace(/targetSdkVersion\s+.*$/m, 'targetSdkVersion 36');
    gradleContent = gradleContent.replace(/targetSdk\s*=.*$/m, 'targetSdk = 36');

    if (!gradleContent.includes('multiDexEnabled')) {
      gradleContent = gradleContent.replace(
        /(defaultConfig\s*\{[\s\S]*?)(versionName.*$)/m,
        '$1$2\n        multiDexEnabled true'
      );
    }

    // Ensure release uses debug signing and no shrinking
    if (gradleContent.includes('buildTypes {')) {
      gradleContent = gradleContent.replace(
        /buildTypes\s*\{[\s\S]*?release\s*\{[\s\S]*?\}/m,
        `buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled false
            shrinkResources false
        }`
      );
    }
  }

  // Remove any legacy androidx.multidex:multidex dependency since minSdk 24 has native multidex
  gradleContent = gradleContent.replace(/implementation\s*\(?["']androidx\.multidex:multidex:[^"']+["']\)?/g, '// native multidex (minSdk 24)');

  fs.writeFileSync(gradlePath, gradleContent, 'utf8');
  console.log('Successfully patched Gradle build config with compileSdk = 36, minSdk = 24.');
} else {
  console.warn(`No build.gradle found in ${appDir}`);
}

// 2. Patch gradle.properties to suppress AGP multidex warning
const gradlePropsPath = path.join(androidDir, 'gradle.properties');
let props = fs.existsSync(gradlePropsPath) ? fs.readFileSync(gradlePropsPath, 'utf8') : '';
if (!props.includes('MULTIDEX_NOT_NEEDED')) {
  props += '\nandroid.sync.suppressAgpWarnings=MULTIDEX_NOT_NEEDED\n';
  fs.writeFileSync(gradlePropsPath, props, 'utf8');
  console.log('Added MULTIDEX_NOT_NEEDED suppression to gradle.properties.');
}

// 3. Patch AndroidManifest.xml
const manifestPath = path.join(appDir, 'src', 'main', 'AndroidManifest.xml');
if (fs.existsSync(manifestPath)) {
  console.log('Found AndroidManifest.xml');
  let xml = fs.readFileSync(manifestPath, 'utf8');

  const permissions = `
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
`;

  if (!xml.includes('android.permission.RECORD_AUDIO')) {
    xml = xml.replace('<application', permissions + '\n    <application');
    fs.writeFileSync(manifestPath, xml, 'utf8');
    console.log('Successfully injected audio & WebRTC permissions into AndroidManifest.xml.');
  } else {
    console.log('Permissions already present in AndroidManifest.xml.');
  }
} else {
  console.warn(`No AndroidManifest.xml found at ${manifestPath}`);
}

console.log('--- Patch complete ---');
