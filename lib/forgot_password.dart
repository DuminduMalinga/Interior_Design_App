part of 'main.dart';

/// Reached from the sign-in form's "Forgot password?" link.
///
/// Collects the account email and asks Supabase to send a password-reset
/// link. Following that link reopens the app on [ResetPasswordScreen] via
/// the `passwordRecovery` auth event handled in [MyApp].
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({this.initialEmail = '', super.key});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );

  bool _submitting = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
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
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primary.withValues(alpha: 0.14),
              border: Border.all(color: c.primary.withValues(alpha: 0.30)),
            ),
            child: SizedBox.square(
              dimension: 64,
              child: Icon(
                _sent
                    ? Icons.mark_email_read_outlined
                    : Icons.lock_reset_rounded,
                color: c.primary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _sent ? 'Check your email' : 'Reset your password',
            textAlign: TextAlign.center,
            style: text.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _sent
                ? 'If an account exists for ${_emailController.text.trim()}, '
                      'we sent a link to reset the password.'
                : "Enter your account's email and we'll send you a link to "
                      'reset your password.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (!_sent) ...[
            AppInputField(
              controller: _emailController,
              hintText: 'Email address',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Send reset link',
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await AuthService.instance.resetPasswordForEmail(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _sent = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final message = error is AuthException
          ? error.message
          : 'Could not send the reset email. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

/// Opened automatically when a password-recovery link brings the user back
/// into the app (see the `passwordRecovery` listener in [MyApp]). Supabase
/// has already exchanged the link for a recovery session by the time this
/// screen is reachable, so submitting here simply sets the new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;

  @override
  void dispose() {
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
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primary.withValues(alpha: 0.14),
              border: Border.all(color: c.primary.withValues(alpha: 0.30)),
            ),
            child: SizedBox.square(
              dimension: 64,
              child: Icon(Icons.lock_reset_rounded, color: c.primary, size: 28),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Choose a new password',
            textAlign: TextAlign.center,
            style: text.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "You're verified â€” set a new password to finish.",
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppInputField(
            controller: _passwordController,
            label: 'New password',
            hintText: 'Enter a new password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: _VisibilityToggle(
              obscured: _obscurePassword,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) =>
                validateStrongPassword(v, emptyMessage: 'Enter a new password'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInputField(
            controller: _confirmPasswordController,
            label: 'Confirm new password',
            hintText: 'Re-enter the new password',
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
              if (v == null || v.isEmpty) return 'Confirm your new password';
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Save new password',
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await supa.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. You are signed in.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final message = error is AuthException
          ? error.message
          : 'Could not update the password. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
