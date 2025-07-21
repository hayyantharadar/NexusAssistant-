# Nexus Assistant - AI Voice Assistant App

A fully functional, production-ready Android app built with Flutter that serves as an intelligent voice assistant with premium Gemini-style UI and advanced features.

## ✨ Features

### 🎯 Core Features
- **Voice Activation**: Responds to "Nexus" wake word
- **Multi-language Support**: English and Hindi language support
- **AI-Powered Responses**: Works offline with local responses, online with API integration
- **Beautiful UI**: Premium Gemini-style modern interface with light/dark themes
- **Voice Commands**: Full voice interaction with TTS responses

### 📱 Device Control
- **WhatsApp Integration**: Send messages by voice command
- **Phone Controls**: 
  - Wi-Fi on/off
  - Flashlight control
  - Volume adjustment
  - Screen brightness control
  - Battery status
- **App Launching**: Voice commands to open Camera, Gallery, Settings, etc.
- **Screen Analysis**: AI-powered screen content analysis

### 🔒 Security Features
- **Smart Lock System**: 
  - First wrong password: "Wrong password" notification
  - Second wrong attempt: Automatic front camera photo capture
  - Correct password: "Welcome back sir" greeting
- **Biometric Authentication**: Fingerprint/face unlock support
- **Photo Security**: Intruder detection with automatic photo capture

### 💬 Chat Interface
- **Animated Message Bubbles**: Beautiful chat interface with animations
- **Voice Input**: Seamless voice-to-text integration
- **Chat History**: Local storage using Hive database
- **Message Types**: Support for different message types (text, voice, commands, jokes)

### ⚙️ Settings & Customization
- **Theme Toggle**: Light and dark mode support
- **Language Switch**: English/Hindi language toggle
- **API Configuration**: 
  - Gemini API integration
  - OpenAI GPT integration
  - Custom API support
- **Voice Settings**: Sensitivity adjustment, activation phrase customization
- **AI Settings**: Toggle dynamic AI replies vs offline responses

### 🎨 UI/UX Features
- **Lottie Animations**: Smooth animations for empty states
- **Splash Screen**: Animated startup screen
- **Material 3 Design**: Modern Material Design 3 components
- **Responsive Layout**: Optimized for different screen sizes

## 🛠️ Technical Stack

- **Framework**: Flutter 3.19.6
- **Language**: Dart 3.3.4
- **State Management**: Provider pattern
- **Local Database**: Hive (NoSQL)
- **Voice Recognition**: speech_to_text plugin
- **Text-to-Speech**: flutter_tts plugin
- **Security**: local_auth, crypto
- **Device Controls**: Multiple platform-specific plugins
- **UI**: Material 3 with custom theming

## 📋 Permissions

The app requests the following permissions:
- Microphone (voice recognition)
- Camera (security photos)
- Storage (file access)
- Network (API calls)
- Device controls (flashlight, volume, etc.)
- Contacts (WhatsApp integration)
- Phone (call functionality)

## 🚀 Installation

### APK Installation
1. Download the `app-release.apk` file
2. Enable "Install from unknown sources" in Android settings
3. Install the APK
4. Grant required permissions when prompted

### From Source
1. Ensure Flutter SDK is installed
2. Clone/extract the project
3. Run `flutter pub get`
4. Connect Android device or start emulator
5. Run `flutter run` for debug or `flutter build apk --release` for production

## 📱 Usage Guide

### Initial Setup
1. Launch the app and grant permissions
2. Go to Settings to configure:
   - Choose theme (light/dark)
   - Select language (English/Hindi)
   - Set up API key (optional for AI features)
   - Configure voice settings

### Voice Commands Examples
- **General**: "Hello", "What time is it?", "Tell me a joke"
- **Device Control**: "Turn on flashlight", "Increase volume", "Turn off Wi-Fi"
- **Apps**: "Open camera", "Open settings", "Open gallery"
- **WhatsApp**: "Send WhatsApp message to [contact]"
- **System**: "Check battery", "System status"

### Security Setup
1. Enable Smart Lock in settings
2. Set a secure password
3. Configure biometric authentication (if supported)
4. Test the security system

## 🔧 Configuration

### API Setup (Optional)
1. **Gemini API**:
   - Get API key from Google AI Studio
   - Enter in Settings > API Configuration
   - Select "Gemini" as provider

2. **OpenAI API**:
   - Get API key from OpenAI
   - Enter in Settings > API Configuration  
   - Select "OpenAI" as provider

### Voice Configuration
- Adjust voice sensitivity in settings
- Customize activation phrase (default: "Nexus")
- Enable/disable auto-listening

## 🏗️ Architecture

```
lib/
├── models/           # Data models (ChatMessage, AppSettings)
├── services/         # Core services (Voice, AI, Device, Security, Database)
├── providers/        # State management providers
├── ui/
│   ├── screens/     # App screens
│   ├── widgets/     # Reusable UI components
│   └── theme/       # App theming
└── l10n/            # Localization files
```

## 🔄 Offline vs Online Mode

### Offline Mode
- Basic conversation responses
- Device control commands
- Pre-programmed jokes and responses
- App launching and system controls

### Online Mode (with API)
- Advanced AI conversations
- Context-aware responses
- Dynamic content generation
- Enhanced natural language understanding

## 🐛 Troubleshooting

### Common Issues
1. **Voice not working**: Check microphone permissions
2. **API not responding**: Verify API key and internet connection
3. **App crashing**: Ensure all permissions are granted
4. **Security features not working**: Check camera permissions

### Performance Tips
- Clear chat history periodically
- Keep app updated
- Restart device if voice recognition becomes slow
- Check available storage space

## 📄 License

This project is a demonstration/educational application. All rights reserved.

## 🤝 Contributing

This is a complete, production-ready application. For custom modifications or enterprise features, please contact the development team.

## 📞 Support

For technical support or feature requests, please refer to the documentation or contact support.

---

**Nexus Assistant** - Your Intelligent Voice Companion 🤖✨

