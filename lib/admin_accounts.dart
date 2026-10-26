part of 'main.dart';

/// Admin panel (SRS UC3). Two tabs: every registered account, which an admin
/// can search and delete after confirming (customers only: admin accounts are
/// protected, as on the web), and the activity log of what admins did.
class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _tab = 0; // 0 = accounts, 1 = activity
  List<AdminUserRecord>? _users;
  List<AuditEntry>? _activity;
  bool _loadFailed = false;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final users = await AdminRepository.instance.fetchUsers();
      // the log is a nicety: the accounts still show if it cannot be read
      final activity = await AdminRepository.instance
          .fetchAuditLog()
          .catchError((Object _) => <AuditEntry>[]);
      if (!mounted) return;
      setState(() {
        _users = users;
        _activity = activity;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(String q, Iterable<String?> fields) =>
      q.isEmpty || fields.any((f) => (f ?? '').toLowerCase().contains(q));

  List<AdminUserRecord> get _filteredUsers {
    final q = _query.trim().toLowerCase();
    return [
      for (final u in _users ?? const <AdminUserRecord>[])
        if (_matches(q, [u.fullName, u.userName, u.email])) u,
    ];
  }

  List<AuditEntry> get _filteredActivity {
    final q = _query.trim().toLowerCase();
    return [
      for (final a in _activity ?? const <AuditEntry>[])
        if (_matches(q, [a.label, a.summary])) a,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final loading = _users == null && !_loadFailed;
    final wide = !context.screenSize.isMobile;

    final search = _SearchField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v),
    );
    final tabs = Row(
      children: [
        _FilterTab(
          label: 'Accounts',
          count: _users?.length ?? 0,
          selected: _tab == 0,
          onTap: () => setState(() => _tab = 0),
        ),
        const SizedBox(width: AppSpacing.sm),
        _FilterTab(
          label: 'Activity',
          count: _activity?.length ?? 0,
          selected: _tab == 1,
          onTap: () => setState(() => _tab = 1),
        ),
      ],
    );

    final Widget body;
    if (_loadFailed && _users == null) {
      body = _LoadError(onRetry: _load);
    } else if (loading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    } else if (_tab == 0) {
      final users = _filteredUsers;
      body = users.isEmpty
          ? const _EmptyState()
          : _CardWrap(
              children: [
                for (final user in users)
                  _UserCard(
                    user: user,
                    isSelf: user.userId == AuthService.instance.currentUser?.id,
                    busy: _busyIds.contains(user.userId),
                    onDelete: () => _deleteUser(user),
                  ),
              ],
            );
    } else {
      final activity = _filteredActivity;
      body = activity.isEmpty
          ? const _EmptyState()
          : _CardWrap(
              children: [for (final entry in activity) _ActivityCard(entry)],
            );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Manage accounts'),
        actions: [
          IconButton(
            onPressed: _sendNews,
            tooltip: 'Send product news',
            icon: const Icon(Icons.mail_outline_rounded),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: AppContentFrame(
                verticalPadding: AppSpacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wide)
                      Row(
                        children: [
                          Expanded(child: search),
                          const SizedBox(width: AppSpacing.lg),
                          SizedBox(width: 320, child: tabs),
                        ],
                      )
                    else ...[
                      search,
                      const SizedBox(height: AppSpacing.md),
                      tabs,
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    body,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// Runs a destructive admin action with a busy marker, a result message and
  /// a reload afterwards.
  Future<void> _run(
    String busyId,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _busyIds.add(busyId));
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) return;
      final message = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : 'Something went wrong. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(busyId));
        await _load();
      }
    }
  }

  /// Opens the product-news form; when it was sent to everyone, says to how
  /// many.
  Future<void> _sendNews() async {
    final recipients = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ProductNewsDialog(),
    );
    if (recipients == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(newsSentMessage(recipients))));
  }

  Future<void> _deleteUser(AdminUserRecord user) async {
    final ok = await _confirm(
      title: 'Delete account?',
      message:
          'This permanently deletes ${user.displayName} (@${user.userName}). '
          'This cannot be undone.',
      action: 'Delete',
    );
    if (!ok || !mounted) return;
    await _run(
      user.userId,
      () => AdminRepository.instance.deleteAccount(user.userId),
      '${user.displayName} was deleted.',
    );
  }
}

/// The form for emailing product news to everyone who turned on "Product
/// news", or to the admin alone as a test (the web's `NewsDialog`). Closes
/// with how many people it was sent to; a test leaves it open.
class ProductNewsDialog extends StatefulWidget {
  const ProductNewsDialog({super.key, this.countReaders, this.send});

