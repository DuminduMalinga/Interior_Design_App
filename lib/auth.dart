part of 'main.dart';

/// SRS FR4: at least 8 characters with an uppercase letter, a lowercase
/// letter, a number and a special character.
String? validateStrongPassword(String? v, {required String emptyMessage}) {
  if (v == null || v.isEmpty) return emptyMessage;
  if (v.length < 8) return 'At least 8 characters';
  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include an uppercase letter';
  if (!RegExp(r'[a-z]').hasMatch(v)) return 'Include a lowercase letter';
  if (!RegExp(r'\d').hasMatch(v)) return 'Include a number';
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
    return 'Include a special character';
  }
  return null;
}

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
            hintText: _isSignUp ? 'Email address' : 'Email or username',
            prefixIcon: _isSignUp
                ? Icons.mail_outline_rounded
                : Icons.person_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              final value = v?.trim() ?? '';
              if (_isSignUp) {
                if (value.isEmpty) return 'Enter your email';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return 'Enter a valid email';
                }
                return null;
              }
              // Sign in accepts either an email address or a username.
              if (value.isEmpty) return 'Enter your email or username';
              if (value.contains('@')) {
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return 'Enter a valid email';
                }
              } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                return 'Usernames use letters, numbers and underscores';
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
            textInputAction: _isSignUp
                ? TextInputAction.next
                : TextInputAction.done,
            suffixIcon: _VisibilityToggle(
              obscured: _obscurePassword,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            // Strength rules only apply when choosing a password; sign-in just
            // needs a value so accounts created under older rules still work.
            validator: (v) => _isSignUp
                ? validateStrongPassword(v, emptyMessage: 'Enter your password')
                : (v == null || v.isEmpty ? 'Enter your password' : null),
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ForgotPasswordScreen(
                        initialEmail: _emailController.text.contains('@')
                            ? _emailController.text.trim()
                            : '',
                      ),
                    ),
                  ),
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
            onPressed: () => _signInWithGoogle(context),
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

  void _showError(BuildContext context, Object error) {
    final message = error is AuthException
        ? error.message
        : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      await AuthService.instance.signInWithGoogle();
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      if (_isSignUp) {
        await AuthService.instance.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          username: _usernameController.text.trim(),
        );
        // SRS: a new account is sent to Sign In rather than straight into
        // the app. Supabase may have opened a session on sign-up, so close
        // it to make the user sign in explicitly.
        await AuthService.instance.signOut();
        if (!mounted) return;
        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _isSignUp = false;
          _submitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully')),
        );
        return;
      } else {
        await AuthService.instance.signIn(
          identifier: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (!mounted) return;
      // SRS FR10: admins land on account management, customers on the
      // dashboard. The dashboard stays underneath so admins can go back to it.
      var isAdmin = false;
      try {
        isAdmin = await AuthService.instance.isAdmin();
      } catch (_) {}
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      );
      if (isAdmin) {
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const AdminAccountsScreen()),
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showError(context, error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
