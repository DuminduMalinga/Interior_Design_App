part of 'main.dart';

enum _AccountStatus {
  pending,
  approved,
  rejected;

  AppStatus get status => switch (this) {
    pending => AppStatus.warning,
    approved => AppStatus.success,
    rejected => AppStatus.error,
  };

  String get label => switch (this) {
    pending => 'Pending',
    approved => 'Approved',
    rejected => 'Rejected',
  };
}

class _UserAccount {
  _UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.joined,
    required this.status,
  });

  final String id;
  final String name;
  final String email;
  final String joined;
  _AccountStatus status;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// Admin panel for reviewing and moderating user accounts: search, filter
/// by status, and approve or reject pending sign-ups.
class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _tab = 0;

  late final List<_UserAccount> _accounts = [
    _UserAccount(
      id: '1',
      name: 'Jamie Morgan',
      email: 'jamie.morgan@gmail.com',
      joined: 'Sep 12, 2026',
      status: _AccountStatus.pending,
    ),
    _UserAccount(
      id: '2',
      name: 'Aisha Rahman',
      email: 'aisha.rahman@outlook.com',
      joined: 'Sep 11, 2026',
      status: _AccountStatus.pending,
    ),
    _UserAccount(
      id: '3',
      name: 'Leo Fernandes',
      email: 'leo.fernandes@yahoo.com',
      joined: 'Sep 10, 2026',
      status: _AccountStatus.approved,
    ),
    _UserAccount(
      id: '4',
      name: 'Priya Nair',
      email: 'priya.nair@gmail.com',
      joined: 'Sep 9, 2026',
      status: _AccountStatus.approved,
    ),
    _UserAccount(
      id: '5',
      name: 'Marcus Chen',
      email: 'marcus.chen@studio.io',
      joined: 'Sep 7, 2026',
      status: _AccountStatus.rejected,
    ),
    _UserAccount(
      id: '6',
      name: 'Sofia Delgado',
      email: 'sofia.delgado@gmail.com',
      joined: 'Sep 6, 2026',
      status: _AccountStatus.pending,
    ),
    _UserAccount(
      id: '7',
      name: 'Ravi Kapoor',
      email: 'ravi.kapoor@buildwise.com',
      joined: 'Sep 3, 2026',
      status: _AccountStatus.approved,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_UserAccount> get _filtered {
    final byTab = switch (_tab) {
      0 => _accounts.where((a) => a.status == _AccountStatus.pending),
      1 => _accounts.where((a) => a.status == _AccountStatus.approved),
      _ => _accounts,
    };
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return byTab.toList();
    return byTab
        .where(
          (a) =>
              a.name.toLowerCase().contains(q) ||
              a.email.toLowerCase().contains(q),
        )
        .toList();
  }

  int _countFor(int tab) {
    return switch (tab) {
      0 => _accounts.where((a) => a.status == _AccountStatus.pending).length,
      1 => _accounts.where((a) => a.status == _AccountStatus.approved).length,
      _ => _accounts.length,
    };
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
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
                  if (results.isEmpty)
                    const _EmptyState()
                  else
                    _AccountList(
                      accounts: results,
                      onApprove: (a) => _updateStatus(a, _AccountStatus.approved),
                      onReject: (a) => _updateStatus(a, _AccountStatus.rejected),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateStatus(_UserAccount account, _AccountStatus status) {
    setState(() => account.status = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == _AccountStatus.approved
              ? '${account.name} approved.'
              : '${account.name} rejected.',
        ),
      ),
    );
  }
}

/// One column on phones, two on tablets, three on desktop. Cards keep their
/// natural height, so this wraps instead of using a fixed-ratio grid.
class _AccountList extends StatelessWidget {
  const _AccountList({
    required this.accounts,
    required this.onApprove,
    required this.onReject,
  });

  final List<_UserAccount> accounts;
  final ValueChanged<_UserAccount> onApprove;
  final ValueChanged<_UserAccount> onReject;

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

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.onApprove,
    required this.onReject,
  });

  final _UserAccount account;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final pending = account.status == _AccountStatus.pending;

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
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
                Text(
                  account.email,
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
                      label: account.status.label,
                      status: account.status.status,
                    ),
                    Text(
                      'Joined ${account.joined}',
                      style: text.labelSmall?.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (pending)
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
              account.status == _AccountStatus.approved
                  ? Icons.verified_rounded
                  : Icons.block_rounded,
              color: account.status.status.colorIn(c),
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
