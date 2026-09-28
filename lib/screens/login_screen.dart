import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  final AppState state;
  final Map<String, dynamic> t;
  const LoginScreen({super.key, required this.state, required this.t});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) return;
    widget.state.doEmailLogin(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    final t     = widget.t;
    final state = widget.state;
    final roles = t['login_roles'] as List;

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
          Text(t['login_sub'],
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

              // ── Email field ────────────────────────────────────────────
              _Field(
                controller:   _emailCtrl,
                hint:         t['login_email_hint'],
                icon:         Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),

              // ── Password field ─────────────────────────────────────────
              _Field(
                controller: _passwordCtrl,
                hint:       t['login_password_hint'],
                icon:       Icons.lock_outline_rounded,
                obscure:    _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: C.textDim, size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 14),

              // ── Error banner ───────────────────────────────────────────
              if (state.authError != null) ...[
                _ErrorBanner(message: state.authError!),
                const SizedBox(height: 10),
              ],

              // ── Sign in button ─────────────────────────────────────────
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
                      : Text(t['login_email_btn'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 14),

              // ── Sign up link ───────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => state.go('signup'),
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: '${t['login_signup_link']} ',
                          style: const TextStyle(color: C.textMut, fontSize: 13)),
                      TextSpan(
                          text: t['login_signup_action'],
                          style: const TextStyle(
                              color: C.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Divider ────────────────────────────────────────────────
              Row(children: [
                const Expanded(child: Divider(color: C.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(t['login_or'],
                      style: const TextStyle(color: C.textDim, fontSize: 11)),
                ),
                const Expanded(child: Divider(color: C.border)),
              ]),
              const SizedBox(height: 16),

              // ── Sanad button ───────────────────────────────────────────
              _SanadBtn(
                label: t['login_sanad'],
                onTap: state.isAuthLoading ? null : state.doLoginDev,
              ),
              const SizedBox(height: 16),

              // ── Verified by Sanad notice ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF002040),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.border),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF2DA84A), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                      text: '${t['login_sanad_by']} ',
                                      style: const TextStyle(
                                          color: C.textMut, fontSize: 12)),
                                  TextSpan(
                                      text: t['login_sanad_name'],
                                      style: const TextStyle(
                                          color: C.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ]),
                              ),
                              const SizedBox(height: 2),
                              Text(t['login_sanad_sub'],
                                  style: const TextStyle(
                                      color: C.textDim, fontSize: 11)),
                            ]),
                      ),
                    ]),
              ),
              const SizedBox(height: 14),

              // ── Trouble link ───────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => state.go('trouble'),
                  child: Text(t['login_trouble'],
                      style: const TextStyle(
                          color: C.textMut,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          decorationColor: C.textMut)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Shared error banner ────────────────────────────────────────────────────

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

// ── Text field ─────────────────────────────────────────────────────────────

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
        hintText:     hint,
        hintStyle:    const TextStyle(color: C.textDim, fontSize: 14),
        prefixIcon:   Icon(icon, color: C.textDim, size: 18),
        suffixIcon:   suffix,
        filled:       true,
        fillColor:    C.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: C.blue, width: 1.5),
        ),
      ),
    );
  }
}

// ── Role selector card ─────────────────────────────────────────────────────

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
          curve:    Curves.easeOut,
          padding:  const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF002040)
                : (_hovered ? const Color(0xFF001830) : C.bg),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? C.blue
                  : (_hovered ? C.borderHi : C.border),
            ),
            boxShadow: _hovered && !active
                ? [BoxShadow(
                    color:      C.blue.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset:     const Offset(0, 2))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.label,
                  style: TextStyle(
                    color:      active ? C.blue : (_hovered ? C.textPrim : C.textMut),
                    fontSize:   14,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 3),
              Text(widget.desc,
                  style: const TextStyle(
                      color: C.textDim, fontSize: 11, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sanad button ───────────────────────────────────────────────────────────

class _SanadLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2DA84A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.62)
      ..cubicTo(size.width * 0.15, size.height * 0.62,
          size.width * 0.28, size.height * 0.48,
          size.width * 0.38, size.height * 0.44)
      ..cubicTo(size.width * 0.45, size.height * 0.41,
          size.width * 0.52, size.height * 0.44,
          size.width * 0.58, size.height * 0.42)
      ..cubicTo(size.width * 0.66, size.height * 0.4,
          size.width * 0.72, size.height * 0.34,
          size.width * 0.8, size.height * 0.24);
    canvas.drawPath(path, paint);
    final arrow = Paint()
      ..color = const Color(0xFF2DA84A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final arrowPath = Path()
      ..moveTo(size.width * 0.68, size.height * 0.22)
      ..lineTo(size.width * 0.8, size.height * 0.24)
      ..lineTo(size.width * 0.78, size.height * 0.36);
    canvas.drawPath(arrowPath, arrow);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SanadBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _SanadBtn({required this.label, this.onTap});

  @override
  State<_SanadBtn> createState() => _SanadBtnState();
}

class _SanadBtnState extends State<_SanadBtn> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() { _hovered = false; _pressed = false; }),
      child: GestureDetector(
        onTap:       widget.onTap,
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) => setState(() => _pressed = false),
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedScale(
          scale:    _pressed ? 0.97 : (_hovered ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve:    Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve:    Curves.easeOut,
            padding:  const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color:        _hovered ? const Color(0xFFF2F2F2) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border:       Border.all(
                color: _hovered ? const Color(0xFFCCCCCC) : Colors.white),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: _hovered ? 0.12 : 0.06),
                  blurRadius: _hovered ? 14 : 4,
                  offset:     _hovered ? const Offset(0, 4) : Offset.zero,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width:  36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:        Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color:      Colors.black.withValues(alpha: 0.10),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: CustomPaint(painter: _SanadLogoPainter()),
                ),
                const SizedBox(width: 12),
                Text(widget.label,
                    style: const TextStyle(
                        color:      Color(0xFF1A1A1A),
                        fontSize:   15,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
