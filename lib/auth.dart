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
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const _AuthLogo(),
                        const SizedBox(height: 22),
                        Text(
                          _isSignUp ? 'Create your account' : 'Welcome back',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUp
                              ? 'Sign up to start turning floor plans into\nAI-designed spaces.'
                              : 'Sign in to pick up where you left off.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (_isSignUp) ...[
                          _AuthField(
                            controller: _fullNameController,
                            hint: 'Full name',
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.name,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter your full name';
                              }
                              if (v.trim().length < 2) {
                                return 'Name is too short';
                              }
                              if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(v.trim())) {
                                return 'Only letters, spaces, - and \' allowed';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _AuthField(
                            controller: _usernameController,
                            hint: 'Username',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.text,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter a username';
                              }
                              if (v.trim().length < 3) {
                                return 'At least 3 characters';
                              }
                              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                                return 'Letters, numbers, _ only';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        _AuthField(
                          controller: _emailController,
                          hint: 'Email address',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your email';
                            }
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v.trim())) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _AuthField(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _muted,
                              size: 18,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your password';
                            }
                            if (v.length < 6) return 'At least 6 characters';
                            if (_isSignUp &&
                                !RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$')
                                    .hasMatch(v)) {
                              return 'Include a letter and a number';
                            }
                            return null;
                          },
                        ),
                        if (_isSignUp) ...[
                          const SizedBox(height: 14),
                          _AuthField(
                            controller: _confirmPasswordController,
                            hint: 'Confirm password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _muted,
                                size: 18,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Confirm your password';
                              }
                              if (v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (!_isSignUp) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  _notify(context, 'Password reset'),
                              style: TextButton.styleFrom(
                                foregroundColor: _blue,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_blue, _violet],
                              ),
                              borderRadius: BorderRadius.circular(17),
                              boxShadow: [
                                BoxShadow(
                                  color: _blue.withValues(alpha: .28),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isSignUp ? 'Create account' : 'Sign in',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const _OrDivider(),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => _notify(context, 'Google sign-in'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: .04,
                              ),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: .14),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            icon: const _GoogleMark(),
                            label: const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUp
                                  ? 'Already have an account?'
                                  : "Don't have an account?",
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12.5,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _isSignUp = !_isSignUp),
                              style: TextButton.styleFrom(
                                foregroundColor: _blue,
                                padding: const EdgeInsets.only(left: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                _isSignUp ? 'Sign in' : 'Sign up',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
      SnackBar(
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        content: Text('$feature coming soon.'),
      ),
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

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_violet, _blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .2)),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: .35),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Planly AI',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
          ),
        ),
      ],
    );
  }
}

/// A rounded input field that glows with the app's electric-blue accent
/// while focused.
class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: _blue.withValues(alpha: .28),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          filled: true,
          fillColor: _surface,
          hintText: widget.hint,
          hintStyle: const TextStyle(color: _muted, fontSize: 13),
          prefixIcon: Icon(
            widget.icon,
            size: 19,
            color: _focused ? _blue : _muted,
          ),
          suffixIcon: widget.suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _blue, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
          ),
          errorStyle: const TextStyle(fontSize: 10.5),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: .10))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'or continue with',
            style: TextStyle(color: _muted, fontSize: 10.5),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: .10))),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-.6, -.9),
          radius: 1.1,
          colors: [_violet.withValues(alpha: .16), Colors.transparent],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(.9, .8),
            radius: 1.2,
            colors: [_blue.withValues(alpha: .14), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
