part of 'main.dart';

/// Admin panel for reviewing `DeletionRequest` rows: search, filter by
/// status, and approve (which deletes the auth user via the `delete-user`
/// edge function) or reject.
class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _tab = 0;
  List<DeletionRequestRecord>? _accounts;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await AdminRepository.instance.fetchDeletionRequests();
    if (!mounted) return;
    setState(() => _accounts = accounts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DeletionRequestRecord> get _filtered {
    final accounts = _accounts ?? const [];
    final byTab = switch (_tab) {
      0 => accounts.where((a) => a.status == DeletionStatus.pending),
      1 => accounts.where((a) => a.status == DeletionStatus.approved),
      _ => accounts,
    };
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return byTab.toList();
    return byTab
        .where(
          (a) =>
              a.displayName.toLowerCase().contains(q) ||
              (a.email ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  int _countFor(int tab) {
    final accounts = _accounts ?? const [];
    return switch (tab) {
      0 => accounts.where((a) => a.status == DeletionStatus.pending).length,
      1 => accounts.where((a) => a.status == DeletionStatus.approved).length,
      _ => accounts.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loading = _accounts == null;
    final results = _filtered;
    final wide = !context.screenSize.isMobile;

    final search = _SearchField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v),
    );
    final tabs = Row(
      children: [
        for (final (index, label) in const ['Pending', 'Approved', 'All'].indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          _FilterTab(
            label: label,
            count: _countFor(index),
            selected: _tab == index,
            onTap: () => setState(() => _tab = index),
          ),
        ],
      ],
    );

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
                          SizedBox(width: 420, child: tabs),
                        ],
                      )
                    else ...[
                      search,
                      const SizedBox(height: AppSpacing.md),
                      tabs,
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      )
                    else if (results.isEmpty)
                      const _EmptyState()
                    else
                      _AccountList(
                        accounts: results,
                        busyIds: _busyIds,
                        onApprove: _approve,
                        onReject: _reject,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approve(DeletionRequestRecord account) async {
    setState(() => _busyIds.add(account.requestId));
    try {
      await AdminRepository.instance.approveRequest(account);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${account.displayName} approved and removed.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not approve: $error')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(account.requestId));
    }
  }

  Future<void> _reject(DeletionRequestRecord account) async {
    setState(() => _busyIds.add(account.requestId));
    try {
      await AdminRepository.instance.rejectRequest(account.requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${account.displayName} rejected.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not reject: $error')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(account.requestId));
    }
  }
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
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
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
              border: Border.all(color: selected ? Colors.transparent : c.border),
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
