import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/admin_controls.dart';
import 'package:interior_design/app_theme.dart';
import 'package:interior_design/data/admin_users.dart';
import 'package:interior_design/data/models.dart';
import 'package:interior_design/main.dart';

import 'test_utils.dart';

AdminUserRecord user(
  String id,
  String name, {
  String role = 'Customer',
  String? email,
  String? userName,
  String? lastSignIn,
  String? avatar,
}) => AdminUserRecord.fromJson({
  'UserID': id,
  'FullName': name,
  'UserName': userName ?? name.toLowerCase().replaceAll(' ', '_'),
  'Email': email ?? '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
  'Role': role,
  'LastSignIn': lastSignIn,
  'AvatarUrl': avatar,
});

List<String> names(List<AdminUserRecord> users) => [
  for (final u in users) u.fullName,
];

/// The admin account list's role filter, sorting and avatars, as the web's
/// account page has them.
void main() {
  setUpAll(loadRoboto);

  final ada = user(
    '1',
    'Ada Lovelace',
    role: 'Admin',
    lastSignIn: '2026-10-24T10:00:00Z',
  );
  final bob = user('2', 'bob Brown', lastSignIn: '2026-10-26T10:00:00Z');
  final cy = user('3', 'Cy Young', lastSignIn: '2026-10-20T10:00:00Z');
  final dee = user('4', 'Dee Dunn', role: 'admin'); // never signed in
  final all = [bob, dee, ada, cy];

  group('role filter', () {
    test('counts each role, with everyone under All', () {
      final counts = AdminUserList.counts(all);
      expect(counts[RoleFilter.all], 4);
      expect(counts[RoleFilter.admin], 2);
      expect(counts[RoleFilter.customer], 2);
    });

    test('counts an empty list as zero everywhere', () {
      expect(AdminUserList.counts(const []).values, everyElement(0));
    });

    test(
      'keeps only the role asked for, whatever the case it is stored in',
      () {
        expect(
          names(AdminUserList.apply(all, filter: RoleFilter.admin)),
          unorderedEquals(['Ada Lovelace', 'Dee Dunn']),
        );
        expect(
          names(AdminUserList.apply(all, filter: RoleFilter.customer)),
          unorderedEquals(['bob Brown', 'Cy Young']),
        );
      },
    );

    test('an unknown role is a customer, as on the web', () {
      final odd = user('9', 'Eve', role: 'Moderator');
      expect(RoleFilter.customer.allows(odd), isTrue);
      expect(RoleFilter.admin.allows(odd), isFalse);
    });
  });

  group('search', () {
    test('matches name, username or email, in any case', () {
      expect(names(AdminUserList.apply(all, query: 'LOVELACE')), [
        'Ada Lovelace',
      ]);
      expect(
        names(
          AdminUserList.apply([
            user('7', 'Zed', userName: 'quiet_one'),
          ], query: 'quiet'),
        ),
        ['Zed'],
      );
      expect(
        names(
          AdminUserList.apply([
            user('8', 'Yan', email: 'yan@corp.test'),
          ], query: '@corp'),
        ),
        ['Yan'],
      );
    });

    test('ignores spaces around the search', () {
      expect(names(AdminUserList.apply(all, query: '  cy  ')), ['Cy Young']);
    });

    test('combines with the role filter', () {
      expect(
        names(
          AdminUserList.apply(all, query: 'brown', filter: RoleFilter.customer),
        ),
        ['bob Brown'],
      );
      expect(
        AdminUserList.apply(all, query: 'brown', filter: RoleFilter.admin),
        isEmpty,
      );
      expect(
        AdminUserList.apply(
          all,
          query: 'lovelace',
          filter: RoleFilter.customer,
        ),
        isEmpty,
      );
    });
  });

  group('sorting', () {
    test('goes by name, A to Z without regard to case', () {
      expect(names(AdminUserList.apply(all, sort: UserSort.name)), [
        'Ada Lovelace',
        'bob Brown',
        'Cy Young',
        'Dee Dunn',
      ]);
    });

    test('can be reversed', () {
      expect(
        names(AdminUserList.apply(all, sort: UserSort.name, ascending: false)),
        ['Dee Dunn', 'Cy Young', 'bob Brown', 'Ada Lovelace'],
      );
    });

    test('goes by email', () {
      expect(names(AdminUserList.apply(all, sort: UserSort.email)), [
        'Ada Lovelace',
        'bob Brown',
        'Cy Young',
        'Dee Dunn',
      ]);
      final swapped = [
        user('a', 'Zoe', email: 'a@x.test'),
        user('b', 'Amy', email: 'z@x.test'),
      ];
      expect(names(AdminUserList.apply(swapped, sort: UserSort.email)), [
        'Zoe',
        'Amy',
      ]);
    });

    test('puts admins before customers, keeping each group\'s order', () {
      expect(
        names(AdminUserList.apply(all, sort: UserSort.role)),
        ['Dee Dunn', 'Ada Lovelace', 'bob Brown', 'Cy Young'],
        reason: 'ties keep the order they came in',
      );
    });

    test('orders by last sign-in, with never signed in as the oldest', () {
      expect(
        names(
          AdminUserList.apply(all, sort: UserSort.lastSignIn, ascending: false),
        ),
        ['bob Brown', 'Ada Lovelace', 'Cy Young', 'Dee Dunn'],
      );
      expect(names(AdminUserList.apply(all, sort: UserSort.lastSignIn)), [
        'Dee Dunn',
        'Cy Young',
        'Ada Lovelace',
        'bob Brown',
      ]);
    });

    test('sorts only what the filters let through', () {
      expect(
        names(
          AdminUserList.apply(
            all,
            filter: RoleFilter.customer,
            sort: UserSort.name,
            ascending: false,
          ),
        ),
        ['Cy Young', 'bob Brown'],
      );
    });

    test('does not change the list it was given', () {
      final before = [...all];
      AdminUserList.apply(all, sort: UserSort.email, ascending: false);
      expect(all, before);
    });

    test('a name is the full name, else the username', () {
      final nameless = user('5', '', userName: 'aaa_first');
      expect(
        names(AdminUserList.apply([bob, nameless], sort: UserSort.name)).first,
        '',
        reason: 'the username aaa_first sorts before bob',
      );
    });
  });

  group('picking a sort', () {
    test('the same field again reverses it', () {
      expect(
        AdminUserList.directionAfterPicking(
          UserSort.name,
          current: UserSort.name,
          ascending: true,
        ),
        isFalse,
      );
      expect(
        AdminUserList.directionAfterPicking(
          UserSort.name,
          current: UserSort.name,
          ascending: false,
        ),
        isTrue,
      );
    });

    test('a new field starts A to Z, except last sign-in, newest first', () {
      expect(
        AdminUserList.directionAfterPicking(
          UserSort.email,
          current: UserSort.name,
          ascending: false,
        ),
        isTrue,
      );
      expect(
        AdminUserList.directionAfterPicking(
          UserSort.lastSignIn,
          current: UserSort.name,
          ascending: true,
        ),
        isFalse,
      );
    });
  });

  group('reading an account', () {
    test('keeps its picture address, and none when blank', () {
      expect(
        user('1', 'A', avatar: 'https://x/a.png').avatarUrl,
        'https://x/a.png',
      );
      expect(
        user('1', 'A', avatar: '  https://x/b.png ').avatarUrl,
        'https://x/b.png',
      );
      expect(user('1', 'A', avatar: '').avatarUrl, isNull);
      expect(user('1', 'A', avatar: '   ').avatarUrl, isNull);
      expect(user('1', 'A').avatarUrl, isNull);
    });
  });

  group('the controls', () {
    Future<void> show(WidgetTester tester, Widget child, {Size? size}) async {
      tester.view.physicalSize = size ?? const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('role chips show their counts and report a tap', (
      tester,
    ) async {
      final picked = <RoleFilter>[];
      await show(
        tester,
        RoleFilterChips(
          counts: AdminUserList.counts(all),
          selected: RoleFilter.all,
          onSelect: picked.add,
        ),
      );
      expect(find.text('All (4)'), findsOneWidget);
      expect(find.text('Admins (2)'), findsOneWidget);
      expect(find.text('Customers (2)'), findsOneWidget);

      await tester.tap(find.text('Admins (2)'));
      expect(picked, [RoleFilter.admin]);
    });

    testWidgets('the chosen role chip is the selected one', (tester) async {
      await show(
        tester,
        RoleFilterChips(
          counts: AdminUserList.counts(all),
          selected: RoleFilter.customer,
          onSelect: (_) {},
        ),
      );
      final chips = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .toList();
      expect([for (final c in chips) c.selected], [false, false, true]);
    });

    testWidgets(
      'the sort menu shows the field and direction, and lists every option',
      (tester) async {
        final picked = <UserSort>[];
        await show(
          tester,
          UserSortMenu(
            field: UserSort.name,
            ascending: true,
            onPick: picked.add,
          ),
        );
        expect(find.text('Name'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

        await tester.tap(find.byType(UserSortMenu));
        await tester.pumpAndSettle();
        for (final label in ['Name', 'Email', 'Role', 'Last active']) {
          expect(find.text(label), findsWidgets, reason: label);
        }
        await tester.tap(find.text('Last active'));
        await tester.pumpAndSettle();
        expect(picked, [UserSort.lastSignIn]);
      },
    );

    testWidgets('the sort arrow points the other way when descending', (
      tester,
    ) async {
      await show(
        tester,
        UserSortMenu(
          field: UserSort.lastSignIn,
          ascending: false,
          onPick: (_) {},
        ),
      );
      expect(find.text('Last active'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    for (final (name, size) in const [
      ('mobile', Size(320, 640)),
      ('tablet', Size(800, 900)),
    ]) {
      testWidgets('fit a $name screen together', (tester) async {
        await show(
          tester,
          Row(
            children: [
              Expanded(
                child: RoleFilterChips(
                  counts: const {
                    RoleFilter.all: 1234,
                    RoleFilter.admin: 12,
                    RoleFilter.customer: 1222,
                  },
                  selected: RoleFilter.all,
                  onSelect: (_) {},
                ),
              ),
              UserSortMenu(
                field: UserSort.lastSignIn,
                ascending: false,
                onPick: (_) {},
              ),
            ],
          ),
          size: size,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('an account card', () {
    Future<void> show(WidgetTester tester, AdminUserRecord u) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: adminUserCardForTest(u),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows initials when the account has no picture', (
      tester,
    ) async {
      await show(tester, ada);
      expect(find.text('AL'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('shows the picture when it has one', (tester) async {
      await show(
        tester,
        user('1', 'Ada Lovelace', avatar: 'http://localhost:1/a.png'),
      );
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('falls back to initials when the picture will not load', (
      tester,
    ) async {
      await show(
        tester,
        user('1', 'Ada Lovelace', avatar: 'http://localhost:1/a.png'),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.text('AL'), findsOneWidget);
    });
  });
}
