/// Live totals shown on the welcome screen, as the web's landing page shows
/// them (`useSiteStats.ts`, from the `get_site_stats` function).
class SiteStats {
  const SiteStats({
    required this.users,
    required this.floorPlans,
    required this.layouts,
  });

  /// Reads the row `get_site_stats` returns: a list holding one row, or the
  /// row itself. Null when it is not there, so the screen shows dashes.
  static SiteStats? fromRpc(Object? data) {
    final row = data is List ? (data.isEmpty ? null : data.first) : data;
    if (row is! Map) return null;
    int? count(Object? v) => v is num ? v.toInt() : int.tryParse('$v');
    final users = count(row['UserCount']);
    final floorPlans = count(row['FloorPlanCount']);
    final layouts = count(row['LayoutCount']);
    if (users == null || floorPlans == null || layouts == null) return null;
    return SiteStats(users: users, floorPlans: floorPlans, layouts: layouts);
  }

  final int users;
  final int floorPlans;
  final int layouts;
}

/// A count with thousands separators ("12,345"), or a dash when it is not
/// known yet: the web's `formatCount`.
String formatCount(int? n) {
  if (n == null) return '—';
  final digits = n.abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return n < 0 ? '-$grouped' : grouped;
}

/// Why product news could not be sent, in words an admin can act on: the
/// web's `NEWS_PROBLEMS`, plus the two the server can also give.
String newsProblem(String? reason) => switch (reason) {
  'not_configured' =>
    "Email isn't set up yet. Add the RESEND_API_KEY secret in Supabase, "
        'then try again.',
  'limit' => "You've reached today's email limit. Try again tomorrow.",
  'provider_error' =>
    'The email service refused the message. Check the API key and sender '
        'address in Supabase.',
  'domain_not_verified' =>
    'Resend only delivers to your own address until you verify a domain '
        'there. Use "Send me a test", or verify a domain in Resend and set '
        'MAIL_FROM to an address on it.',
  'no_address' => 'Your account has no email address to send a test to.',
  null || '' => 'The message could not be sent.',
  final other => other,
};

/// The line under the title of the news dialog: who will get the message.
String newsReadersNote(int? readers) {
  if (readers == null) {
    return 'Emailed to everyone who turned on Product news.';
  }
  if (readers == 0) {
    return 'Nobody has Product news turned on, so there is no one to send '
        'this to.';
  }
  return "Emailed to $readers ${readers == 1 ? 'person' : 'people'} who "
      "turned on Product news. It can't be unsent.";
}

/// What the admin is told after sending to everyone.
String newsSentMessage(int recipients) =>
    'Product news sent to $recipients '
    "${recipients == 1 ? 'person' : 'people'}.";
