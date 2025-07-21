import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  CameraController? _cameraController;
  
  int _wrongPasswordAttempts = 0;
  bool _isLocked = false;
  String? _lockedReason;
  DateTime? _lockTime;

  // Biometric Authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      final hasFingerprint = await _localAuth.canCheckBiometrics;
      return isAvailable && hasFingerprint;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics({
    String reason = 'Please authenticate to access Nexus Assistant',
  }) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedFallbackTitle: 'Use PIN',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Nexus Assistant Authentication',
            biometricHint: 'Touch the fingerprint sensor',
            biometricNotRecognized: 'Fingerprint not recognized',
            biometricRequiredTitle: 'Fingerprint required',
            biometricSuccess: 'Fingerprint recognized',
            cancelButton: 'Cancel',
            deviceCredentialsRequiredTitle: 'Device credentials required',
            deviceCredentialsSetupDescription: 'Device credentials required',
            goToSettingsButton: 'Go to settings',
            goToSettingsDescription: 'Please set up your fingerprint',
          ),
        ],
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      
      if (isAuthenticated) {
        _resetSecurityState();
      }
      
      return isAuthenticated;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  // Password Authentication
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyPassword(String inputPassword, String storedPasswordHash) {
    final inputHash = _hashPassword(inputPassword);
    return inputHash == storedPasswordHash;
  }

  String hashPassword(String password) {
    return _hashPassword(password);
  }

  // Smart Lock System
  Future<SecurityResult> authenticateUser({
    required String password,
    required String correctPasswordHash,
    required int maxAttempts,
  }) async {
    // Check if app is temporarily locked
    if (_isLocked && _lockTime != null) {
      final lockDuration = DateTime.now().difference(_lockTime!);
      if (lockDuration.inMinutes < 5) { // 5-minute lock
        return SecurityResult(
          success: false,
          message: 'App is locked. Try again in ${5 - lockDuration.inMinutes} minutes.',
          action: SecurityAction.locked,
        );
      } else {
        _unlockApp();
      }
    }

    if (verifyPassword(password, correctPasswordHash)) {
      _resetSecurityState();
      return SecurityResult(
        success: true,
        message: 'Welcome back sir!',
        action: SecurityAction.unlocked,
      );
    } else {
      _wrongPasswordAttempts++;
      
      if (_wrongPasswordAttempts == 1) {
        return SecurityResult(
          success: false,
          message: 'Wrong password',
          action: SecurityAction.wrongPassword,
        );
      } else if (_wrongPasswordAttempts == 2) {
        // Take photo on second wrong attempt
        final photoPath = await _captureIntruderPhoto();
        return SecurityResult(
          success: false,
          message: 'Wrong password. Photo captured for security.',
          action: SecurityAction.photoTaken,
          photoPath: photoPath,
        );
      } else if (_wrongPasswordAttempts >= maxAttempts) {
        _lockApp('Too many failed attempts');
        return SecurityResult(
          success: false,
          message: 'App locked due to multiple failed attempts.',
          action: SecurityAction.locked,
        );
      }
      
      return SecurityResult(
        success: false,
        message: 'Wrong password. ${maxAttempts - _wrongPasswordAttempts} attempts remaining.',
        action: SecurityAction.wrongPassword,
      );
    }
  }

  // Camera Functions
  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<String?> _captureIntruderPhoto() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        await initializeCamera();
      }
      
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final image = await _cameraController!.takePicture();
        
        // Save with timestamp and security context
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final securityImagePath = 'security_${timestamp}.jpg';
        
        // In a real app, you might want to save this to a secure location
        // or upload to a cloud service
        debugPrint('Security photo captured: ${image.path}');
        
        return image.path;
      }
    } catch (e) {
      debugPrint('Error capturing security photo: $e');
    }
    
    return null;
  }

  void _lockApp(String reason) {
    _isLocked = true;
    _lockedReason = reason;
    _lockTime = DateTime.now();
  }

  void _unlockApp() {
    _isLocked = false;
    _lockedReason = null;
    _lockTime = null;
  }

  void _resetSecurityState() {
    _wrongPasswordAttempts = 0;
    _unlockApp();
  }

  // Security Status
  bool get isLocked => _isLocked;
  String? get lockReason => _lockedReason;
  int get wrongPasswordAttempts => _wrongPasswordAttempts;
  DateTime? get lockTime => _lockTime;

  // Force unlock (for admin purposes)
  void forceUnlock() {
    _resetSecurityState();
  }

  // Security Settings
  Future<bool> setupBiometricAuth() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;
      
      return await authenticateWithBiometrics(
        reason: 'Set up biometric authentication for Nexus Assistant',
      );
    } catch (e) {
      debugPrint('Error setting up biometric auth: $e');
      return false;
    }
  }

  // Cleanup
  void dispose() {
    _cameraController?.dispose();
  }

  // Security Logs (for debugging/monitoring)
  List<SecurityEvent> _securityEvents = [];
  
  void _logSecurityEvent(SecurityAction action, {String? details}) {
    _securityEvents.add(SecurityEvent(
      action: action,
      timestamp: DateTime.now(),
      details: details,
    ));
    
    // Keep only last 100 events
    if (_securityEvents.length > 100) {
      _securityEvents.removeAt(0);
    }
  }

  List<SecurityEvent> getSecurityEvents() => List.unmodifiable(_securityEvents);

  // Auto-lock timer
  Timer? _autoLockTimer;
  
  void startAutoLockTimer(Duration duration) {
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer(duration, () {
      _lockApp('Auto-lock timer expired');
      _logSecurityEvent(SecurityAction.autoLocked, details: 'Auto-lock after ${duration.inMinutes} minutes');
    });
  }

  void resetAutoLockTimer(Duration duration) {
    startAutoLockTimer(duration);
  }

  void cancelAutoLockTimer() {
    _autoLockTimer?.cancel();
  }
}

class SecurityResult {
  final bool success;
  final String message;
  final SecurityAction action;
  final String? photoPath;

  SecurityResult({
    required this.success,
    required this.message,
    required this.action,
    this.photoPath,
  });
}

enum SecurityAction {
  unlocked,
  wrongPassword,
  photoTaken,
  locked,
  autoLocked,
  biometricSuccess,
  biometricFailed,
}

class SecurityEvent {
  final SecurityAction action;
  final DateTime timestamp;
  final String? details;

  SecurityEvent({
    required this.action,
    required this.timestamp,
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'action': action.name,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
  };
}