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
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.year}';
}

class _ProfileScreenState extends State<ProfileScreen> {
  NotificationPrefs _prefs = const NotificationPrefs();
  AppUserProfile? _profile;
  bool _isAdmin = false;
  ({int projects, int rooms})? _stats;
  bool _avatarBusy = false;

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
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as AppUserProfile?;
      _prefs = _profile?.notifications ?? const NotificationPrefs();
      _stats = results[1] as ({int projects, int rooms});
      _isAdmin = results[2] as bool;
    });
  }

  /// Lets the user switch between the dark and light look; it applies at
  /// once and is remembered on this device.
  Future<void> _chooseAppearance() async {
    final current = ThemeController.instance.value;
    final choice = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (mode, label, icon) in const [
              (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
              (ThemeMode.light, 'Light', Icons.light_mode_outlined),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: mode == current
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(mode),
              ),
          ],
        ),
      ),
    );
    if (choice == null || choice == current) return;
    await ThemeController.instance.set(choice);
    if (mounted) setState(() {});
  }

  /// Lets the user choose a new picture or remove the current one.
  Future<void> _editAvatar() async {
    final hasPicture = _profile?.avatarUrl != null;
    final choice = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(hasPicture ? 'Choose a new photo' : 'Choose a photo'),
              onTap: () => Navigator.of(context).pop(true),
            ),
            if (hasPicture)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Remove photo'),
                onTap: () => Navigator.of(context).pop(false),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice) {
      await _pickAvatar();
    } else {
      await _removeAvatar();
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAvatar() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: avatarExtensions,
    );
    if (file == null) return;

    final extension = (file.extension ?? file.name.split('.').last)
        .toLowerCase();
    final problem = checkAvatarFile(
      extension: extension,
      size: await file.length(),
    );
    if (problem != null) return _say(problem);

    setState(() => _avatarBusy = true);
    try {
      final picture = await shrinkAvatar(
        await file.readAsBytes(),
        avatarContentType(extension),
      );
      await AvatarRepository.instance.upload(
        userId: user.id,
        bytes: picture.bytes,
        contentType: picture.contentType,
      );
      await _reloadProfile();
    } catch (_) {
      _say('The picture could not be saved. Try again.');
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _removeAvatar() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    setState(() => _avatarBusy = true);
    try {
      await AvatarRepository.instance.remove(user.id);
      await _reloadProfile();
    } catch (_) {
      _say('The picture could not be removed. Try again.');
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _reloadProfile() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final profile = await UserRepository.instance.fetchProfile(user.id);
    if (!mounted) return;
    setState(() => _profile = profile ?? _profile);
  }

  /// Saves a notification choice to the account (shared with the web app),
  /// putting the switch back if that fails.
  Future<void> _setPrefs(NotificationPrefs next) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final before = _prefs;
    setState(() => _prefs = next);
    try {
      await UserRepository.instance.saveNotificationPrefs(user.id, next);
    } catch (_) {
      if (!mounted) return;
      setState(() => _prefs = before);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save that choice. Try again.')),
      );
    }
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
      avatarUrl: profile?.avatarUrl,
      avatarBusy: _avatarBusy,
      onEditAvatar: profile == null ? null : _editAvatar,
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
              icon: Icons.mark_email_unread_outlined,
              title: 'Email notifications',
              subtitle: 'Plan ready and design saved',
              trailing: Switch(
                value: _prefs.email,
                activeThumbColor: c.primary,
                onChanged: (v) => _setPrefs(_prefs.copyWith(email: v)),
              ),
            ),
            _SettingsTile(
              icon: Icons.campaign_outlined,
              title: 'Product news',
              subtitle: 'Updates from the InteriorAI team',
              trailing: Switch(
                value: _prefs.updates,
                activeThumbColor: c.primary,
                onChanged: (v) => _setPrefs(_prefs.copyWith(updates: v)),
              ),
            ),
            _SettingsTile(
              icon: ThemeController.instance.value == ThemeMode.light
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              title: 'Appearance',
              subtitle: ThemeController.instance.value == ThemeMode.light
                  ? 'Light'
                  : 'Dark',
              onTap: _chooseAppearance,
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
                subtitle: 'View and delete accounts, review requests',
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
              title: 'Delete my account',
              subtitle: 'Permanently removes your account and files',
              onTap: profile == null
                  ? null
                  : () => _deleteAccount(context, profile),
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
      selectedIndex: 4,
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

  /// Deletes the account after the user types their password (as on the web).
  Future<void> _deleteAccount(
    BuildContext context,
    AppUserProfile profile,
  ) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your account, floor plans and saved '
              'designs. It cannot be undone. Enter your password to confirm.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.isEmpty) return;
    try {
      await UserRepository.instance.deleteMyAccount(
        email: profile.email,
        password: password,
      );
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!context.mounted) return;
      final message = error is AuthException
          ? error.message
          : 'Could not delete the account. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
    required this.avatarUrl,
    required this.avatarBusy,
    required this.onEditAvatar,
  });

  final String name;
  final String email;
  final String initials;
  final String? avatarUrl;

  /// A picture is being saved or removed.
  final bool avatarBusy;

  /// Null until the profile has loaded.
  final VoidCallback? onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return Row(
      children: [
        Semantics(
          button: true,
          label: avatarUrl == null
              ? 'Add a profile picture'
              : 'Change profile picture',
          child: GestureDetector(
            onTap: avatarBusy ? null : onEditAvatar,
            child: Stack(
              children: [
                AppAvatar(
                  initials: initials,
                  imageUrl: avatarUrl,
                  size: 76,
                  borderWidth: 2,
                  textStyle: text.headlineSmall,
                  glow: true,
                ),
                if (avatarBusy)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.scrim,
                      ),
                      child: const Center(
                        child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
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
          ),
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
