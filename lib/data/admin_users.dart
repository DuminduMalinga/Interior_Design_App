import 'models.dart';

/// Which accounts the admin list shows by role.
enum RoleFilter {
  all('All'),
  admin('Admins'),
  customer('Customers');

  const RoleFilter(this.label);

  final String label;

  bool allows(AdminUserRecord user) => switch (this) {
    all => true,
    admin => user.isAdmin,
    customer => !user.isAdmin,
  };
}

/// What the admin list can be sorted by (the web's columns).
enum UserSort {
  name('Name'),
  email('Email'),
  role('Role'),
  lastSignIn('Last active');

  const UserSort(this.label);

  final String label;

  /// The direction a field starts in when first picked: newest sign-in
  /// first, everything else A to Z.
  bool get startsAscending => this != lastSignIn;
}

/// The admin list's filtering and sorting, as the web's account page does it.
abstract final class AdminUserList {
  /// How many accounts each role filter would show, for the chips.
  static Map<RoleFilter, int> counts(List<AdminUserRecord> users) => {
    for (final filter in RoleFilter.values)
      filter: users.where(filter.allows).length,
  };

  /// The accounts that match [query] (in name, username or email) and the
  /// role [filter], ordered by [sort].
  static List<AdminUserRecord> apply(
    List<AdminUserRecord> users, {
    String query = '',
    RoleFilter filter = RoleFilter.all,
    UserSort sort = UserSort.name,
    bool ascending = true,
  }) {
    final q = query.trim().toLowerCase();
    final matches = [
      for (final u in users)
        if (filter.allows(u) &&
            (q.isEmpty ||
                u.fullName.toLowerCase().contains(q) ||
                u.userName.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q)))
          u,
    ];

    Comparable<Object> key(AdminUserRecord u) => switch (sort) {
      UserSort.name => u.displayName.toLowerCase(),
      UserSort.email => u.email.toLowerCase(),
      UserSort.role => u.isAdmin ? 'admin' : 'customer',
      // never signed in sorts as the oldest
      UserSort.lastSignIn => u.lastSignIn?.millisecondsSinceEpoch ?? 0,
    };

    // List.sort is not stable, so ties keep their order through the index
    final indexed = [for (final (i, u) in matches.indexed) (i, u)];
    indexed.sort((a, b) {
      final ka = key(a.$2), kb = key(b.$2);
      final order = ka is num
          ? ka.compareTo(kb as num)
          : (ka as String).compareTo(kb as String);
      if (order != 0) return ascending ? order : -order;
      return a.$1.compareTo(b.$1);
    });
    return [for (final (_, u) in indexed) u];
  }

  /// The direction after tapping [field] while [current] is sorted [ascending]:
  /// the same field flips, a new one starts in its own natural direction.
  static bool directionAfterPicking(
    UserSort field, {
    required UserSort current,
    required bool ascending,
  }) => field == current ? !ascending : field.startsAscending;
}
