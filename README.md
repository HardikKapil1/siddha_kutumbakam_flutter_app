# 🌿 Siddha Kutumbakam — Mindful Reminder App

> **A battery-efficient, cross-platform mindfulness & breathing reminder application.**  
> Built with Flutter for Android, iOS, and Web.

---

## 📖 Table of Contents
1. [What is Siddha Kutumbakam?](#-what-is-siddha-kutumbakam)
2. [How the App Works (In Short)](#-how-the-app-works-in-short)
3. [Project Folder & File Structure](#-project-folder--file-structure)
4. [For Clients: How to Install APK on Android (No Setup Required)](#-for-clients-how-to-install-apk-on-android-no-setup-required)
5. [How to Share & Open on iOS (Apple iPhone)](#-how-to-share--open-on-ios-apple-iphone)
6. [How to Share & Open on Web (Instant Browser Access)](#-how-to-share--open-on-web-instant-browser-access)
7. [How to Connect Android Phone Wirelessly (No Cables)](#-how-to-connect-android-phone-wirelessly-no-cables)
8. [Developer Setup (Without Android Studio)](#-developer-setup-without-android-studio)
9. [What to Do After `flutter clean` (Step-by-Step Guide)](#-what-to-do-after-flutter-clean-step-by-step-guide)
10. [Key Features & Behavior Rules](#-key-features--behavior-rules)


---

## 🌟 What is Siddha Kutumbakam?

**Siddha Kutumbakam** is a mindful breathing companion that helps users maintain daily wellness through customizable audio chimes, dual-pulse vibrations, and banner notifications for:
- **Exhale (प्रश्वास)** mindfulness cues
- **Taste / Inhale (स्वाद / श्वास)** awareness cues

---

## ⚡ How the App Works (In Short)

1. **Battery-Efficient Event Scheduling (0% Background CPU Drain)**:  
   Unlike ordinary apps that keep battery-draining background timers running 24/7, this app registers exact alarms directly with the Android/iOS operating system (`exactAllowWhileIdle`). The app goes to sleep, and the phone OS wakes it up *only* for a split-second at the exact scheduled time to play the chime, vibrate, and show the notification.
2. **Flexible Timing**:  
   Set reminders **Periodically** (e.g., every 5, 10, or 15 minutes) or **Randomly** (e.g., 4 times per hour).
3. **Notification Modes**:  
   - 🔔 **Sound & Vibration**: Plays chime sound + dual-pulse vibration + notification banner.
   - 📳 **Vibration Only**: Silent dual-pulse vibration + notification banner.
   - 🔕 **Silent**: Visual notification banner only.
4. **Smart Priority Pause Matrix**:  
   - 🔴 **Global Master Pause**: Temporarily halts all reminders with a single tap from Home or Settings.
   - 🌙 **Night Sleep Hours**: Automatically stays silent during your scheduled sleep time (e.g., 10:00 PM to 07:00 AM).
   - 📅 **Meeting Pauses**: Custom temporary pause blocks for specific dates & hours.
   - 🔒 **Configuration Preservation Rule**: Pausing or entering night mode **never** erases or turns off your individual switch settings.

---

## 📁 Project Folder & File Structure

Here is the complete layout of the codebase and what each file and folder does:

```text
siddha_kutumbakam_flutter_app/
├── 📁 android/                     # Native Android project configuration & permissions
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml     # Defines permissions (Exact Alarms, Notifications, Vibration)
│   │   └── res/                    # App icons, splash screens, notification drawables
│   └── build.gradle                # Android build configs & SDK versions
│
├── 📁 ios/                         # Native iOS project configuration (Xcode files)
│   └── Runner/
│       ├── Info.plist              # iOS app permissions & background execution modes
│       └── Assets.xcassets         # iOS app icons & launch images
│
├── 📁 web/                         # Web build template & HTML entry
│   ├── index.html                  # Web container entry point
│   ├── manifest.json               # Progressive Web App (PWA) configuration
│   └── favicon.png                 # Web tab icon
│
├── 📁 assets/                      # Bundled static media files
│   ├── 📁 audio/                   # Mindfulness sound assets
│   │   ├── exhale.mp3              # Audio chime for Exhale reminders
│   │   └── taste.mp3               # Audio chime for Taste/Inhale reminders
│   └── 📁 images/                  # Siddha Kutumbakam branding & logos
│       ├── logo.png
│       └── logo2.png
│
├── 📁 lib/                         # 💡 MAIN APPLICATION SOURCE CODE (Dart)
│   ├── main.dart                   # App entry point; initializes local notifications & state
│   ├── app.dart                    # App root widget, Material 3 theme, tabs router
│   │
│   ├── 📁 core/                    # Core business logic, storage & system services
│   │   ├── reminder_state.dart     # Central State Manager (handles timing, frequencies,
│   │   │                           # pause/resume states, meetings, SharedPreferences persistence)
│   │   ├── notification_service.dart # OS-level alarm scheduling, vibration triggers,
│   │   │                           # and persistent lock screen / notification drawer controls
│   │   ├── audio_service.dart      # Audio player engine (plays MP3 chimes on demand)
│   │   └── language.dart           # Complete English & Hindi bilingual localization dictionary
│   │
│   └── 📁 pages/                   # User Interface Screens (UI)
│       ├── home_page.dart          # Home dashboard (live status, quick triggers, master pause/resume)
│       ├── settings_page.dart      # Configuration page (interval sliders, sound/vibe toggles, night mode)
│       └── profile_page.dart       # User profile, language switch (English/Hindi), about information
│
├── 📁 test/                        # Automated unit & integration tests
│   ├── reminder_config_test.dart   # Automated test suite covering all 24 functional specifications
│   └── widget_test.dart            # Flutter UI sanity test
│
├── 📁 build/                       # Generated binaries & build artifacts
│   └── app/outputs/flutter-apk/    # 🎯 Output folder where app-release.apk is generated
│
├── pubspec.yaml                    # Flutter project dependency manifest (libraries, assets, fonts)
└── README.md                       # This documentation guide
```

---

## 📱 For Clients: How to Install APK on Android (No Setup Required)

If you are a client or tester who just wants to **install and use the app on an Android phone**:

### Step 1: Get the APK File
The pre-compiled standalone release APK is located at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

### Step 2: Share it to the Phone
You can send this `.apk` file using any of the following easy methods:
- **WhatsApp / Telegram**: Send the `app-release.apk` file directly in a chat.
- **Google Drive / Dropbox**: Upload the file and open the download link on your phone.
- **USB Cable**: Plug the phone into your PC and copy `app-release.apk` to your phone's **Download** folder.

### Step 3: Install on the Phone
1. Open the file on your phone (tap it in WhatsApp, Files, or Downloads).
2. If prompted: **"For your security, your phone is not allowed to install unknown apps from this source"**:
   - Tap **Settings**.
   - Toggle **Allow from this source** to **ON**.
   - Tap **Back** and tap **Install**.
3. Tap **Open**.
4. When opened for the first time:
   - Tap **Allow** for Notifications.
   - Tap **Allow** for Alarms & Reminders if requested.

> ✅ **Done!** The app is now installed and works completely offline without needing any computer connection.

---

## 🍏 How to Share & Open on iOS (Apple iPhone)

Apple does not allow direct `.apk` downloads. Here are the 3 ways to share and run the app on iPhone:

### Method A: Apple TestFlight (Recommended for Clients)
1. The developer creates an Apple Developer Account and builds the iOS archive.
2. Uploads the build to **App Store Connect / TestFlight**.
3. Shares a **TestFlight Public Invitation Link** with the client.
4. The client downloads the free **TestFlight app** from the Apple App Store, taps the link, and installs the app with one click.

### Method B: Diawi / InstallOnAir (Ad-Hoc Wireless Sharing)
1. The developer registers the client's iPhone UDID.
2. Builds an `.ipa` file using `flutter build ipa`.
3. Uploads to [Diawi.com](https://www.diawi.com).
4. Sends the Diawi link to the client, who opens it in Safari to install directly.

### Method C: Run via Mac & Xcode (For Developers)
Connect iPhone via USB or Wi-Fi to a Mac and run:
```bash
flutter run -d ios
```

---

## 🌐 How to Share & Open on Web (Instant Browser Access)

You can run and share the app as a web link accessible from **any laptop, tablet, or smartphone browser**:

### 1. Build the Web Application
```bash
flutter build web --release
```
This generates optimized HTML/JS/CSS files in the `build/web/` folder.

### 2. Share / Deploy in 1 Minute (Free)
- **Netlify Drop**: Go to [app.netlify.com/drop](https://app.netlify.com/drop), drag and drop the `build/web/` folder. You will get a live `https://your-app.netlify.app` link instantly.
- **Vercel / GitHub Pages**: Push the repository and deploy static files.

### 3. Run Locally in Browser
```bash
flutter run -d chrome
```

---

## 📶 How to Connect Android Phone Wirelessly (No Cables)

You can run, test, and debug on an Android phone over Wi-Fi without any USB cable or Android Studio:

### Prerequisites:
- Your computer and Android phone must be connected to the **same Wi-Fi network**.
- Android 11+ on your phone.

### Step-by-Step Wireless Connection:
1. **Enable Developer Options on Phone**:
   - Go to phone **Settings** → **About Phone** → Tap **Build Number** 7 times until you see *"You are now a developer!"*.
2. **Enable Wireless Debugging**:
   - Go to **Settings** → **Developer Options** → Enable **Wireless Debugging**.
   - Tap on **Wireless Debugging** → Tap **Pair device with pairing code**.
   - Note the **IP address, port number, and 6-digit pairing code** shown on screen.
3. **Pair from Computer Command Prompt / Terminal**:
   ```bash
   adb pair <IP_ADDRESS>:<PORT>
   # Enter the 6-digit pairing code when prompted
   ```
4. **Connect**:
   ```bash
   adb connect <IP_ADDRESS>:<PORT>
   ```
5. **Run the App**:
   ```bash
   flutter run
   ```
   The app will automatically launch on your phone over Wi-Fi!

---

## 🛠️ Developer Setup (Without Android Studio)

You do **NOT** need the heavy Android Studio IDE to run or build this project. You only need the lightweight Flutter SDK and Command Prompt / Terminal / VS Code:

### 1. Check Flutter Health
```bash
flutter doctor
```

---

## 🧹 What to Do After `flutter clean` (Step-by-Step Guide)

Running `flutter clean` deletes all temporary build files and Gradle caches (freeing up ~2.4 GB of disk space). Whenever you run `flutter clean`, follow these exact steps to rebuild and run the app:

### Step 1: Restore Dependencies (Mandatory)
Always run `flutter pub get` first. This restores all required plugins and packages:
```bash
flutter pub get
```

### Step 2: Run Verification Tests (Optional, Recommended)
Verify that all 24 functional specifications and state rules pass:
```bash
flutter test
```

### Step 3: Choose How You Want to Build / Run

#### Option A: Run Live on Your Connected Phone / Emulator
```bash
flutter run
```

#### Option B: Build Universal Release APK (~65 MB — works on all Android devices)
```bash
flutter build apk --release
```
📍 *Output file:* `build/app/outputs/flutter-apk/app-release.apk`

#### Option C: Build Compact Split APKs (~22 MB — lightweight per CPU)
```bash
flutter build apk --split-per-abi
```
📍 *Output files:*
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` *(for modern smartphones)*
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` *(for older 32-bit phones)*

#### Option D: Build Web Production Files
```bash
flutter build web --release
```
📍 *Output folder:* `build/web/`

#### Option E: Build iOS Archive (On Mac)
```bash
flutter build ipa --release
```

---

## 📋 Key Features & Behavior Rules

| Feature | Behavior |
|---|---|
| **Exhale & Taste Toggles** | Can be independently toggled ON or OFF. |
| **Periodic Mode** | Triggers consistently every *N* minutes (e.g., 5 min, 10 min). |
| **Random Mode** | Distributes reminders randomly *N* times per hour. |
| **Master Pause Button** | Red `▶ Pause` button pauses all reminders immediately. Green `⏸ Resume` button resumes them. |
| **Night Sleep Window** | Automatically suppresses sound and vibration between bedtime hours (default: 22:00 to 07:00). |
| **Meeting Pauses** | Allows scheduling temporary silent blocks for work or meetings. |
| **Bilingual Support** | Instant toggle between English and Hindi across all screens. |
| **Offline First** | Does not require internet access, logins, or external servers to operate. |

---

## 🤝 Support & Maintenance
For questions, customization requests, or new feature additions, please contact the development team.
