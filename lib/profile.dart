part of 'main.dart';

/// The signed-in user's profile: identity, usage stats, account settings,
/// and sign out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wide = !context.screenSize.isMobile;

    const header = _ProfileHeader(
      name: 'Jamie Morgan',
      email: 'jamie.morgan@gmail.com',
      initials: 'JM',
    );
    const stats = Row(
      children: [
        Expanded(
          child: _ProfileStat(
            icon: Icons.grid_view_rounded,
            value: '12',
            label: 'Projects',
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ProfileStat(
            icon: Icons.meeting_room_outlined,
            value: '34',
            label: 'Rooms designed',
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ProfileStat(
            icon: Icons.calendar_today_outlined,
            value: 'Sep 2026',
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
              onTap: () => _notify(context, 'Edit profile'),
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
        const SizedBox(height: AppSpacing.xl),
        const _SectionLabel('Admin'),
        _SettingsGroup(
          children: [
            _SettingsTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Manage accounts',
              subtitle: 'Review and approve sign-ups',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminAccountsScreen(),
                ),
              ),
            ),
          ],
        ),
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Profile'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: AppContentFrame(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              header,
                              SizedBox(height: AppSpacing.xl),
                              stats,
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
                        stats,
                        const SizedBox(height: AppSpacing.xxl),
                        settings,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _notify(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon.')),
    );
  }

  void _signOut(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      (route) => false,
    );
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
                  Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
