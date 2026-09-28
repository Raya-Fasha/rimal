import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/form_data.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  String  view             = 'landing';
  String  lang             = 'en';
  String? role;
  Map<String, dynamic>? selectedApp;
  List<Map<String, dynamic>> selectedAppDocs = [];
  List<Map<String, dynamic>> applications = [];
  int     formStep         = 1;
  String  reviewDecision   = '';
  String  reviewRisk       = 'High';
  bool    isSavingReview   = false;
  String? reviewError;
  String  statusFilter     = 'All';
  String  riskFilter       = 'All';
  String  loginRole        = 'applicant';
  String? formValidationError;
  bool    isAuthLoading    = false;
  bool    isAppLoading     = false;
  bool    isFormSubmitting = false;
  String? authError;
  String? appError;
  String? formSubmissionError;
  String? submittedReference;
  // Shown on the trouble screen after a reset email is sent
  bool    resetEmailSent   = false;

  final FormData formData = FormData();
  RiskResult? submittedResult;

  StreamSubscription<AuthState>? _authSub;
  bool _inPasswordRecovery = false;

  // Called from main() BEFORE Supabase.initialize() processes the URL.
  // Detects both PKCE (?code=) and implicit (#type=recovery) flows,
  // and captures auth errors like expired OTP links.
  static bool   _pendingAuth  = false;
  static String? _pendingError;

  static void detectPendingAuth() {
    final query    = Uri.base.queryParameters;
    final fragment = Uri.base.fragment;

    if (query.containsKey('error')) {
      final code = query['error_code'] ?? query['error'] ?? '';
      if (code == 'otp_expired') {
        _pendingError = 'This reset link has expired. Please request a new one.';
      } else {
        final desc = query['error_description'] ?? 'Authentication error.';
        _pendingError = desc.replaceAll('+', ' ');
      }
      return;
    }

    _pendingAuth = query.containsKey('code') ||
        fragment.contains('type=recovery') ||
        query['type'] == 'recovery';
  }

  AppState() {
    // Show error (e.g. expired link) on the trouble screen.
    if (_pendingError != null) {
      authError     = _pendingError;
      _pendingError = null;
      view          = 'trouble';
    }

    // Block auto-login until we know whether this is recovery or confirmation.
    if (_pendingAuth) {
      _inPasswordRecovery = true;
      _pendingAuth = false;
    }

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          _inPasswordRecovery = true;
          view = 'resetpassword';
          notifyListeners();
        } else if (data.event == AuthChangeEvent.signedIn && role == null) {
          // Could be email confirmation (not recovery) — allow login.
          _inPasswordRecovery = false;
          await restoreSession();
        }
      },
    );
  }

  // ── Session restoration ────────────────────────────────────────────────
  Future<void> restoreSession() async {
    if (_inPasswordRecovery) return;
    try {
      final storedRole = await AuthService.instance.getStoredRole();
      // Check again after the async gap — passwordRecovery event may have
      // fired while we were awaiting the database call.
      if (_inPasswordRecovery) return;
      if (storedRole != null) {
        role = storedRole;
        view = role == 'applicant' ? 'dash' : 'regdash';
        notifyListeners();
        await loadApplications();
      }
    } catch (_) {}
  }

  Future<void> loadApplications() async {
    _setAppLoading(true);
    try {
      final rows = await ApplicationService.instance.fetchApplications(
        all: role == 'regulator',
      );
      applications = rows.map(_normalizeApplicationRow).toList();
      appError = null;
    } catch (e) {
      applications = [];
      appError = e.toString();
    } finally {
      _setAppLoading(false);
    }
  }

  Map<String, dynamic> _normalizeApplicationRow(Map<String, dynamic> row) {
    final aiTypes = row['ai_types'] is List ? (row['ai_types'] as List).cast<String>() : <String>[];
    final flags = row['risk_flags'] is List ? (row['risk_flags'] as List).cast<int>() : <int>[];
    final hullStatus = row['status'] is String ? _prettyStatus(row['status'] as String) : 'Draft';

    return {
      'id': row['reference_id'] ?? row['id'],
      'uuid': row['id'],
      'org': row['org_name'] ?? '',
      'project': row['project_name'] ?? '',
      'sector': row['deploy_region'] ?? row['dev_stage'] ?? 'N/A',
      'status': hullStatus,
      'score': row['risk_score'] ?? 0,
      'risk': row['risk_level'] ?? 'Low',
      'submitted': row['submitted_at'] ?? row['created_at'],
      'aiType': aiTypes.isNotEmpty ? aiTypes.join(', ') : 'AI system',
      'stage': row['dev_stage'] ?? 'N/A',
      'region': row['deploy_region'] ?? 'Jordan',
      'flags': flags,
      'data_types': row['data_types'],
      'selected_risks': row['selected_risks'],
      'model_type': row['model_type'],
      'model_description': row['model_description'],
      'risk_breakdown': row['score_breakdown'],
    };
  }

  String _prettyStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void _setAppLoading(bool v) {
    isAppLoading = v;
    notifyListeners();
  }

  void _setFormSubmitting(bool v) {
    isFormSubmitting = v;
    if (v) formSubmissionError = null;
    notifyListeners();
  }

  // ── Navigation ─────────────────────────────────────────────────────────
  void go(String v) {
    if (v == 'apply') formStep = 1;
    view = v;
    notifyListeners();
  }

  void toggleLang() { lang = lang == 'en' ? 'ar' : 'en'; notifyListeners(); }

  Future<void> logout() async {
    await AuthService.instance.logout();
    role               = null;
    selectedApp        = null;
    applications       = [];
    submittedReference = null;
    authError          = null;
    view               = 'landing';
    notifyListeners();
  }

  void setLoginRole(String r) { loginRole = r; notifyListeners(); }
  void clearAuthError()       { authError = null; notifyListeners(); }

  // ── Sanad mock login (simulated SSO handshake) ────────────────────────
  Future<void> doLoginDev() async {
    _setAuthLoading(true);
    try {
      // Simulate Sanad SSO redirect + token exchange (~1.5 s)
      await Future.delayed(const Duration(milliseconds: 1500));
      await AuthService.instance.login(role: loginRole);
      await _onLoginSuccess();
    } catch (_) {
      authError = 'Login failed. Please try again.';
    } finally {
      _setAuthLoading(false);
    }
  }

  // ── Email sign-in ──────────────────────────────────────────────────────
  Future<void> doEmailLogin({
    required String email,
    required String password,
  }) async {
    _setAuthLoading(true);
    try {
      await AuthService.instance.loginWithEmail(
        email:    email,
        password: password,
        role:     loginRole,
      );
      await _onLoginSuccess();
    } catch (e) {
      authError = _friendlyError(e);
    } finally {
      _setAuthLoading(false);
    }
  }

  // ── Email sign-up ──────────────────────────────────────────────────────
  String pendingEmail = '';

  Future<void> doEmailSignUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setAuthLoading(true);
    try {
      final needsConfirmation = await AuthService.instance.signUpWithEmail(
        email:    email,
        password: password,
        role:     loginRole,
        fullName: fullName.trim().isEmpty ? null : fullName.trim(),
      );
      if (needsConfirmation) {
        pendingEmail = email;
        view = 'confirm';
      } else {
        await _onLoginSuccess();
      }
    } catch (e) {
      authError = _friendlyError(e);
    } finally {
      _setAuthLoading(false);
    }
  }

  // ── Password reset ─────────────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    _setAuthLoading(true);
    try {
      final exists = await AuthService.instance.checkEmailRegistered(email.trim());
      if (!exists) {
        authError = 'No account found with this email address.';
        return;
      }
      await AuthService.instance.resetPassword(email.trim());
      resetEmailSent = true;
    } catch (e) {
      authError = _friendlyError(e);
    } finally {
      _setAuthLoading(false);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    _setAuthLoading(true);
    try {
      await AuthService.instance.updatePassword(newPassword);
      _inPasswordRecovery = false;
      await AuthService.instance.logout();
      role    = null;
      authError = null;
      view    = 'login';
      notifyListeners();
    } catch (e) {
      authError = _friendlyError(e);
    } finally {
      _setAuthLoading(false);
    }
  }

  void clearResetState() {
    resetEmailSent = false;
    authError      = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Future<void> _onLoginSuccess() async {
    role = loginRole;
    view = role == 'applicant' ? 'dash' : 'regdash';
    notifyListeners();
    await loadApplications();
  }

  void _setAuthLoading(bool v) {
    isAuthLoading = v;
    if (v) authError = null;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('regulator_not_approved')) {
      return 'This email is not authorized to register as a regulator. Contact your administrator.';
    }
    if (msg.contains('email already') || msg.contains('already registered') ||
        msg.contains('already in use') || msg.contains('email_already_in_use')) {
      return 'This email is already in use. Please sign in instead.';
    }
    if (msg.contains('password should be at least')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('unable to validate email') || msg.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('rate limit') || msg.contains('over_email_send_rate_limit')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Network error. Check your connection.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    return e.toString();
  }

  void selectApp(Map<String, dynamic> app, String dest) {
    selectedApp    = app;
    selectedAppDocs = [];
    reviewDecision = '';
    reviewRisk     = app['risk'] as String? ?? 'High';
    reviewError    = null;
    isSavingReview = false;
    go(dest);
    _loadDocs(app['uuid'] as String?);
  }

  Future<void> _loadDocs(String? uuid) async {
    if (uuid == null) return;
    try {
      selectedAppDocs = await ApplicationService.instance.fetchDocuments(uuid);
      notifyListeners();
    } catch (_) {}
  }

  // ── Form navigation ────────────────────────────────────────────────────
  bool formNext() {
    final err = formData.validateStep(formStep);
    if (err != null) {
      formValidationError = err;
      notifyListeners();
      return false;
    }
    formValidationError = null;
    if (formStep < 5) formStep++;
    notifyListeners();
    return true;
  }

  void formPrev() {
    formValidationError = null;
    if (formStep > 1) formStep--;
    notifyListeners();
  }

  void clearValidationError() {
    formValidationError = null;
    notifyListeners();
  }

  // ── Regulator filters ──────────────────────────────────────────────────
  void setSF(String f) { statusFilter = f; notifyListeners(); }
  void setRF(String f) { riskFilter   = f; notifyListeners(); }

  // ── Review actions ─────────────────────────────────────────────────────
  void setDecision(String d)   { reviewDecision = d; notifyListeners(); }
  void setReviewRisk(String r) { reviewRisk = r; notifyListeners(); }

  Future<void> submitReview({String notes = ''}) async {
    if (reviewDecision.isEmpty) return;
    final appId = selectedApp?['uuid'] as String?;
    if (appId == null) return;

    isSavingReview = true;
    reviewError    = null;
    notifyListeners();

    try {
      await ApplicationService.instance.submitReview(
        applicationId: appId,
        decision:      reviewDecision,
        assignedRisk:  reviewRisk,
        internalNotes: notes.trim().isEmpty ? null : notes.trim(),
      );
      await loadApplications();
      go('reviewdone');
    } catch (e) {
      reviewError = e.toString();
    } finally {
      isSavingReview = false;
      notifyListeners();
    }
  }

  // ── Form field toggles ─────────────────────────────────────────────────
  void toggleAiType(String t) {
    formData.selectedAiTypes.contains(t)
        ? formData.selectedAiTypes.remove(t)
        : formData.selectedAiTypes.add(t);
    notifyListeners();
  }

  void toggleDataType(String t) {
    formData.selectedDataTypes.contains(t)
        ? formData.selectedDataTypes.remove(t)
        : formData.selectedDataTypes.add(t);
    notifyListeners();
  }

  void toggleRisk(String r) {
    formData.selectedRisks.contains(r)
        ? formData.selectedRisks.remove(r)
        : formData.selectedRisks.add(r);
    notifyListeners();
  }

  void setStage(String s)                { formData.selectedStage         = s; notifyListeners(); }
  void setMakesDecisions(bool v)         { formData.makesDecisions         = v; notifyListeners(); }
  void setHumanOversight(bool v)         { formData.hasHumanOversight      = v; notifyListeners(); }
  void setProcessesSensitiveData(bool v) { formData.processesSensitiveData = v; notifyListeners(); }

  void setUploadedFile(String docType, String fileName, [List<int>? bytes]) {
    formData.uploadedFiles[docType]     = fileName;
    formData.uploadedFileBytes[docType] = bytes;
    notifyListeners();
  }

  void resetForm() {
    formData.reset();
    formStep            = 1;
    formValidationError = null;
    formSubmissionError = null;
    notifyListeners();
  }

  Future<void> submitForm() async {
    final validationError = formData.validateStep(formStep);
    if (validationError != null) {
      formValidationError = validationError;
      notifyListeners();
      return;
    }

    _setFormSubmitting(true);
    try {
      final score = RiskScorer.score(formData);
      final appRow = await ApplicationService.instance.createApplication(formData);
      selectedApp = _normalizeApplicationRow(appRow);
      submittedReference = selectedApp?['id'] as String?;
      submittedResult = score;
      await loadApplications();
      go('success');
    } catch (e) {
      formSubmissionError = e.toString();
    } finally {
      _setFormSubmitting(false);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    formData.dispose();
    super.dispose();
  }
}
