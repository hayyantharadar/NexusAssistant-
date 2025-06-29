# Nexus Voice Assistant

A powerful Android voice assistant app with wake word activation, AI integration, and modern UI design inspired by Google Gemini.

## Features

### 🎤 Voice Recognition
- **Wake Word Activation**: Activate with "Nexus" or "N-X-S"
- **Continuous Listening**: Background service for always-on wake word detection
- **Voice Waveform Animation**: Real-time visual feedback during voice input
- **Multi-language Support**: English and Hindi language detection and responses

### 🤖 AI Integration
- **Smart Chat**: Powered by OpenAI GPT or Google Gemini APIs
- **Context-Aware Responses**: Intelligent conversation handling
- **Language Detection**: Automatic Hindi/English detection for appropriate responses
- **Page Summarization**: AI-powered content summarization (placeholder)

### 📱 System Integration
- **WhatsApp Messaging**: Send messages via voice commands
- **App Launcher**: Open any installed app by voice
- **System Controls**: 
  - Wi-Fi toggle
  - Flashlight control
  - Screen lock (with device admin permissions)
- **Entertainment**: Built-in joke collection

### 🔒 Security Features
- **API Key Protection**: Encrypted storage of API keys
- **Enhanced Intruder Detection**: 
  - Silent photo capture after 2 consecutive wrong password attempts
  - Automatic front camera selection (falls back to rear camera if unavailable)
  - Photos saved to `/NexusSecurity/Intruders/` directory with timestamp
  - No UI animations or notifications during capture
- **Access Control**: Secure app access with predefined API key
- **Privacy Protection**: Excludes sensitive data from backups

### 🎨 Modern UI Design
- **Google Gemini Inspired**: Clean, modern interface
- **Dual Theme Support**: Light and dark themes
- **Material Design 3**: Latest Material Design components
- **Responsive Layout**: Optimized for all screen sizes
- **Smooth Animations**: Fluid transitions and micro-interactions

## Installation

### Prerequisites
- Android 7.0 (API level 24) or higher
- Microphone permission for voice commands
- Camera permission for security features
- Internet connection for AI features

### Setup Instructions

1. **Install the APK**
   ```bash
   adb install nexus-assistant.apk
   ```

2. **Grant Permissions**
   - Allow microphone access
   - Allow camera access (required for intruder detection)

3. **Configure API Key**
   - Launch the app
   - Enter the correct API key: `NEXUS_2024_API_KEY_SECURE`
   - For AI features, replace with your actual OpenAI or Gemini API key

4. **Enable Device Admin (Optional)**
   - For screen lock functionality
   - Go to Settings > Security > Device Admin
   - Enable Nexus Assistant

## Security Features

### Intruder Detection System
The app includes a sophisticated intruder detection system:

1. **Trigger**: Activated after 2 consecutive wrong password attempts
2. **Camera Selection**: 
   - Prioritizes front camera for better face capture
   - Automatically falls back to rear camera if front camera unavailable
3. **Silent Operation**: 
   - No animations, toasts, or UI changes during capture
   - Only system-level camera permissions may show
4. **Storage**: Photos saved to `/NexusSecurity/Intruders/` with timestamp-based filenames
5. **Privacy**: No network transmission of captured photos

### Permission Handling
- Camera permission requested via standard Android dialog
- Graceful fallback if permissions denied
- No custom overlays or animations during capture process

## Usage

### Voice Commands

#### Basic Commands
- **"Nexus, send WhatsApp message to [contact]"** - Send WhatsApp message
- **"Nexus, open YouTube"** - Open any installed app
- **"Nexus, turn on Wi-Fi"** - Toggle Wi-Fi
- **"Nexus, turn on flashlight"** - Control flashlight
- **"Nexus, lock my screen"** - Lock device screen
- **"Nexus, tell me a joke"** - Get a random joke
- **"Nexus, what's the weather?"** - Weather information

#### AI Chat
- **"Nexus, [any question]"** - General AI conversation
- **"Nexus, summarize this page"** - Page summarization (requires setup)

#### Supported Apps
- YouTube, Chrome, WhatsApp, Instagram, Facebook
- Twitter, Gmail, Google Maps, Camera, Photos
- Settings and other system apps

### API Key Configuration

#### For Development/Testing
Use the default key: `NEXUS_2024_API_KEY_SECURE`

