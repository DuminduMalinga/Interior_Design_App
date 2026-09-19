import 'package:flutter/material.dart';

import 'app_components.dart';
import 'app_theme.dart';
import 'responsive.dart';

part 'dashboard.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planly AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      home: const DashboardScreen(),
    );
  }
}
