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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _background,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ProfileHeader(
                name: 'Jamie Morgan',
                email: 'jamie.morgan@gmail.com',
                initials: 'JM',
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(
                    child: _ProfileStat(
                      icon: Icons.grid_view_rounded,
                      value: '12',
                      label: 'Projects',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _ProfileStat(
                      icon: Icons.meeting_room_outlined,
                      value: '34',
                      label: 'Rooms designed',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _ProfileStat(
                      icon: Icons.calendar_today_outlined,
                      value: 'Sep 2026',
                      label: 'Member since',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Account',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
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
                      activeThumbColor: _blue,
                      onChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
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
              const SizedBox(height: 22),
              const Text(
                'Admin',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 22),
              const Text(
                'Support',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & support',
                    onTap: () => _notify(context, 'Help & support'),
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Planly AI',
                    subtitle: 'Version 1.0.0',
                    onTap: () => _notify(context, 'About'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _signOut(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B6B),
                    side: const BorderSide(color: Color(0x55FF6B6B)),
                    backgroundColor: const Color(
                      0xFFFF6B6B,
                    ).withValues(alpha: .08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Sign out',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _notify(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        content: Text('$feature coming soon.'),
      ),
    );
  }

  void _signOut(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      (route) => false,
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
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_violet, _blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: _background, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const _ProPill(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProPill extends StatelessWidget {
  const _ProPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _violet.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _violet.withValues(alpha: .35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFFC9B8FF), size: 12),
          SizedBox(width: 5),
          Text(
            'PRO PLAN',
            style: TextStyle(
              color: Color(0xFFC9B8FF),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _blue, size: 18),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 9.5),
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
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                indent: 54,
                color: Colors.white.withValues(alpha: .06),
              ),
          ],
        ],
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: _muted, size: 19),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (subtitle != null) ...[
              Text(
                subtitle!,
                style: const TextStyle(color: _muted, fontSize: 11.5),
              ),
              const SizedBox(width: 6),
            ],
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _muted,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}
