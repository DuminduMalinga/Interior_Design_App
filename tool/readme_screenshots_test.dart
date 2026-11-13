// ignore_for_file: invalid_use_of_visible_for_testing_member
// Renders the README screenshots from the real screens, offline, with the
// bundled font and sample data. Regenerate them with:
//
//   flutter test tool/readme_screenshots_test.dart --update-goldens
//
// Each screen is drawn at phone size (390 x 844) in the dark theme.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/app_theme.dart';
import 'package:interior_design/data/models.dart';
import 'package:interior_design/data/project_status.dart';
import 'package:interior_design/data/site_news.dart';
import 'package:interior_design/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:interior_design/env.dart';

import '../test/room_glb_test.dart' show bedroom;
import '../test/test_utils.dart';

const _phone = Size(390, 844);

Future<void> shoot(
  WidgetTester tester,
  Widget screen,
  String name, {
  Future<void> Function()? before,
  Size size = _phone,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      home: screen,
    ),
  );
  // let image assets (the logo) decode, which needs real time
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await before?.call();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../docs/screenshots/$name.png'),
  );
  // stop any looping animation before the test ends
  await tester.pumpWidget(const SizedBox());
}

FloorPlanRecord _plan(String id) => FloorPlanRecord(
  floorPlanId: id,
  userId: 'u',
  imagePath: '',
  status: 'Uploaded',
  uploadDateTime: DateTime.now(),
);

ProjectSummary _project(
  String id,
  String title,
  ProjectStage stage, {
  int rooms = 6,
  int? score,
  Duration ago = const Duration(hours: 3),
}) => ProjectSummary(
  plan: _plan(id),
  stage: stage,
  title: title,
  roomCount: rooms,
  updatedAt: DateTime.now().subtract(ago),
  score: score,
);

/// The Material icon font ships with the SDK; tests don't load it, which
/// would draw every icon as an empty box.
Future<void> loadMaterialIcons() async {
  final exe = Platform.resolvedExecutable.replaceAll(r'\', '/');
  final cache = exe.indexOf('/bin/cache/');
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      (cache == -1 ? null : exe.substring(0, cache));
  if (root == null) return;
  final file = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!file.existsSync()) return;
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  await loader.load();
}

Map<String, dynamic> _piece(
  String id,
  String type,
  List<num> bbox,
  num height,
  String facing, {
  String? role,
  String? label,
}) => {
  'id': id,
  'type': type,
  'bbox': bbox,
  'height': height,
  'facing': facing,
  'role': ?role,
  'label': ?label,
};

AnalysisLayout _roomLayout({
  required String type,
  required String title,
  required num score,
  required num width,
  required num length,
  required List<Map<String, dynamic>> furniture,
}) => AnalysisLayout.fromJson({
  'layout': {
    'type': type,
    'title': title,
    'score': score,
    'suitability_score': 88,
  },
  'room': {
    'width': width,
    'length': length,
    'height': 2800,
    'area_m2': width * length / 1e6,
    'cutouts': <Object>[],
  },
  'validation': {'valid': true},
  'openings': {
    'doors': [
      {'wall': 'south', 'position': 500, 'width': 900},
    ],
    'windows': [
      {
        'wall': 'north',
        'position': width / 2 - 700,
        'width': 1400,
        'sill_height': 900,
        'height': 1200,
      },
    ],
  },
  'furniture': furniture,
});

AnalysisLayout _kitchen() => _roomLayout(
  type: 'l_shape',
  title: 'L-shaped kitchen',
  score: 94,
  width: 4000,
  length: 3000,
  furniture: [
    _piece(
      'f1',
      'fridge',
      [100, 2350, 700, 2900],
      1800,
      'south',
      label: 'Fridge',
    ),
    _piece(
      'c1',
      'counter',
      [700, 2400, 1900, 2900],
      900,
      'south',
      role: 'prep counter',
      label: 'Prep counter',
    ),
    _piece('s1', 'sink', [1900, 2400, 2700, 2900], 900, 'south', label: 'Sink'),
    _piece(
      'h1',
      'stove',
      [2700, 2400, 3300, 2900],
      900,
      'south',
      label: 'Stove',
    ),
    _piece(
      'c2',
      'counter',
      [3300, 2400, 3900, 2900],
      900,
      'south',
      label: 'Counter',
    ),
    _piece(
      'c3',
      'counter',
      [1200, 1000, 2800, 1600],
      900,
      'north',
      role: 'serving counter',
      label: 'Island',
    ),
  ],
);

