import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  final AppState state;
  final Map<String, dynamic> t;
  const ResetPasswordScreen({super.key, required this.state, required this.t});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  String? _localError;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _localError = null);
    widget.state.clearAuthError();

    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _localError = widget.t['reset_error_match']);
      return;
    }

    widget.state.updatePassword(_passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final t     = widget.t;
    final state = widget.state;
    final error = _localError ?? state.authError;

    return RimalScaffold(
      state: state,
      t: t,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 16),
          const Icon(Icons.lock_reset_rounded, color: C.blue, size: 40),
          const SizedBox(height: 12),
          Text(t['reset_title'],
              style: const TextStyle(
                  color: C.textPrim,
                  fontWeight: FontWeight.w800,
                  fontSize: 22)),
          const SizedBox(height: 6),
          Text(t['reset_sub'],
              style: const TextStyle(color: C.textMut, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          RCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── New password ────────────────────────────────────────────
              _Field(
                controller: _passwordCtrl,
                hint:       t['reset_new_hint'],
                icon:       Icons.lock_outline_rounded,
                obscure:    _obscurePass,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: C.textDim, size: 18,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              const SizedBox(height: 10),

              // ── Confirm new password ────────────────────────────────────
              _Field(
                controller: _confirmCtrl,
                hint:       t['reset_confirm_hint'],
                icon:       Icons.lock_outline_rounded,
                obscure:    _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: C.textDim, size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 14),

              // ── Error ───────────────────────────────────────────────────
              if (error != null) ...[
                _ErrorBanner(message: error),
                const SizedBox(height: 10),
              ],

              // ── Submit button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.isAuthLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: C.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isAuthLoading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(t['reset_btn'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        const Color(0xFF3A0A0A),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: const Color(0xFF7A1A1A)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFFFF6B6B), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12)),
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:  controller,
      obscureText: obscure,
      style: const TextStyle(color: C.textPrim, fontSize: 14),
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  const TextStyle(color: C.textDim, fontSize: 14),
        prefixIcon: Icon(icon, color: C.textDim, size: 18),
        suffixIcon: suffix,
        filled:     true,
        fillColor:  C.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   const BorderSide(color: C.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   const BorderSide(color: C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   const BorderSide(color: C.blue, width: 1.5)),
      ),
    );
  }
}
