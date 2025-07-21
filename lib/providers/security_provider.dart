import 'package:flutter/foundation.dart';
import '../services/security_service.dart';

class SecurityProvider extends ChangeNotifier {
  final SecurityService _securityService = SecurityService();

  bool _isLocked = false;
  bool _biometricAvailable = false;
  int _wrongAttempts = 0;

  bool get isLocked => _isLocked;
  bool get biometricAvailable => _biometricAvailable;
  int get wrongAttempts => _wrongAttempts;

  Future<void> initialize() async {
    try {
      _biometricAvailable = await _securityService.isBiometricAvailable();
      _isLocked = _securityService.isLocked;
      _wrongAttempts = _securityService.wrongPasswordAttempts;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing security provider: $e');
    }
  }

  Future<SecurityResult> authenticateWithPassword(String password, String correctHash, int maxAttempts) async {
    try {
      final result = await _securityService.authenticateUser(
        password: password,
        correctPasswordHash: correctHash,
        maxAttempts: maxAttempts,
      );
      
      _isLocked = _securityService.isLocked;
      _wrongAttempts = _securityService.wrongPasswordAttempts;
      notifyListeners();
      
      return result;
    } catch (e) {
      debugPrint('Error authenticating with password: $e');
      return SecurityResult(
        success: false,
        message: 'Authentication error',
        action: SecurityAction.wrongPassword,
      );
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final success = await _securityService.authenticateWithBiometrics();
      if (success) {
        _isLocked = false;
        _wrongAttempts = 0;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error authenticating with biometrics: $e');
      return false;
    }
  }

  void forceUnlock() {
    _securityService.forceUnlock();
    _isLocked = false;
    _wrongAttempts = 0;
    notifyListeners();
  }
}