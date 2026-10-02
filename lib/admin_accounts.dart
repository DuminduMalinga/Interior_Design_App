part of 'main.dart';

/// Admin panel (SRS UC3). Two tabs: every registered account, which an admin
/// can search and delete after confirming, and the pending account-deletion
/// requests users have submitted, which can be approved (deleting the
/// account) or rejected.
class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _tab = 0; // 0 = accounts, 1 = deletion requests
  List<AdminUserRecord>? _users;
  List<DeletionRequestRecord>? _requests;
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
      final requests = await AdminRepository.instance.fetchDeletionRequests();
      if (!mounted) return;
      setState(() {
        _users = users;
        _requests = requests;
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

  List<DeletionRequestRecord> get _filteredRequests {
    final q = _query.trim().toLowerCase();
    return [
      for (final r in _requests ?? const <DeletionRequestRecord>[])
        if (_matches(q, [r.displayName, r.username, r.email])) r,
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
          label: 'Requests',
          count: _requests?.length ?? 0,
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
      final requests = _filteredRequests;
      body = requests.isEmpty
          ? const _EmptyState()
          : _AccountList(
              accounts: requests,
              busyIds: _busyIds,
              onApprove: _approve,
              onReject: _reject,
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

  Future<void> _approve(DeletionRequestRecord request) async {
    final ok = await _confirm(
      title: 'Approve deletion?',
      message: 'This permanently deletes ${request.displayName}\'s account.',
      action: 'Approve & delete',
    );
    if (!ok || !mounted) return;
    await _run(
      request.requestId,
      () => AdminRepository.instance.approveRequest(request),
      '${request.displayName} approved and removed.',
    );
  }

  Future<void> _reject(DeletionRequestRecord request) => _run(
    request.requestId,
    () => AdminRepository.instance.rejectRequest(request.requestId),
    '${request.displayName} rejected.',
  );
}

/// One column on phones, two on tablets, three on desktop. Cards keep their
/// natural height, so this wraps instead of using a fixed-ratio grid.
class _AccountList extends StatelessWidget {
  const _AccountList({
    required this.accounts,
    required this.busyIds,
    required this.onApprove,
    required this.onReject,
  });

  final List<DeletionRequestRecord> accounts;
  final Set<String> busyIds;
  final ValueChanged<DeletionRequestRecord> onApprove;
  final ValueChanged<DeletionRequestRecord> onReject;

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
            for (final account in accounts)
              SizedBox(
                width: width,
                child: _AccountCard(
                  account: account,
                  busy: busyIds.contains(account.requestId),
                  onApprove: () => onApprove(account),
                  onReject: () => onReject(account),
                ),
              ),
          ],
        );
      },
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

AppStatus _deletionStatusVisual(DeletionStatus status) => switch (status) {
  DeletionStatus.pending => AppStatus.warning,
  DeletionStatus.approved => AppStatus.success,
  DeletionStatus.rejected => AppStatus.error,
};

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final DeletionRequestRecord account;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final pending = account.status == DeletionStatus.pending;
    final statusVisual = _deletionStatusVisual(account.status);

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
                  account.initials,
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
                  account.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
                if (account.email != null)
                  Text(
                    account.email!,
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
                      label: account.status.raw,
                      status: statusVisual,
                    ),
                    Text(
                      'Requested ${_formatRelativeDate(account.requestedAt)}',
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
          else if (pending)
            Column(
              children: [
                _RoundIconButton(
                  icon: Icons.check_rounded,
                  color: c.success,
                  tooltip: 'Approve',
                  onTap: onApprove,
                ),
                const SizedBox(height: AppSpacing.sm),
                _RoundIconButton(
                  icon: Icons.close_rounded,
                  color: c.error,
                  tooltip: 'Reject',
                  onTap: onReject,
                ),
              ],
            )
          else
            Icon(
              account.status == DeletionStatus.approved
                  ? Icons.verified_rounded
                  : Icons.block_rounded,
              color: statusVisual.colorIn(c),
              size: 20,
            ),
        ],
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
          else if (!isSelf)
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
