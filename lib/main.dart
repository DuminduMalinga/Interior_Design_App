import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_components.dart';
import 'app_theme.dart';
import 'responsive.dart';

part 'dashboard.dart';
part 'upload.dart';
part 'processing.dart';
part 'room_selection.dart';
part 'layouts.dart';
part 'admin_accounts.dart';
part 'auth.dart';
part 'welcome.dart';
part 'profile.dart';
part 'room_viewer.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planly AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      home: const WelcomeScreen(),
    );
  }
}
