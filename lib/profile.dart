part of 'main.dart';

/// The signed-in user's profile: identity, usage stats, account settings,
/// and sign out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

String _monthYear(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.year}';
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  AppUserProfile? _profile;
  bool _isAdmin = false;
  ({int projects, int rooms})? _stats;
  DeletionRequestRecord? _deletionRequest;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profile == null) _load();
  }

  Future<void> _load() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final results = await Future.wait([
      UserRepository.instance.fetchProfile(user.id),
      UserRepository.instance.fetchStats(user.id),
      AuthService.instance.isAdmin(),
      UserRepository.instance.fetchOwnDeletionRequest(user.id),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as AppUserProfile?;
      _stats = results[1] as ({int projects, int rooms});
      _isAdmin = results[2] as bool;
      _deletionRequest = results[3] as DeletionRequestRecord?;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wide = !context.screenSize.isMobile;
    final user = AuthService.instance.currentUser;
    final profile = _profile;
    final stats = _stats;

    final header = _ProfileHeader(
      name: profile?.fullName ?? 'Loading...',
      email: profile?.email ?? user?.email ?? '',
      initials: profile?.initials ?? '?',
    );
    final statsRow = Row(
      children: [
        Expanded(
          child: _ProfileStat(
            icon: Icons.grid_view_rounded,
            value: '${stats?.projects ?? '—'}',
            label: 'Projects',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ProfileStat(
            icon: Icons.meeting_room_outlined,
            value: '${stats?.rooms ?? '—'}',
            label: 'Rooms designed',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ProfileStat(
            icon: Icons.calendar_today_outlined,
            value: user?.createdAt == null
                ? '—'
                : _monthYear(DateTime.parse(user!.createdAt)),
            label: 'Member since',
          ),
        ),
      ],
    );

    final settings = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Account'),
        _SettingsGroup(
          children: [
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Edit profile',
              onTap: profile == null
                  ? null
                  : () => _editProfile(context, profile),
            ),
            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              title: 'Push notifications',
              trailing: Switch(
                value: _notificationsEnabled,
                activeThumbColor: c.primary,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
            ),
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'Appearance',
              subtitle: 'Dark',
              onTap: () => _notify(context, 'Appearance'),
            ),
          ],
        ),
        if (_isAdmin) ...[
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Admin'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Manage accounts',
                subtitle: 'Review account deletion requests',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminAccountsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        const _SectionLabel('Support'),
        _SettingsGroup(
          children: [
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & support',
              onTap: () => _notify(context, 'Help & support'),
            ),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About LiviSpace',
              subtitle: 'Version 1.0.0',
              onTap: () => _notify(context, 'About'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionLabel('Danger zone'),
        _SettingsGroup(
          children: [
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: _deletionRequest?.status == DeletionStatus.pending
                  ? 'Account deletion requested'
                  : 'Delete my account',
              subtitle: _deletionRequest?.status == DeletionStatus.pending
                  ? 'An admin will review your request'
                  : 'Submit a request for an admin to review',
              onTap: (profile == null ||
                      _deletionRequest?.status == DeletionStatus.pending)
                  ? null
                  : () => _requestDeletion(context, profile),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        OutlinedButton.icon(
          onPressed: () => _signOut(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: c.error,
            side: BorderSide(color: c.error.withValues(alpha: 0.35)),
            backgroundColor: c.error.withValues(alpha: 0.08),
          ),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Sign out'),
        ),
      ],
    );

    return _TabScaffold(
      selectedIndex: 3,
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AppContentFrame(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            header,
                            const SizedBox(height: AppSpacing.xl),
                            statsRow,
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxl),
                      Expanded(flex: 5, child: settings),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      const SizedBox(height: AppSpacing.xl),
                      statsRow,
                      const SizedBox(height: AppSpacing.xxl),
                      settings,
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _notify(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon.')));
  }

  Future<void> _editProfile(
    BuildContext context,
    AppUserProfile profile,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: profile),
    );
    if (updated == true) _load();
  }

  Future<void> _requestDeletion(
    BuildContext context,
    AppUserProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          "This sends a request to an admin to permanently delete your "
          "account. You'll keep access until it's approved.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Request deletion'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await UserRepository.instance.requestAccountDeletion(profile);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deletion request submitted.')),
      );
      _load();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not submit request: $error')));
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }
}

/// A small bottom-sheet form for editing the mutable fields on `User`.
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile});

  final AppUserProfile profile;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _fullNameController = TextEditingController(
    text: widget.profile.fullName,
  );
  late final _bioController = TextEditingController(
    text: widget.profile.bio ?? '',
  );
  late final _locationController = TextEditingController(
    text: widget.profile.location ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.profile.phone ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.backgroundElevated,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          border: Border.all(color: c.border),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit profile', style: context.text.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                AppInputField(
                  controller: _fullNameController,
                  hintText: 'Full name',
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppInputField(
                  controller: _bioController,
                  hintText: 'Bio',
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                AppInputField(
                  controller: _locationController,
                  hintText: 'Location',
                  prefixIcon: Icons.place_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppInputField(
                  controller: _phoneController,
                  hintText: 'Phone',
                  prefixIcon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Save changes',
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await UserRepository.instance.updateProfile(
        userId: widget.profile.userId,
        fullName: _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(label, style: context.text.titleSmall),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.initials,
  });

  final String name;
  final String email;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return Row(
      children: [
        Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: c.brandGradient,
                border: Border.all(color: c.glassBorder, width: 2),
                boxShadow: AppShadows.glow(c.primary),
              ),
              child: SizedBox.square(
                dimension: 76,
                child: Center(
                  child: Text(
                    initials,
                    style: text.headlineSmall?.copyWith(color: c.onPrimary),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.background, width: 2),
                ),
                child: SizedBox.square(
                  dimension: 26,
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: c.onPrimary,
                    size: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: text.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppStatusChip(
                label: 'PRO PLAN',
                icon: Icons.auto_awesome_rounded,
                color: c.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Icon(icon, color: c.primary, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall,
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall?.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppCard(
      padding: EdgeInsets.zero,
      // Ink splashes paint on the nearest Material, so it has to sit inside
      // the card's decoration to be visible.
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(height: 1, indent: 56, color: c.border),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Row(
            children: [
              Icon(icon, color: c.textMuted, size: 20),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: Text(title, style: text.titleSmall)),
              if (subtitle != null) ...[
                Flexible(
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: c.textMuted),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: c.textMuted,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
