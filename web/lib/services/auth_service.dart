import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyAdminExists = 'admin_exists';
  static const String _keyAdminUsername = 'admin_username';
  static const String _keyAdminPassword = 'admin_password';

  // Check if admin account has been created
  static Future<bool> hasAdminAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAdminExists) ?? false;
  }

  // Register the admin account
  static Future<void> registerAdmin(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdminExists, true);
    await prefs.setString(_keyAdminUsername, username);
    await prefs.setString(_keyAdminPassword, password);
  }

  // Validate login
  static Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString(_keyAdminUsername);
    final savedPassword = prefs.getString(_keyAdminPassword);

    if (savedUsername == username && savedPassword == password) {
      return true;
    }
    return false;
  }

  // Get current username (for display in Settings)
  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAdminUsername) ?? '';
  }

  // Change password — validates old password first
  // Returns null on success, or an error message string on failure
  static Future<String?> changePassword(String oldPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString(_keyAdminPassword);

    if (savedPassword != oldPassword) {
      return 'Mot de passe actuel incorrect.';
    }
    if (newPassword.length < 4) {
      return 'Le nouveau mot de passe doit avoir au moins 4 caractères.';
    }
    await prefs.setString(_keyAdminPassword, newPassword);
    return null; // success
  }
}
