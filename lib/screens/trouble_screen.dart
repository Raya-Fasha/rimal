import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/widgets.dart';

class TroubleScreen extends StatefulWidget {
  final AppState state;
  final Map<String, dynamic> t;
  const TroubleScreen({super.key, required this.state, required this.t});

  @override
  State<TroubleScreen> createState() => _TroubleScreenState();
}

class _TroubleScreenState extends State<TroubleScreen> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t     = widget.t;
    final state = widget.state;

    return RimalScaffold(
      state: state,
      t: t,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 16),

          // ── Header ────────────────────────────────────────────────────
          const Icon(Icons.help_outline_rounded, color: C.blue, size: 40),
          const SizedBox(height: 12),
          Text(t['trouble_title'],
              style: const TextStyle(
                  color: C.textPrim,
                  fontWeight: FontWeight.w800,
                  fontSize: 22)),
          const SizedBox(height: 6),
          Text(t['trouble_sub'],
              style: const TextStyle(color: C.textMut, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),

          // ── Password reset card ────────────────────────────────────────
          RCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionLabel(t['trouble_reset_label']),
              const SizedBox(height: 12),

              if (state.resetEmailSent) ...[
                // Success state
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:        const Color(0xFF002A10),
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: C.green),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: C.green, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(t['trouble_reset_sent'],
                          style: const TextStyle(
                              color: C.green, fontSize: 13)),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    state.clearResetState();
                    _emailCtrl.clear();
                  },
                  child: const Text('Send another',
                      style: TextStyle(color: C.blue, fontSize: 13)),
                ),
              ] else ...[
                // Input state
                TextField(
                  controller:   _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: C.textPrim, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:   t['trouble_reset_hint'],
                    hintStyle:  const TextStyle(color: C.textDim, fontSize: 14),
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: C.textDim, size: 18),
                    filled:     true,
                    fillColor:  C.bg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:   const BorderSide(color: C.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:   const BorderSide(color: C.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: C.blue, width: 1.5)),
                  ),
                ),
                if (state.authError != null) ...[
                  const SizedBox(height: 10),
                  _ErrorBanner(message: state.authError!),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.isAuthLoading
                        ? null
                        : () {
                            final email = _emailCtrl.text.trim();
                            if (email.isNotEmpty) {
                              state.sendPasswordReset(email);
                            }
                          },
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
                        : Text(t['trouble_reset_btn'],
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          // ── Contact support card ───────────────────────────────────────
          RCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionLabel(t['trouble_contact_label']),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.mail_outline_rounded,
                    color: C.blue, size: 18),
                const SizedBox(width: 10),
                Text(t['trouble_contact_email'],
                    style: const TextStyle(
                        color: C.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 6),
              Text(t['trouble_contact_note'],
                  style: const TextStyle(color: C.textDim, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Back to sign in ────────────────────────────────────────────
          GestureDetector(
            onTap: () {
              state.clearResetState();
              state.go('login');
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.arrow_back_rounded, color: C.blue, size: 16),
              const SizedBox(width: 6),
              Text(t['trouble_back'],
                  style: const TextStyle(
                      color: C.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: C.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8));
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
              style: const TextStyle(
                  color: Color(0xFFFF6B6B), fontSize: 12)),
        ),
      ]),
    );
  }
}