AnalysisLayout _dining() => _roomLayout(
  type: 'table_centre',
  title: 'Table for four',
  score: 91,
  width: 4000,
  length: 3400,
  furniture: [
    _piece(
      't1',
      'dining_table',
      [1000, 1000, 3000, 2400],
      750,
      'north',
      label: 'Dining table',
    ),
    _piece(
      'd1',
      'dining_chair',
      [1250, 500, 1750, 1000],
      900,
      'north',
      label: 'Chair',
    ),
    _piece(
      'd2',
      'dining_chair',
      [2250, 500, 2750, 1000],
      900,
      'north',
      label: 'Chair',
    ),
    _piece(
      'd3',
      'dining_chair',
      [1250, 2400, 1750, 2900],
      900,
      'south',
      label: 'Chair',
    ),
    _piece(
      'd4',
      'dining_chair',
      [2250, 2400, 2750, 2900],
      900,
      'south',
      label: 'Chair',
    ),
    _piece(
      'sb',
      'sideboard',
      [300, 3000, 2000, 3350],
      850,
      'south',
      label: 'Sideboard',
    ),
  ],
);

SavedDesignRecord _design(
  String id,
  String room,
  AnalysisLayout layout,
  Duration ago,
) => SavedDesignRecord(
  designId: id,
  floorPlanId: 'p',
  roomId: id,
  roomName: room,
  title: layout.title,
  score: layout.score.round(),
  layout: layout,
  modelPath: null,
  previewPath: null,
  updatedAt: DateTime.now().subtract(ago),
);

const _profile = AppUserProfile(
  userId: 'u',
  email: 'malinga@example.com',
  fullName: 'Malinga Bandara',
  userName: 'malinga',
  role: 'User',
  bio: 'Designing a small flat in Colombo.',
  location: 'Colombo, Sri Lanka',
);

const _rooms = [
  ('Living room', '5.2 × 4.1 m · 21.3 m²', .94, 88, 'from the 5200 mm label'),
  ('Kitchen', '4.0 × 2.6 m · 10.4 m²', .91, 79, 'from the 4000 × 2600 label'),
  ('Bedroom', '3.6 × 3.2 m · 11.5 m²', .89, 82, 'from the wall scale'),
  ('Bathroom', '2.0 × 3.2 m · 6.4 m²', .86, 74, 'from the wall scale'),
  ('Dining', '3.4 × 2.0 m · 6.8 m²', .83, 70, 'from the wall scale'),
  ('Hallway', '3.4 × 1.8 m · 6.1 m²', .72, 0, 'from the wall scale'),
];

