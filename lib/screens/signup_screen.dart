import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/widgets.dart';

class SignupScreen extends StatefulWidget {
  final AppState state;
  final Map<String, dynamic> t;
  const SignupScreen({super.key, required this.state, required this.t});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  String? _localError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _localError = null);
    widget.state.clearAuthError();

    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _localError = widget.t['signup_error_match']);
      return;
    }

    widget.state.doEmailSignUp(
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      fullName: _nameCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t     = widget.t;
    final state = widget.state;
    final roles = t['login_roles'] as List;
    final error = _localError ?? state.authError;

    return RimalScaffold(
      state: state,
      t: t,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 16),
          const Text('Rimal',
              style: TextStyle(
                  color: C.textPrim,
                  fontWeight: FontWeight.w900,
                  fontSize: 28)),
          const SizedBox(height: 8),
          Text(t['signup_sub'],
              style: const TextStyle(color: C.textMut, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          RCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Role selector ──────────────────────────────────────────
              Text(t['login_role_label'],
                  style: const TextStyle(
                      color: C.textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const SizedBox(height: 10),
              Row(
                children: roles.map<Widget>((r) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: r == roles.last ? 0 : 8),
                      child: _RoleCard(
                        label:    r['label'],
                        desc:     r['desc'],
                        isActive: state.loginRole == r['key'],
                        onTap:    () => state.setLoginRole(r['key']),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Name ───────────────────────────────────────────────────
              _Field(
                controller:  _nameCtrl,
                hint:        t['signup_name_hint'],
                icon:        Icons.person_outline_rounded,
              ),
              const SizedBox(height: 10),

              // ── Email ──────────────────────────────────────────────────
              _Field(
                controller:   _emailCtrl,
                hint:         t['signup_email_hint'],
                icon:         Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),

              // ── Password ───────────────────────────────────────────────
              _Field(
                controller: _passwordCtrl,
                hint:       t['signup_password_hint'],
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

              // ── Confirm password ───────────────────────────────────────
              _Field(
                controller: _confirmCtrl,
                hint:       t['signup_confirm_hint'],
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

              // ── Error ──────────────────────────────────────────────────
              if (error != null) ...[
                _ErrorBanner(message: error),
                const SizedBox(height: 10),
              ],

              // ── Create account button ──────────────────────────────────
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
                      : Text(t['signup_btn'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 16),

              // ── Sign in link ───────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => state.go('login'),
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: '${t['signup_signin']} ',
                          style: const TextStyle(
                              color: C.textMut, fontSize: 13)),
                      TextSpan(
                          text: t['signup_signin_action'],
                          style: const TextStyle(
                              color: C.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Reused widgets ─────────────────────────────────────────────────────────

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
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: C.textPrim, fontSize: 14),
      decoration: InputDecoration(
        hintText:    hint,
        hintStyle:   const TextStyle(color: C.textDim, fontSize: 14),
        prefixIcon:  Icon(icon, color: C.textDim, size: 18),
        suffixIcon:  suffix,
        filled:      true,
        fillColor:   C.bg,
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

class _RoleCard extends StatefulWidget {
  final String label;
  final String desc;
  final bool isActive;
  final VoidCallback onTap;
  const _RoleCard({
    required this.label,
    required this.desc,
    required this.isActive,
    required this.onTap,
  });
  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF002040)
                : (_hovered ? const Color(0xFF001830) : C.bg),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: active
                    ? C.blue
                    : (_hovered ? C.borderHi : C.border)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.label,
                style: TextStyle(
                    color: active ? C.blue : (_hovered ? C.textPrim : C.textMut),
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(widget.desc,
                style: const TextStyle(
                    color: C.textDim, fontSize: 11, height: 1.4)),
          ]),
        ),
      ),
    );
  }
}
