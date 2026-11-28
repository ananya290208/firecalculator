import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static const String _keyIsLoggedIn = 'auth_is_logged_in';
  static const String _keyIsRegistered = 'auth_is_registered';
  static const String _keyUserName = 'auth_user_name';
  static const String _keyUserEmail = 'auth_user_email';
  static const String _keyUserPassword = 'auth_user_password';
  static const String _keyRememberMe = 'auth_remember_me';

  // Web-only strict credentials
  static const String webAuthorizedEmail = 'sachin.virmalwar@gmail.com';
  static const String webAuthorizedPassword = 'Incredible@08';
  static const String webAuthorizedName = 'Sachin Virmalwar';

  bool _isLoggedIn = false;
  bool _isRegistered = false;
  bool _rememberMe = true;
  bool _isDemoMode = false;
  String _userName = '';
  String _userEmail = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isRegistered => _isRegistered;
  bool get rememberMe => _rememberMe;
  bool get isDemoMode => _isDemoMode;
  String get userName => _userName;
  String get userEmail => _userEmail;

  /// Activates demo mode for unregistered/exploring users
  void enterDemoMode() {
    _isDemoMode = true;
    notifyListeners();
  }

  /// Exits demo mode and returns to login / register screen
  void exitDemoMode() {
    _isDemoMode = false;
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool(_keyRememberMe) ?? true;
    final storedLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

    if (kIsWeb) {
      _isRegistered = true;
      _userName = webAuthorizedName;
      _userEmail = webAuthorizedEmail;
      _isLoggedIn = storedLoggedIn && _rememberMe;
    } else {
      _isRegistered = prefs.getBool(_keyIsRegistered) ?? false;
      _userName = prefs.getString(_keyUserName) ?? '';
      _userEmail = prefs.getString(_keyUserEmail) ?? '';
      _isLoggedIn = _isRegistered && storedLoggedIn && _rememberMe;
    }
    notifyListeners();
  }

  /// Register user locally on this device
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    if (kIsWeb) {
      return 'Registration is disabled on Web. Please sign in directly.';
    }

    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      return 'Please enter your full name.';
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return 'Please enter a valid email address.';
    }
    if (password.length < 4) {
      return 'Password must be at least 4 characters long.';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, cleanName);
    await prefs.setString(_keyUserEmail, cleanEmail);
    await prefs.setString(_keyUserPassword, password);
    await prefs.setBool(_keyIsRegistered, true);
    await prefs.setBool(_keyRememberMe, rememberMe);
    await prefs.setBool(_keyIsLoggedIn, true);

    _userName = cleanName;
    _userEmail = cleanEmail;
    _rememberMe = rememberMe;
    _isRegistered = true;
    _isLoggedIn = true;
    _isDemoMode = false;
    notifyListeners();
    return null; // success
  }

  /// Log in against credentials stored locally on this device
  Future<String?> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      return 'Please enter your email address.';
    }
    if (password.isEmpty) {
      return 'Please enter your password.';
    }

    if (kIsWeb) {
      if (cleanEmail == webAuthorizedEmail.toLowerCase() && password == webAuthorizedPassword) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyRememberMe, rememberMe);
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserEmail, webAuthorizedEmail);
        await prefs.setString(_keyUserName, webAuthorizedName);
        _userName = webAuthorizedName;
        _userEmail = webAuthorizedEmail;
        _rememberMe = rememberMe;
        _isRegistered = true;
        _isLoggedIn = true;
        _isDemoMode = false;
        notifyListeners();
        return null; // success
      } else {
        return 'Access denied: Invalid credentials for Web version.';
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString(_keyUserEmail) ?? '';
    final storedPassword = prefs.getString(_keyUserPassword) ?? '';

    if (!_isRegistered && storedEmail.isEmpty) {
      return 'No account registered on this device yet. Please create an account first.';
    }

    if (storedEmail.toLowerCase() != cleanEmail) {
      return 'Email does not match the registered user on this device.';
    }

    if (storedPassword != password) {
      return 'Incorrect password. Please try again.';
    }

    await prefs.setBool(_keyRememberMe, rememberMe);
    await prefs.setBool(_keyIsLoggedIn, true);
    _rememberMe = rememberMe;
    _isLoggedIn = true;
    _isDemoMode = false;
    notifyListeners();
    return null; // success
  }

  /// Update rememberMe preference
  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, value);
    notifyListeners();
  }

  /// Log out from current session
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    _isLoggedIn = false;
    _isDemoMode = false;
    notifyListeners();
  }
}
