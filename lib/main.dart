import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'state/app_state.dart';
import 'theme/colors.dart';
import 'i18n/translations.dart';

import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dash_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/form_screen.dart';
import 'screens/success_screen.dart';
import 'screens/regulator/reg_dash_screen.dart';
import 'screens/regulator/review_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/trouble_screen.dart';
import 'screens/confirm_email_screen.dart';
import 'screens/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read the URL BEFORE Supabase.initialize() processes and clears it.
  AppState.detectPendingAuth();

  await Supabase.initialize(
    url:     Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const RimalApp());
}

class RimalApp extends StatefulWidget {
  const RimalApp({super.key});

  @override
  State<RimalApp> createState() => _RimalAppState();
}

class _RimalAppState extends State<RimalApp> {
  final _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.addListener(() => setState(() {}));
    // Delay by one event loop tick so onAuthStateChange (passwordRecovery)
    // fires before restoreSession decides whether to auto-login.
    Future.delayed(Duration.zero, _state.restoreSession);
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t     = tx(_state.lang);
    final isRtl = t['dir'] == 'rtl';

    return MaterialApp(
      title: 'Rimal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(surface: C.bg),
        scaffoldBackgroundColor: C.bg,
        textTheme:
            GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: C.bg,
          elevation: 0,
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection:
            isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_state.view),
          child: _buildScreen(t),
        ),
      ),
    );
  }

  Widget _buildScreen(Map<String, dynamic> t) {
    switch (_state.view) {
      case 'landing':    return LandingScreen(state: _state, t: t);
      case 'login':      return LoginScreen(state: _state, t: t);
      case 'dash':       return DashScreen(state: _state, t: t);
      case 'apply':      return FormScreen(state: _state, t: t);
      case 'detail':     return DetailScreen(state: _state, t: t);
      case 'success':    return SuccessScreen(state: _state, t: t);
      case 'regdash':    return RegDashScreen(state: _state, t: t);
      case 'review':     return ReviewScreen(state: _state, t: t);
      case 'reviewdone': return ReviewDoneScreen(state: _state, t: t);
      case 'signup':     return SignupScreen(state: _state, t: t);
      case 'trouble':       return TroubleScreen(state: _state, t: t);
      case 'confirm':       return ConfirmEmailScreen(state: _state, t: t);
      case 'resetpassword': return ResetPasswordScreen(state: _state, t: t);
      default:           return LandingScreen(state: _state, t: t);
    }
  }
}
