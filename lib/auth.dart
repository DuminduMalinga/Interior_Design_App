part of 'main.dart';

/// Combined sign up / sign in screen. A single form toggles between the two
/// modes so the layout, validation, and social button stay in one place.
class AuthScreen extends StatefulWidget {
  const AuthScreen({this.startInSignIn = false, super.key});

  /// Opens the form in sign-in mode instead of the default sign-up mode.
  final bool startInSignIn;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late bool _isSignUp = !widget.startInSignIn;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final wide = !context.screenSize.isMobile;

    final form = Form(
      key: _formKey,
      child: Column(
        children: [
          const _AuthLogo(),
          const SizedBox(height: AppSpacing.xl),
          Text(
            _isSignUp ? 'Create your account' : 'Welcome back',
            textAlign: TextAlign.center,
            style: text.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _isSignUp
                ? 'Sign up to start turning floor plans into AI-designed spaces.'
                : 'Sign in to pick up where you left off.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (_isSignUp) ...[
            AppInputField(
              controller: _fullNameController,
              hintText: 'Full name',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter your full name';
                }
                if (v.trim().length < 2) return 'Name is too short';
                if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(v.trim())) {
                  return 'Only letters, spaces, - and \' allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppInputField(
              controller: _usernameController,
              hintText: 'Username',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a username';
                if (v.trim().length < 3) return 'At least 3 characters';
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                  return 'Letters, numbers, _ only';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppInputField(
            controller: _emailController,
            hintText: 'Email address',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInputField(
            controller: _passwordController,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction:
                _isSignUp ? TextInputAction.next : TextInputAction.done,
            suffixIcon: _VisibilityToggle(
              obscured: _obscurePassword,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your password';
              if (v.length < 6) return 'At least 6 characters';
              if (_isSignUp &&
                  !RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(v)) {
                return 'Include a letter and a number';
              }
              return null;
            },
          ),
          if (_isSignUp) ...[
            const SizedBox(height: AppSpacing.lg),
            AppInputField(
              controller: _confirmPasswordController,
              hintText: 'Confirm password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              suffixIcon: _VisibilityToggle(
                obscured: _obscureConfirmPassword,
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
          if (!_isSignUp)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: TextButton(
                  onPressed: () => _notify(context, 'Password reset'),
                  child: const Text('Forgot password?'),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: _isSignUp ? 'Create account' : 'Sign in',
            loading: _submitting,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
          const _OrDivider(),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => _notify(context, 'Google sign-in'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: c.glassFill,
              side: BorderSide(color: c.glassBorder),
            ),
            icon: const AppGoogleMark(),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _isSignUp
                    ? 'Already have an account?'
                    : "Don't have an account?",
                style: text.bodySmall?.copyWith(color: c.textMuted),
              ),
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(_isSignUp ? 'Sign in' : 'Sign up'),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.screenSize.gutter,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 460 : 400),
                  // On larger screens the form sits on a glass panel instead
                  // of floating directly on the backdrop.
                  child: wide
                      ? AppCard(
                          glass: true,
                          radius: AppRadius.xlAll,
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: form,
                        )
                      : form,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _notify(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon.')),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: context.colors.textMuted,
        size: 18,
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Column(
      children: [
        const AppLogoMark(size: 72),
        const SizedBox(height: AppSpacing.md),
        Text('LiviSpace', style: context.text.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Design spaces for better living',
          style: context.text.labelSmall?.copyWith(color: c.textMuted),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Row(
      children: [
        Expanded(child: Divider(color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or continue with',
            style: context.text.labelSmall?.copyWith(color: c.textMuted),
          ),
        ),
        Expanded(child: Divider(color: c.border)),
      ],
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: c.backgroundGradient),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-.6, -.9),
            radius: 1.1,
            colors: [c.secondary.withValues(alpha: 0.16), Colors.transparent],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(.9, .8),
              radius: 1.2,
              colors: [c.primary.withValues(alpha: 0.14), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}
