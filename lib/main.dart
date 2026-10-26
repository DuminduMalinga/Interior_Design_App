import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_components.dart';
import 'app_theme.dart';
import 'data/avatar.dart';
import 'data/layout_service.dart';
import 'data/models.dart';
import 'data/room_export.dart';
import 'data/site_news.dart';
import 'data/supabase_service.dart';
import 'env.dart';
import 'plan_overlay.dart';
import 'responsive.dart';
import 'theme_controller.dart';

part 'splash.dart';
part 'dashboard.dart';
part 'projects.dart';
part 'designs.dart';
part 'upload.dart';
part 'processing.dart';
part 'room_selection.dart';
part 'layouts.dart';
part 'admin_accounts.dart';
part 'auth.dart';
part 'forgot_password.dart';
part 'welcome.dart';
part 'profile.dart';
part 'about.dart';
part 'room_viewer.dart';
part 'room_pieces.dart';
part 'room_pieces_living.dart';
part 'room_pieces_bedroom.dart';
part 'room_pieces_kitchen.dart';
part 'room_pieces_bathroom.dart';
part 'room_pieces_dining.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  await Supabase.initialize(
    url: SupabaseEnv.url,
    publishableKey: SupabaseEnv.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(const MyApp());
}

/// Global key so the Supabase auth-state listener below can push routes
/// (e.g. after a password-recovery deep link) without needing a widget's
/// own [BuildContext].
final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Supabase redirects a password-reset link back into the app as a
    // `passwordRecovery` auth event rather than a regular sign-in; catching
    // it here lets us route straight to the "set new password" screen from
    // wherever the user happens to be.
    _authSub = AuthService.instance.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute<void>(builder: (_) => const ResetPasswordScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) => MaterialApp(
        navigatorKey: navigatorKey,
        title: 'LiviSpace',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: mode,
        home: const SplashScreen(),
      ),
    );
  }
}