  /// How many people will get it; the database unless a test says otherwise.
  final Future<int> Function()? countReaders;

  /// Sends the message and returns how many people got it.
  final Future<int> Function({
    required String subject,
    required String message,
    required bool testOnly,
  })?
  send;

  @override
  State<ProductNewsDialog> createState() => _ProductNewsDialogState();
}

class _ProductNewsDialogState extends State<ProductNewsDialog> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  int? _readers;
  bool _sending = false;
  bool _testSent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subject.addListener(_changed);
    _message.addListener(_changed);
    _countReaders();
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<void> _countReaders() async {
    try {
      final count =
          await (widget.countReaders ??
              AdminRepository.instance.countNewsReaders)();
      if (mounted) setState(() => _readers = count);
    } catch (_) {
      // the note simply stays general
    }
  }

  bool get _ready =>
      _subject.text.trim().isNotEmpty && _message.text.trim().isNotEmpty;

  Future<void> _submit({required bool testOnly}) async {
    if (!_ready || _sending || (!testOnly && _readers == 0)) return;
    setState(() {
      _sending = true;
      _error = null;
      _testSent = false;
    });
    try {
      final send = widget.send ?? AdminRepository.instance.sendProductNews;
      final recipients = await send(
        subject: _subject.text.trim(),
        message: _message.text.trim(),
        testOnly: testOnly,
      );
      if (!mounted) return;
      if (testOnly) {
        setState(() => _testSent = true);
      } else {
        Navigator.of(context).pop(recipients);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'The message could not be sent.';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return PopScope(
      canPop: !_sending,
      child: AlertDialog(
        title: const Text('Send product news'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsReadersNote(_readers),
                  style: text.bodySmall?.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _subject,
                  enabled: !_sending,
                  maxLength: 150,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _message,
                  enabled: !_sending,
                  maxLength: 5000,
                  minLines: 5,
                  maxLines: 8,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: text.bodySmall?.copyWith(color: c.error),
                  ),
                ],
                if (_testSent) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Test sent to your own address. Check your inbox.',
                    style: text.bodySmall?.copyWith(color: c.success),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _sending ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _ready && !_sending
                ? () => _submit(testOnly: true)
                : null,
            child: const Text('Send me a test'),
          ),
          FilledButton(
            onPressed: _ready && !_sending && _readers != 0
                ? () => _submit(testOnly: false)
                : null,
            child: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send to everyone'),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppInputField(
      controller: controller,
      onChanged: onChanged,
      hintText: 'Search by name or email',
      prefixIcon: Icons.search_rounded,
      textInputAction: TextInputAction.search,
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 52,
            decoration: BoxDecoration(
              gradient: selected ? c.brandGradient : null,
              color: selected ? null : c.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: selected ? Colors.transparent : c.border,
              ),
            ),
            child: Center(
              child: Text(
                '$label ($count)',
                style: context.text.labelMedium?.copyWith(
                  color: selected ? c.onPrimary : c.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded, color: c.textMuted, size: 46),
            const SizedBox(height: AppSpacing.lg),
            Text('No accounts found', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try a different search or switch filters.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// One column on phones, two on tablets, three on desktop.
class _CardWrap extends StatelessWidget {
  const _CardWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(mobile: 1, tablet: 2, desktop: 3);
    const spacing = AppSpacing.md;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.busy,
    required this.onDelete,
  });

  final AdminUserRecord user;
  final bool isSelf;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: c.brandGradient,
              border: Border.all(color: c.glassBorder, width: 1.5),
            ),
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: Text(
                  user.initials,
                  style: text.labelLarge?.copyWith(color: c.onPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppStatusChip(
                      label: user.isAdmin ? 'Admin' : 'Customer',
                      status: user.isAdmin ? AppStatus.info : AppStatus.neutral,
                    ),
                    Text(
                      user.lastSignIn == null
                          ? 'Never signed in'
                          : 'Last sign-in ${_formatRelativeDate(user.lastSignIn!)}',
                      style: text.labelSmall?.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (!isSelf && !user.isAdmin)
            _RoundIconButton(
              icon: Icons.delete_outline_rounded,
              color: c.error,
              tooltip: 'Delete account',
              onTap: onDelete,
            ),
        ],
      ),
    );
  }
}

/// One line of the admin activity log.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard(this.entry);

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history_rounded, color: c.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.label, style: text.titleSmall),
                if (entry.summary.isNotEmpty)
                  Text(
                    entry.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: c.textMuted),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatRelativeDate(entry.createdAt),
                  style: text.labelSmall?.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