#### For AI Features
Replace the API key in `ApiKeyActivity.kt`:
```kotlin
private const val CORRECT_API_KEY = "your_actual_api_key_here"
```

Supported API formats:
- **OpenAI**: Keys starting with `sk-`
- **Google Gemini**: Keys starting with `AIza`

## Development

### Building from Source

1. **Clone the Repository**
   ```bash
   git clone [repository-url]
   cd NexusAssistant
   ```

2. **Open in Android Studio**
   - Import the project
   - Sync Gradle files
   - Build and run

3. **Build APK**
   ```bash
   ./gradlew assembleRelease
   ```

### Project Structure
```
app/
├── src/main/
│   ├── java/com/nexus/assistant/
│   │   ├── MainActivity.kt              # Main voice interface
│   │   ├── ApiKeyActivity.kt           # API key validation & intruder detection
│   │   ├── adapter/                    # RecyclerView adapters
│   │   ├── model/                      # Data models
│   │   ├── service/                    # Background services
│   │   ├── receiver/                   # Broadcast receivers
│   │   └── utils/                      # Utility classes
│   ├── res/                           # Resources (layouts, drawables, etc.)
│   └── AndroidManifest.xml           # App configuration
└── build.gradle                      # App-level dependencies
```

### Key Security Components

#### ApiKeyActivity
- Enhanced intruder detection with camera integration
- Silent photo capture without UI feedback
- Automatic camera selection (front → rear fallback)
- Secure photo storage in app-specific directory

#### Camera Integration
- CameraX library for modern camera handling
- Proper permission management
- Error handling for camera unavailability
- No custom animations or overlays during capture

## Customization

### Adding New Commands
1. Update `CommandProcessor.kt`
2. Add command patterns in `processCommand()` method
3. Implement command logic

### Changing Wake Words
1. Update `VoiceService.kt`
2. Modify wake word detection logic
3. Update string resources

### UI Customization
1. Modify themes in `res/values/themes.xml`
2. Update colors in `res/values/colors.xml`
3. Customize layouts in `res/layout/`

### Intruder Detection Customization
1. Modify `captureIntruderPhoto()` in `ApiKeyActivity.kt`
2. Adjust trigger conditions (currently 2 attempts)
3. Change storage location in `getOutputDirectory()`

## Permissions

### Required Permissions
- `RECORD_AUDIO` - Voice recognition
- `INTERNET` - AI API communication
- `CAMERA` - Intruder photo capture

### Optional Permissions
- `ACCESS_WIFI_STATE` / `CHANGE_WIFI_STATE` - Wi-Fi control
- `FLASHLIGHT` - Flashlight control
- `DEVICE_ADMIN` - Screen lock functionality

## Troubleshooting

### Common Issues

1. **Voice Recognition Not Working**
   - Check microphone permissions
   - Ensure device has speech recognition support
   - Test in a quiet environment

2. **AI Features Not Responding**
   - Verify API key configuration
   - Check internet connection
   - Ensure API key has sufficient credits

3. **Intruder Detection Not Working**
   - Verify camera permission is granted
   - Check if device has front/rear camera
   - Ensure storage directory is accessible

4. **App Crashes on Launch**
   - Check Android version compatibility
   - Verify all required permissions are granted
   - Clear app data and restart

5. **Wake Word Not Detected**
   - Speak clearly and at normal volume
   - Ensure background service is running
   - Check notification for service status

## Technical Specifications

- **Minimum SDK**: Android 7.0 (API 24)
- **Target SDK**: Android 14 (API 34)
- **Language**: Kotlin
- **Architecture**: MVVM with Repository pattern
- **Dependencies**: Material Design 3, CameraX, OkHttp, Retrofit

## Recent Updates

### Version 1.1 - Enhanced Security
- ✅ Silent intruder photo capture after 2 wrong attempts
- ✅ Automatic camera selection (front → rear fallback)
- ✅ Secure photo storage in `/NexusSecurity/Intruders/`
- ✅ No UI animations during capture process
- ✅ Improved permission handling
- ✅ Removed deprecated storage permissions

## License

This project is created as a demonstration of Android voice assistant capabilities. Please ensure compliance with relevant API terms of service when using AI features.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review the code documentation
3. Test with the default API key first

---

**Note**: This app requires manual API key configuration for full AI functionality. The default key is for demonstration purposes only. The intruder detection feature operates silently and stores photos locally for security purposes.