void main() {
  setUpAll(loadRoboto);
  setUpAll(loadMaterialIcons);
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseEnv.url,
      publishableKey: SupabaseEnv.anonKey,
    );
  });

  final projects = [
    _project('1', 'Modern Living Room', ProjectStage.layoutReady),
    _project(
      '2',
      'Main Bedroom',
      ProjectStage.layoutSelected,
      score: 92,
      ago: const Duration(days: 1),
    ),
    _project(
      '3',
      'Colombo Apartment',
      ProjectStage.layoutSelected,
      score: 88,
      rooms: 8,
      ago: const Duration(days: 3),
    ),
    _project(
      '4',
      'Studio Flat',
      ProjectStage.detected,
      rooms: 4,
      ago: const Duration(days: 5),
    ),
  ];

  testWidgets('welcome', (tester) async {
    await shoot(
      tester,
      WelcomeScreen(
        loadStats: () async =>
            const SiteStats(users: 128, floorPlans: 342, layouts: 1204),
      ),
      'welcome',
    );
  });

  testWidgets('sign in', (tester) async {
    await shoot(tester, const AuthScreen(startInSignIn: true), 'sign-in');
  });

  testWidgets('home', (tester) async {
    await shoot(
      tester,
      dashboardPreviewForTest(
        profile: const AppUserProfile(
          userId: 'u',
          email: 'malinga@example.com',
          fullName: 'Malinga Bandara',
          userName: 'malinga',
          role: 'User',
        ),
        summaries: projects,
      ),
      'home',
    );
  });

  testWidgets('projects', (tester) async {
    await shoot(tester, projectsPreviewForTest(projects), 'projects');
  });

  testWidgets('upload', (tester) async {
    await shoot(tester, const UploadScreen(), 'upload');
  });

  testWidgets('detected rooms', (tester) async {
    await shoot(
      tester,
      roomSelectionPreviewForTest(const [
        (
          'Living room',
          '5.2 × 4.1 m · 21.3 m²',
          .94,
          88,
          'from the 5200 mm label',
        ),
        (
          'Kitchen',
          '4.0 × 2.6 m · 10.4 m²',
          .91,
          79,
          'from the 4000 × 2600 label',
        ),
        ('Bedroom', '3.6 × 3.2 m · 11.5 m²', .89, 82, 'from the wall scale'),
        ('Bathroom', '2.0 × 3.2 m · 6.4 m²', .86, 74, 'from the wall scale'),
        ('Dining', '3.4 × 2.0 m · 6.8 m²', .83, 70, 'from the wall scale'),
        ('Hallway', '3.4 × 1.8 m · 6.1 m²', .72, 0, 'from the wall scale'),
      ]),
      'room-selection',
    );
  });

  testWidgets('layout choices', (tester) async {
    final json = jsonDecode(
      File('test/fixtures/living_room_layouts.json').readAsStringSync(),
    );
    final set = AnalysisLayoutSet.from(json)!;
    await shoot(
      tester,
      layoutsPreviewForTest(roomName: 'Living room', set: set),
      'layout-choices',
    );
  });

  testWidgets('3d viewer pieces', (tester) async {
    await shoot(
      tester,
      roomViewerForTest(roomName: 'Bedroom', layout: bedroom()),
      'layout-bedroom',
    );
  });

  testWidgets('3d viewer details', (tester) async {
    await shoot(
      tester,
      roomViewerForTest(roomName: 'Bedroom', layout: bedroom()),
      'room-details',
      before: () async {
        await tester.tap(find.text('Room details'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });

  testWidgets('sign up', (tester) async {
    await shoot(tester, const AuthScreen(), 'sign-up');
  });

  testWidgets('forgot password', (tester) async {
    await shoot(tester, const ForgotPasswordScreen(), 'forgot-password');
  });

  testWidgets('reset password', (tester) async {
    await shoot(tester, const ResetPasswordScreen(), 'reset-password');
  });

  testWidgets('processing', (tester) async {
    await shoot(tester, processingPreviewForTest(), 'processing');
  });

  testWidgets('about', (tester) async {
    await shoot(tester, const AboutScreen(), 'about');
  });

  testWidgets('help', (tester) async {
    await shoot(tester, const HelpScreen(), 'help');
  });

  testWidgets('profile', (tester) async {
    await shoot(
      tester,
      profilePreviewForTest(_profile, projects: 4, rooms: 11),
      'profile',
    );
  });

  testWidgets('admin accounts', (tester) async {
    final now = DateTime.now();
    await shoot(
      tester,
      adminPreviewForTest([
        AdminUserRecord(
          userId: '1',
          fullName: 'Dumindu Malinga',
          userName: 'dumindu',
          email: 'dumindu@example.com',
          role: 'Admin',
          lastSignIn: now,
        ),
        AdminUserRecord(
          userId: '2',
          fullName: 'Nethmi Perera',
          userName: 'nethmi',
          email: 'nethmi@example.com',
          role: 'Customer',
          lastSignIn: now.subtract(const Duration(days: 2)),
        ),
        AdminUserRecord(
          userId: '3',
          fullName: 'Kasun Silva',
          userName: 'kasun_s',
          email: 'kasun@example.com',
          role: 'Customer',
          lastSignIn: now.subtract(const Duration(days: 9)),
        ),
        const AdminUserRecord(
          userId: '4',
          fullName: 'Ayesha Fernando',
          userName: 'ayesha',
          email: 'ayesha@example.com',
          role: 'Customer',
        ),
      ], const []),
      'admin-accounts',
    );
  });

  testWidgets('saved designs', (tester) async {
    await shoot(
      tester,
      designsPreviewForTest([
        _design('a', 'Bedroom', bedroom(), const Duration(hours: 5)),
        _design('b', 'Kitchen', _kitchen(), const Duration(days: 1)),
        _design('c', 'Dining', _dining(), const Duration(days: 4)),
      ]),
      'saved-designs',
    );
  });

  testWidgets('kitchen in 3d', (tester) async {
    await shoot(
      tester,
      roomViewerForTest(roomName: 'Kitchen', layout: _kitchen()),
      'layout-kitchen',
    );
  });

  testWidgets('dining room in 3d', (tester) async {
    await shoot(
      tester,
      roomViewerForTest(roomName: 'Dining', layout: _dining()),
      'layout-dining-room',
    );
  });

  testWidgets('3d viewer on desktop', (tester) async {
    await shoot(
      tester,
      roomViewerForTest(roomName: 'Bedroom', layout: bedroom()),
      'room-3d-viewer-desktop',
      size: const Size(1280, 800),
    );
  });

  testWidgets('saved design details on a tablet', (tester) async {
    await shoot(
      tester,
      roomViewerForTest(roomName: 'Kitchen', layout: _kitchen()),
      'saved-design-details',
      size: const Size(820, 1000),
    );
  });

  testWidgets('room list on a wide screen', (tester) async {
    await shoot(
      tester,
      roomSelectionPreviewForTest(_rooms),
      'room-selection-list',
      size: const Size(1100, 760),
    );
  });
}
