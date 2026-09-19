part of 'main.dart';

/// Reached from the sign-in form's "Forgot password?" link.
///
/// The username and email identify which account is being reset, so they're
/// shown locked (read-only) rather than editable — this screen only ever
/// sets a new password for the account already on file.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    this.username = 'jamie.morgan',
    this.email = 'jamie.morgan@gmail.com',
    super.key,
  });

  final String username;
  final String email;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
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
            'Reset your password',
            textAlign: TextAlign.center,
            style: text.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This is the account we found. Choose a new password to '
            'finish resetting it.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppInputField(
            label: 'Username',
            initialValue: widget.username,
            enabled: false,
            prefixIcon: Icons.alternate_email_rounded,
            suffixIcon: Icon(Icons.lock_outline_rounded, size: 16, color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInputField(
            label: 'Email address',
            initialValue: widget.email,
            enabled: false,
            prefixIcon: Icons.mail_outline_rounded,
            suffixIcon: Icon(Icons.lock_outline_rounded, size: 16, color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
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
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a new password';
              if (v.length < 6) return 'At least 6 characters';
              if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(v)) {
                return 'Include a letter and a number';
              }
              return null;
            },
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
            label: 'Reset password',
            loading: _submitting,
            onPressed: _submit,
          ),
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
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset. Sign in with your new password.')),
    );
    Navigator.of(context).pop();
  }
}
