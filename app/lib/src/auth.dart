import 'package:shared_preferences/shared_preferences.dart';

class AuthStore {
  final SharedPreferences _prefs;
  static const defaultHost = '46.225.143.221';

  AuthStore(this._prefs);

  String get host => _prefs.getString('host') ?? defaultHost;
  set host(String v) => _prefs.setString('host', v);

  String? get token => _prefs.getString('token');
  set token(String? v) => v == null
      ? _prefs.remove('token')
      : _prefs.setString('token', v);

  int? get expiresAt => _prefs.getInt('token_expires_at');
  set expiresAt(int? v) => v == null
      ? _prefs.remove('token_expires_at')
      : _prefs.setInt('token_expires_at', v);

  bool get isAuthed => _prefs.getString('token') != null;

  void clear() {
    _prefs.remove('token');
    _prefs.remove('token_expires_at');
  }
}
