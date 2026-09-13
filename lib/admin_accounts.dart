part of 'main.dart';

enum _AccountStatus { pending, approved, rejected }

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _background,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Manage accounts',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SearchField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _FilterTab(
                        label: 'Pending',
                        count: _countFor(0),
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'Approved',
                        count: _countFor(1),
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'All',
                        count: _countFor(2),
                        selected: _tab == 2,
                        onTap: () => setState(() => _tab = 2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: results.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final account = results[index];
                        return _AccountCard(
                          account: account,
                          onApprove: () => _updateStatus(
                            account,
                            _AccountStatus.approved,
                          ),
                          onReject: () => _updateStatus(
                            account,
                            _AccountStatus.rejected,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateStatus(_UserAccount account, _AccountStatus status) {
    setState(() => account.status = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        content: Text(
          status == _AccountStatus.approved
              ? '${account.name} approved.'
              : '${account.name} rejected.',
        ),
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
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _muted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search by name or email',
                hintStyle: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkWell(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, color: _muted, size: 18),
              ),
            ),
        ],
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [_blue, _violet])
                : null,
            color: selected ? null : _surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: .08),
            ),
          ),
          child: Center(
            child: Text(
              '$label ($count)',
              style: TextStyle(
                color: selected ? Colors.white : _muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_violet, _blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Center(
              child: Text(
                account.initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusBadge(status: account.status),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Joined ${account.joined}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (account.status == _AccountStatus.pending)
            Column(
              children: [
                _RoundIconButton(
                  icon: Icons.check_rounded,
                  color: const Color(0xFF4ADE80),
                  tooltip: 'Approve',
                  onTap: onApprove,
                ),
                const SizedBox(height: 8),
                _RoundIconButton(
                  icon: Icons.close_rounded,
                  color: const Color(0xFFFF6B6B),
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
              color: account.status == _AccountStatus.approved
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFFFF6B6B),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: .4)),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _AccountStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _AccountStatus.pending => ('Pending', const Color(0xFFF6C86A)),
      _AccountStatus.approved => ('Approved', const Color(0xFF4ADE80)),
      _AccountStatus.rejected => ('Rejected', const Color(0xFFFF6B6B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_rounded,
              color: Colors.white.withValues(alpha: .2),
              size: 46,
            ),
            const SizedBox(height: 14),
            const Text(
              'No accounts found',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different search or switch filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
