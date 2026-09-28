import 'package:supabase_flutter/supabase_flutter.dart';

final _db = Supabase.instance.client;

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Anonymous login (dev / Sanad placeholder) ──────────────────────────
  Future<void> login({required String role}) async {
    if (_db.auth.currentSession == null) {
      await _db.auth.signInAnonymously();
    }
    await _db.from('profiles').upsert({
      'id':   _db.auth.currentUser!.id,
      'role': role,
    });
  }

  // ── Email sign-in ──────────────────────────────────────────────────────
  Future<void> loginWithEmail({
    required String email,
    required String password,
    required String role,
  }) async {
    await _db.auth.signInWithPassword(email: email, password: password);
    final uid = _db.auth.currentUser!.id;
    // Only create a profile if one doesn't already exist — never overwrite the
    // stored role, so an applicant can't self-promote by picking "Regulator"
    // on the login screen.
    final existing = await _db
        .from('profiles')
        .select('role')
        .eq('id', uid)
        .maybeSingle();
    if (existing == null) {
      await _db.from('profiles').upsert({'id': uid, 'role': role});
    }
  }

  // ── Email sign-up ──────────────────────────────────────────────────────
  /// Returns true if email confirmation is required (user must check inbox).
  /// Returns false if the user is signed in immediately (confirmation OFF).
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String role,
    String? fullName,
  }) async {
    if (role == 'regulator') {
      final allowed = await _db
          .from('regulator_emails')
          .select('email')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();
      if (allowed == null) {
        throw Exception('regulator_not_approved');
      }
    }

    final response = await _db.auth.signUp(
      email:    email,
      password: password,
      data: {
        'pending_role': role,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      },
    );
    final user = response.user;
    if (user == null) throw Exception('Sign-up failed. Please try again.');

    // Supabase returns an empty identities list instead of an error when the
    // email is already registered (to prevent email enumeration attacks).
    if (user.identities != null && user.identities!.isEmpty) {
      throw Exception('email_already_in_use');
    }

    final needsConfirmation = response.session == null;

    if (!needsConfirmation) {
      // Email confirmation is OFF — user is already signed in, create profile now
      await _db.from('profiles').upsert({
        'id':        user.id,
        'role':      role,
        'full_name': fullName,
      });
    }
    // If confirmation is needed, the profile is created on first sign-in
    // via loginWithEmail which always upserts the profile with the selected role.

    return needsConfirmation;
  }

  // ── Password reset ─────────────────────────────────────────────────────
  Future<bool> checkEmailRegistered(String email) async {
    final result = await _db.rpc(
      'check_email_registered',
      params: {'p_email': email},
    );
    return result as bool? ?? false;
  }

  Future<void> resetPassword(String email) async {
    await _db.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _db.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ── Logout ─────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _db.auth.signOut();
  }

  // ── Session restore ────────────────────────────────────────────────────
  Future<String?> getStoredRole() async {
    final session = _db.auth.currentSession;
    if (session == null) return null;

    final user = session.user;

    // Check if profile exists
    final data = await _db
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (data != null) return data['role'] as String?;

    // Profile missing — user just confirmed email for the first time.
    // Apply the pending role stored in user metadata during sign-up.
    final meta     = user.userMetadata ?? {};
    final role     = meta['pending_role'] as String? ?? 'applicant';
    final fullName = meta['full_name'] as String?;

    await _db.from('profiles').upsert({
      'id':        user.id,
      'role':      role,
      'full_name': fullName,
    });

    return role;
  }
}
