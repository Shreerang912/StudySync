import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

final _supabase = Supabase.instance.client;

class AuthService extends ChangeNotifier {
  User? get currentUser => _supabase.auth.currentUser;

  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  Future<String?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final existing = await _supabase
        .from('users')
        .select('id')
        .eq('username', username.trim())
        .maybeSingle();
      
      if (existing !=null) return 'Username already taken';

      final res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (res.user == null) return 'Registration failed, try again';

      await _supabase.from('users').insert({
        'id': res.user!.id,
        'username': username.trim(),
        'email': email.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      await _loadCurrentUser();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      await _loadCurrentUser();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    _currentUserModel = null;
    await _supabase.auth.signOut();
    notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final data = await _supabase
         .from('users')
         .select()
         .eq('id', uid)
         .maybeSingle();
    if (data != null) {
      _currentUserModel = UserModel.fromMap(data);
      notifyListeners();
    }
  }

  Future<UserModel?> fetchCurrentUserModel() async {
    if (_currentUserModel != null) return _currentUserModel;
    await _loadCurrentUser();
    return _currentUserModel;
  }
}