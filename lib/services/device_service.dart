import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:torch_light/torch_light.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  // Flashlight control
  Future<bool> toggleFlashlight({bool? turnOn}) async {
    try {
      if (turnOn == null) {
        // Toggle current state
        final isOn = await TorchLight.isTorchAvailable();
        if (isOn) {
          await TorchLight.disableTorch();
          return false;
        } else {
          await TorchLight.enableTorch();
          return true;
        }
      } else {
        if (turnOn) {
          await TorchLight.enableTorch();
        } else {
          await TorchLight.disableTorch();
        }
        return turnOn;
      }
    } catch (e) {
      debugPrint('Error controlling flashlight: $e');
      return false;
    }
  }

  // Volume control
  Future<bool> setVolume(double volume) async {
    try {
      await VolumeController().setVolume(volume);
      return true;
    } catch (e) {
      debugPrint('Error setting volume: $e');
      return false;
    }
  }

  Future<bool> increaseVolume() async {
    try {
      final currentVolume = await VolumeController().getVolume();
      final newVolume = (currentVolume + 0.1).clamp(0.0, 1.0);
      await VolumeController().setVolume(newVolume);
      return true;
    } catch (e) {
      debugPrint('Error increasing volume: $e');
      return false;
    }
  }

  Future<bool> decreaseVolume() async {
    try {
      final currentVolume = await VolumeController().getVolume();
      final newVolume = (currentVolume - 0.1).clamp(0.0, 1.0);
      await VolumeController().setVolume(newVolume);
      return true;
    } catch (e) {
      debugPrint('Error decreasing volume: $e');
      return false;
    }
  }

  Future<double> getCurrentVolume() async {
    try {
      return await VolumeController().getVolume();
    } catch (e) {
      debugPrint('Error getting volume: $e');
      return 0.5;
    }
  }

  // Brightness control
  Future<bool> setBrightness(double brightness) async {
    try {
      await ScreenBrightness().setScreenBrightness(brightness);
      return true;
    } catch (e) {
      debugPrint('Error setting brightness: $e');
      return false;
    }
  }

  Future<bool> increaseBrightness() async {
    try {
      final currentBrightness = await ScreenBrightness().current;
      final newBrightness = (currentBrightness + 0.1).clamp(0.0, 1.0);
      await ScreenBrightness().setScreenBrightness(newBrightness);
      return true;
    } catch (e) {
      debugPrint('Error increasing brightness: $e');
      return false;
    }
  }

  Future<bool> decreaseBrightness() async {
    try {
      final currentBrightness = await ScreenBrightness().current;
      final newBrightness = (currentBrightness - 0.1).clamp(0.0, 1.0);
      await ScreenBrightness().setScreenBrightness(newBrightness);
      return true;
    } catch (e) {
      debugPrint('Error decreasing brightness: $e');
      return false;
    }
  }

  Future<double> getCurrentBrightness() async {
    try {
      return await ScreenBrightness().current;
    } catch (e) {
      debugPrint('Error getting brightness: $e');
      return 0.5;
    }
  }

  // WiFi control
  Future<bool> toggleWiFi({bool? turnOn}) async {
    try {
      if (Platform.isAndroid) {
        if (turnOn == null) {
          // Check current state and toggle
          final isConnected = await _connectivity.checkConnectivity();
          if (isConnected == ConnectivityResult.wifi) {
            return await WiFiForIoTPlugin.setWiFiAPEnabled(false);
          } else {
            return await WiFiForIoTPlugin.setWiFiAPEnabled(true);
          }
        } else {
          return await WiFiForIoTPlugin.setWiFiAPEnabled(turnOn);
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error controlling WiFi: $e');
      return false;
    }
  }

  // Battery information
  Future<BatteryInfo> getBatteryInfo() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      
      return BatteryInfo(
        level: level,
        isCharging: state == BatteryState.charging,
        state: state,
      );
    } catch (e) {
      debugPrint('Error getting battery info: $e');
      return BatteryInfo(level: 0, isCharging: false, state: BatteryState.unknown);
    }
  }

  // Connectivity information
  Future<ConnectivityInfo> getConnectivityInfo() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return ConnectivityInfo(
        type: result,
        isConnected: result != ConnectivityResult.none,
      );
    } catch (e) {
      debugPrint('Error getting connectivity info: $e');
      return ConnectivityInfo(
        type: ConnectivityResult.none,
        isConnected: false,
      );
    }
  }

  // App launching
  Future<bool> openApp(String appName) async {
    try {
      if (Platform.isAndroid) {
        final packageNames = {
          'camera': 'com.android.camera',
          'gallery': 'com.google.android.apps.photos',
          'settings': 'com.android.settings',
          'contacts': 'com.android.contacts',
          'phone': 'com.android.dialer',
          'messages': 'com.google.android.apps.messaging',
          'browser': 'com.android.chrome',
          'calculator': 'com.android.calculator2',
          'calendar': 'com.google.android.calendar',
          'music': 'com.google.android.music',
        };

        final packageName = packageNames[appName.toLowerCase()];
        if (packageName != null) {
          final intent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: packageName,
          );
          await intent.launch();
          return true;
        }

        // Fallback to generic intents
        final intents = {
          'camera': AndroidIntent(action: 'android.media.action.IMAGE_CAPTURE'),
          'gallery': AndroidIntent(action: 'android.intent.action.VIEW', type: 'image/*'),
          'settings': AndroidIntent(action: 'android.settings.SETTINGS'),
          'phone': AndroidIntent(action: 'android.intent.action.DIAL'),
          'browser': AndroidIntent(action: 'android.intent.action.VIEW', data: 'https://google.com'),
        };

        final intent = intents[appName.toLowerCase()];
        if (intent != null) {
          await intent.launch();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error opening app $appName: $e');
      return false;
    }
  }

  // WhatsApp message sending
  Future<bool> sendWhatsAppMessage(String recipient, String message) async {
    try {
      // First try to open WhatsApp with specific contact
      final whatsappUrl = 'whatsapp://send?phone=$recipient&text=${Uri.encodeComponent(message)}';
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
        return true;
      }

      // Fallback to web WhatsApp
      final webUrl = 'https://wa.me/$recipient?text=${Uri.encodeComponent(message)}';
      if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl));
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error sending WhatsApp message: $e');
      return false;
    }
  }

  // Phone call
  Future<bool> makePhoneCall(String phoneNumber) async {
    try {
      final telUrl = 'tel:$phoneNumber';
      if (await canLaunchUrl(Uri.parse(telUrl))) {
        await launchUrl(Uri.parse(telUrl));
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error making phone call: $e');
      return false;
    }
  }

  // System settings
  Future<bool> openSystemSettings(String settingType) async {
    try {
      if (Platform.isAndroid) {
        final settingsMap = {
          'wifi': 'android.settings.WIFI_SETTINGS',
          'bluetooth': 'android.settings.BLUETOOTH_SETTINGS',
          'location': 'android.settings.LOCATION_SOURCE_SETTINGS',
          'sound': 'android.settings.SOUND_SETTINGS',
          'display': 'android.settings.DISPLAY_SETTINGS',
          'security': 'android.settings.SECURITY_SETTINGS',
          'apps': 'android.settings.APPLICATION_SETTINGS',
          'storage': 'android.settings.INTERNAL_STORAGE_SETTINGS',
          'battery': 'android.settings.BATTERY_SAVER_SETTINGS',
        };

        final action = settingsMap[settingType.toLowerCase()];
        if (action != null) {
          final intent = AndroidIntent(action: action);
          await intent.launch();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error opening system settings: $e');
      return false;
    }
  }

  // Device lock (requires system permissions)
  Future<bool> lockDevice() async {
    try {
      if (Platform.isAndroid) {
        // This requires device admin permissions
        const channel = MethodChannel('device_control');
        final result = await channel.invokeMethod('lockDevice');
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error locking device: $e');
      return false;
    }
  }

  // Screenshot (requires additional permissions)
  Future<bool> takeScreenshot() async {
    try {
      if (Platform.isAndroid) {
        const channel = MethodChannel('device_control');
        final result = await channel.invokeMethod('takeScreenshot');
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error taking screenshot: $e');
      return false;
    }
  }

  // Request necessary permissions
  Future<bool> requestPermissions() async {
    try {
      final permissions = [
        Permission.camera,
        Permission.microphone,
        Permission.storage,
        Permission.phone,
        Permission.contacts,
        Permission.location,
      ];

      final statuses = await permissions.request();
      return statuses.values.every((status) => 
        status == PermissionStatus.granted || 
        status == PermissionStatus.limited
      );
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }
}

class BatteryInfo {
  final int level;
  final bool isCharging;
  final BatteryState state;

  BatteryInfo({
    required this.level,
    required this.isCharging,
    required this.state,
  });

  String get statusText {
    if (isCharging) return 'Charging';
    switch (state) {
      case BatteryState.full:
        return 'Full';
      case BatteryState.charging:
        return 'Charging';
      case BatteryState.discharging:
        return 'Discharging';
      default:
        return 'Unknown';
    }
  }
}

class ConnectivityInfo {
  final ConnectivityResult type;
  final bool isConnected;

  ConnectivityInfo({
    required this.type,
    required this.isConnected,
  });

  String get typeText {
    switch (type) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      default:
        return 'No Connection';
    }
  }
}