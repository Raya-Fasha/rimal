import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/widgets.dart';

class ConfirmEmailScreen extends StatelessWidget {
  final AppState state;
  final Map<String, dynamic> t;
  const ConfirmEmailScreen({super.key, required this.state, required this.t});

  @override
  Widget build(BuildContext context) {
    return RimalScaffold(
      state: state,
      t: t,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icon ────────────────────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color:        const Color(0xFF002040),
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: C.blue),
                ),
                child: const Icon(Icons.mark_email_unread_outlined,
                    color: C.blue, size: 36),
              ),
              const SizedBox(height: 24),

              // ── Title ────────────────────────────────────────────────────
              const Text('Check your inbox',
                  style: TextStyle(
                      color:      C.textPrim,
                      fontSize:   22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),

              // ── Email address ────────────────────────────────────────────
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(children: [
                  const TextSpan(
                      text: 'We sent a confirmation link to\n',
                      style: TextStyle(color: C.textMut, fontSize: 14)),
                  TextSpan(
                      text: state.pendingEmail,
                      style: const TextStyle(
                          color:      C.blue,
                          fontSize:   14,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 8),
              const Text(
                'Click the link in the email to activate\nyour account, then sign in.',
                textAlign: TextAlign.center,
                style: TextStyle(color: C.textDim, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 32),

              // ── Go to sign in ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => state.go('login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: C.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go to Sign In',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 16),

              // ── Wrong email ──────────────────────────────────────────────
              GestureDetector(
                onTap: () => state.go('signup'),
                child: const Text('Wrong email? Sign up again',
                    style: TextStyle(
                        color:      C.textMut,
                        fontSize:   13,
                        decoration: TextDecoration.underline,
                        decorationColor: C.textMut)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
