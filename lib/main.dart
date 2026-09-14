import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'dashboard.dart';
part 'upload.dart';
part 'processing.dart';
part 'room_selection.dart';
part 'layouts.dart';
part 'admin_accounts.dart';
part 'auth.dart';
part 'welcome.dart';
part 'room_viewer.dart';

void main() => runApp(const MyApp());

const _background = Color(0xFF080B14);
const _surface = Color(0xFF111624);
const _muted = Color(0xFF8991A6);
const _blue = Color(0xFF4D9BFF);
const _violet = Color(0xFF8A6BFF);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planly AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: _blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
