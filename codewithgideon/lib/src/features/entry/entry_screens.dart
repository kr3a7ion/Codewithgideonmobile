import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/app_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScreen(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.premium),
          ),
          _GlowOrb(color: AppColors.teal, size: 180, top: 90, right: -20),
          _GlowOrb(
            color: AppColors.deepBlueLight,
            size: 240,
            bottom: 120,
            left: -60,
            opacity: 0.08,
          ),
          _GlowOrb(
            color: AppColors.orange,
            size: 220,
            top: 260,
            left: 90,
            opacity: 0.1,
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(size: 124)
                        .animate()
                        .scale(duration: 700.ms, curve: Curves.easeOutBack)
                        .fadeIn(),
                    const Gap(28),
                    Text(
                      'CodeWithGideon',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.deepBlueDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.25),
                    const Gap(10),
                    Text(
                      'Learn. Code. Excel.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 260.ms),
                    const Gap(54),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) =>
                            Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.deepBlue,
                                    shape: BoxShape.circle,
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .scale(
                                  delay: Duration(milliseconds: 200 * index),
                                  duration: 1200.ms,
                                  begin: const Offset(0.7, 0.7),
                                  end: const Offset(1.15, 1.15),
                                )
                                .fade(
                                  begin: 0.35,
                                  end: 1,
                                  delay: Duration(milliseconds: 200 * index),
                                  duration: 1200.ms,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();

  static const _slides = [
    _SlideData(
      title: 'Learn to Code',
      description:
          'Master programming with live interactive classes from expert instructors.',
      icon: Icons.code_rounded,
      colors: [AppColors.deepBlue, AppColors.deepBlueLight],
    ),
    _SlideData(
      title: 'Watch Anytime',
      description:
          'Access recorded lessons and resources 24/7 at your own pace.',
      icon: Icons.play_circle_rounded,
      colors: [AppColors.tealDark, AppColors.teal],
    ),
    _SlideData(
      title: 'Earn Certificates',
      description:
          'Complete courses and get recognised with industry-standard certificates.',
      icon: Icons.workspace_premium_rounded,
      colors: [AppColors.orange, AppColors.orangeLight],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(onboardingIndexProvider);
    final authController = ref.read(authControllerProvider.notifier);

    return AppScreen(
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await authController.markOnboardingSeen();
                    if (!context.mounted) return;
                    context.go('/welcome');
                  },
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) {
                    ref.read(onboardingIndexProvider.notifier).state = value;
                  },
                  itemBuilder: (context, pageIndex) {
                    final slide = _slides[pageIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 164,
                            height: 164,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: slide.colors),
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: AppShadows.premium,
                            ),
                            child: Icon(
                              slide.icon,
                              color: Colors.white,
                              size: 74,
                            ),
                          ).animate().fadeIn().scale(
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
                          const Gap(44),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                          const Gap(18),
                          Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.mutedForeground,
                                  height: 1.6,
                                ),
                          ).animate().fadeIn(delay: 180.ms),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SmoothPageIndicator(
                controller: _controller,
                count: _slides.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: AppColors.deepBlue,
                  dotColor: Color(0xFFD1D5DB),
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 3.2,
                ),
              ),
              const Gap(24),
              AppButton(
                label: index == _slides.length - 1 ? 'Get Started' : 'Next',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                ),
                onPressed: () async {
                  if (index == _slides.length - 1) {
                    await authController.markOnboardingSeen();
                    if (!context.mounted) return;
                    context.go('/welcome');
                    return;
                  }
                  await _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, AppColors.background, Color(0xFFEFF6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          _GlowOrb(
            color: AppColors.teal,
            size: 260,
            top: 70,
            right: -60,
            opacity: 0.18,
          ),
          _GlowOrb(
            color: AppColors.deepBlue,
            size: 280,
            bottom: 120,
            left: -70,
            opacity: 0.16,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Spacer(),
                  const BrandMark(size: 132),
                  const Gap(34),
                  const BrandWordmark(
                    height: 38,
                    color: AppColors.deepBlueDark,
                  ),
                  const Gap(18),
                  Text(
                    'Master coding with live classes, expert mentors, and a thriving community.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.mutedForeground,
                      height: 1.6,
                    ),
                  ),
                  const Gap(24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: const [
                      _FeaturePill(label: 'Live Classes'),
                      _FeaturePill(label: 'Pay As You Go!!'),
                      _FeaturePill(label: 'Certificates'),
                    ],
                  ),
                  const Spacer(),
                  AppButton(
                    label: 'Create Account',
                    leading: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => context.go('/signup'),
                  ),
                  const Gap(14),
                  AppButton(
                    label: 'Sign In',
                    leading: const Icon(
                      Icons.login_rounded,
                      color: AppColors.deepBlue,
                    ),
                    variant: AppButtonVariant.outline,
                    onPressed: () => context.go('/login'),
                  ),
                  const Gap(20),
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: const [
                        TextSpan(text: 'By continuing, you agree to our '),
                        TextSpan(
                          text: 'Terms',
                          style: TextStyle(
                            color: AppColors.deepBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: AppColors.deepBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Give iOS a beat to retract the keyboard before auth redirects the route.
    await _settleKeyboardBeforeRouteChange(context);
    await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (!authState.isAuthenticated) return;
    if (authState.enrollmentStatus == EnrollmentStatus.enrolled) {
      await ref.read(dashboardSnapshotProvider.future);
      if (!mounted) return;
      context.go('/dashboard');
      return;
    }
    if (authState.enrollmentStatus == EnrollmentStatus.notRegistered) {
      await ref.read(catalogRepositoryProvider).getPaths();
      if (!mounted) return;
      context.go('/continue-registration');
      return;
    }
    context.go('/enrollment');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        showAppSnackBar(context, next.errorMessage!);
      }
    });
    final authState = ref.watch(authControllerProvider);

    return AppScreen(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _AuthBackdrop(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(18),
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Sign in to continue your learning journey.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),

                  const Gap(32),
                  AppTextField(
                    label: 'Email Address',
                    hint: 'Enter your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                  const Gap(18),
                  AppTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    obscureText: _obscure,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                    ),
                  ),
                  const Gap(10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go('/forgot-password'),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const Gap(10),
                  AppButton(
                    label: 'Sign In',
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading ? null : _login,
                  ),
                  if (authState.errorMessage != null) ...[
                    const Gap(12),
                    Text(
                      'Sign in failed. Please check your details and try again.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                    ),
                  ],
                  const Gap(30),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "Don't have an account?",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const Gap(10),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  int get _strength {
    final length = _passwordController.text.length;
    if (length >= 8) return 3;
    if (length >= 5) return 2;
    if (length >= 1) return 1;
    return 0;
  }

  Future<void> _createAccount() async {
    if (_passwordController.text != _confirmController.text) {
      showAppSnackBar(context, "Passwords don't match.");
      return;
    }
    // Match login by dismissing the keyboard before the auth flow starts.
    await _settleKeyboardBeforeRouteChange(context);
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      final authState = ref.read(authControllerProvider);
      if (authState.isAuthenticated) {
        context.go('/continue-registration');
      } else if (authState.errorMessage != null) {
        showAppSnackBar(context, authState.errorMessage!);
      }
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordsMatch = _passwordController.text == _confirmController.text;

    return AppScreen(
      body: Stack(
        children: [
          _AuthBackdrop(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: AppColors.teal,
                        ),
                        const Gap(8),
                        Text(
                          'Start Your Journey',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.deepBlue),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Begin your learning adventure with CodeWithGideon.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const Gap(28),
                  AppTextField(
                    label: 'Email Address',
                    hint: 'email@yourmail.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const Gap(18),
                  AppTextField(
                    label: 'Password',
                    hint: 'Create a strong password',
                    controller: _passwordController,
                    obscureText: _obscure,
                    prefixIcon: Icons.lock_outline_rounded,
                    onChanged: (_) => setState(() {}),
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                    ),
                  ),
                  if (_strength > 0) ...[
                    const Gap(10),
                    Row(
                      children: List.generate(
                        3,
                        (index) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                            height: 6,
                            decoration: BoxDecoration(
                              color: _strength > index
                                  ? index == 0
                                        ? Colors.red
                                        : index == 1
                                        ? Colors.orange
                                        : Colors.green
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      _strength == 1
                          ? 'Password is too weak'
                          : _strength == 2
                          ? 'Password strength: Good'
                          : 'Password strength: Strong',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const Gap(18),
                  AppTextField(
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    prefixIcon: Icons.lock_outline_rounded,
                    onChanged: (_) => setState(() {}),
                    suffix: IconButton(
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                    ),
                  ),
                  if (_confirmController.text.isNotEmpty &&
                      !passwordsMatch) ...[
                    const Gap(8),
                    Text(
                      "Passwords don't match.",
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                    ),
                  ],
                  const Gap(18),
                  AppCard(
                    color: AppColors.teal.withValues(alpha: 0.05),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What you'll get:",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Gap(14),
                        for (final item in const [
                          'Access to live coding sessions',
                          'Library of recorded lessons',
                          'Its Pay As You Go',
                          'Community support and networking',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: AppColors.teal,
                                ),
                                const Gap(10),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Gap(18),
                  AppButton(
                    label: 'Create Account',
                    isLoading: _loading,
                    onPressed:
                        _emailController.text.isEmpty ||
                            _passwordController.text.isEmpty ||
                            _confirmController.text.isEmpty ||
                            !passwordsMatch
                        ? null
                        : _createAccount,
                  ),
                  const Gap(10),
                  Text(
                    "Next step happens inside the app now. You'll complete your profile before payment and enrollment are fully connected.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Gap(18),
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: const [
                        TextSpan(
                          text: 'By creating an account, you agree to our ',
                        ),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(26),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Already have an account?',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const Gap(10),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign In'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContinueRegistrationScreen extends ConsumerStatefulWidget {
  const ContinueRegistrationScreen({super.key});

  @override
  ConsumerState<ContinueRegistrationScreen> createState() =>
      _ContinueRegistrationScreenState();
}

class _ContinueRegistrationScreenState
    extends ConsumerState<ContinueRegistrationScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _weeksController = TextEditingController(text: '4');
  bool _submitting = false;
  String _selectedPath = 'Flutter & Mobile App Development';
  String _selectedAgeRange = '18-24';
  String _selectedGender = 'Prefer not to say';

  List<String> _paths = const [
    'Flutter & Mobile App Development',
    'Web Development & WordPress',
    'AI-Assisted Development',
  ];

  static const _ageRanges = ['13-17', '18-24', '25-34', '35+'];
  static const _genders = ['Male', 'Female', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      final paths = await ref.read(catalogRepositoryProvider).getPaths();
      if (!mounted || paths.isEmpty) return;
      setState(() {
        _paths = paths.map((path) => path.title).toList();
        if (!_paths.contains(_selectedPath)) {
          _selectedPath = _paths.first;
        }
      });
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _weeksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_fullNameController.text.trim().length < 2) {
      showAppSnackBar(context, 'Please enter your full name.');
      return;
    }
    if (_phoneController.text.trim().length < 6) {
      showAppSnackBar(context, 'Please enter a valid phone number.');
      return;
    }

    // Prevent the form from flashing an overflow while the keyboard collapses.
    await _settleKeyboardBeforeRouteChange(context);
    if (!mounted) return;
    setState(() => _submitting = true);
    try {
      final session = ref.read(authControllerProvider).session;
      if (session == null) {
        showAppSnackBar(context, 'Your session expired. Please sign in again.');
        return;
      }

      await ref
          .read(studentRepositoryProvider)
          .completeRegistrationProfile(
            uid: session.uid,
            email: session.email,
            fullName: _fullNameController.text,
            phone: _phoneController.text,
            ageRange: _selectedAgeRange,
            gender: _selectedGender,
            weeksToCommit: int.tryParse(_weeksController.text.trim()) ?? 4,
            pathTitle: _selectedPath,
          );
      await ref
          .read(authControllerProvider.notifier)
          .completeRegistration(EnrollmentStatus.pending);
      if (!mounted) return;
      context.go('/payment?mode=initial');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AppScreen(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _AuthBackdrop(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Gap(18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.assignment_ind_rounded,
                          size: 18,
                          color: AppColors.teal,
                        ),
                        const Gap(8),
                        Text(
                          'Step 2 of 2',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.deepBlue),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  Text(
                    'Complete Your Registration',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'The website uses a single-page continue-registration flow, so we now handle that inside the app instead of opening the dead /complete-registration URL.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.mutedForeground,
                      height: 1.55,
                    ),
                  ),
                  const Gap(24),
                  AppCard(
                    color: AppColors.teal.withValues(alpha: 0.05),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Gap(10),
                        Text(
                          authState.session?.email ?? 'No email found',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const Gap(22),
                  AppTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _fullNameController,
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const Gap(18),
                  AppTextField(
                    label: 'Phone Number',
                    hint: 'e.g. +234 800 000 0000',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const Gap(18),
                  _DropdownField<String>(
                    label: 'Learning Path',
                    value: _selectedPath,
                    items: _paths,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedPath = value);
                    },
                  ),
                  const Gap(18),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownField<String>(
                          label: 'Age Range',
                          value: _selectedAgeRange,
                          items: _ageRanges,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedAgeRange = value);
                          },
                        ),
                      ),
                      const Gap(14),
                      Expanded(
                        child: _DropdownField<String>(
                          label: 'Gender',
                          value: _selectedGender,
                          items: _genders,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedGender = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(18),
                  AppTextField(
                    label: 'Weeks To Commit',
                    hint: 'How many weeks do you want to unlock now?',
                    controller: _weeksController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.calendar_month_outlined,
                  ),
                  const Gap(18),
                  AppCard(
                    color: AppColors.deepBlue.withValues(alpha: 0.05),
                    border: Border.all(
                      color: AppColors.deepBlue.withValues(alpha: 0.12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What happens next',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Gap(12),
                        for (final item in const [
                          'We save your profile next in Firestore.',
                          'Your path will inherit the admin-managed active cohort.',
                          'Payment and unlocked classes will follow the same setup.',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: AppColors.teal,
                                ),
                                const Gap(10),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Gap(22),
                  AppButton(
                    label: 'Save And Continue',
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              if (!_sent) ...[
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                const Gap(26),
                Center(
                  child: Text(
                    'Forgot Password?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Gap(10),
                Text(
                  "Enter your email and we'll send you a reset link.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.mutedForeground,
                    height: 1.6,
                  ),
                ),
                const Gap(28),
                AppTextField(
                  label: 'Email Address',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const Gap(20),
                AppButton(
                  label: 'Send Reset Link',
                  isLoading: _loading,
                  onPressed: _emailController.text.isEmpty ? null : _sendReset,
                ),
                const Gap(8),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Back to Login'),
                  ),
                ),
              ] else ...[
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.success, Color(0xFF16A34A)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
                const Gap(26),
                Center(
                  child: Text(
                    'Check Your Email',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Gap(10),
                Text(
                  "We've sent a password reset link to\n${_emailController.text}",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.mutedForeground,
                    height: 1.6,
                  ),
                ),
                const Gap(28),
                AppButton(
                  label: 'Back to Login',
                  onPressed: () => context.go('/login'),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class EnrollmentGateScreen extends ConsumerWidget {
  const EnrollmentGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final status = authState.enrollmentStatus;

    return AppScreen(
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: switch (status) {
              EnrollmentStatus.enrolled => _EnrollmentStatusCard(
                icon: Icons.verified_rounded,
                gradient: const LinearGradient(
                  colors: [AppColors.success, Color(0xFF16A34A)],
                ),
                title: "You're All Set!",
                body: "Your enrollment is confirmed. Let's start learning.",
                primaryLabel: 'Go to Dashboard',
                onPrimary: () => context.go('/dashboard'),
              ),
              EnrollmentStatus.pending => _EnrollmentStatusCard(
                icon: Icons.schedule_rounded,
                gradient: const LinearGradient(
                  colors: [AppColors.orange, AppColors.orangeLight],
                ),
                title: 'Payment Pending',
                body:
                    'Complete your payment here in the app to unlock your classes and dashboard.',
                note:
                    'If you already started checkout, we will keep the same payment reference and let you continue from where you stopped.',
                primaryLabel: 'Complete Payment',
                onPrimary: () => context.go('/payment?mode=initial'),
                secondaryLabel: 'Review Registration',
                onSecondary: () => context.go('/continue-registration'),
              ),
              EnrollmentStatus.notRegistered => _EnrollmentStatusCard(
                icon: Icons.info_rounded,
                gradient: const LinearGradient(
                  colors: [AppColors.deepBlue, AppColors.deepBlueLight],
                ),
                title: 'Registration Required',
                body:
                    'Complete your registration details inside the app before payment and dashboard access.',
                note:
                    'What you get: live classes, recorded lessons, AI tutor support, community access, and industry certificates.',
                primaryLabel: 'Continue Registration',
                onPrimary: () => context.go('/continue-registration'),
                secondaryLabel: 'Back',
                onSecondary: () =>
                    ref.read(authControllerProvider.notifier).logout(),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Gap(10),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(),
          borderRadius: BorderRadius.circular(20),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.18)),
        boxShadow: AppShadows.card,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.foreground),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
    this.top,
    this.right,
    this.bottom,
    this.left,
    this.opacity = 0.3,
  });

  final Color color;
  final double size;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child:
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: opacity),
                      blurRadius: 90,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 4200.ms,
                begin: const Offset(0.92, 0.92),
                end: const Offset(1.08, 1.08),
              ),
    );
  }
}

Future<void> _settleKeyboardBeforeRouteChange(BuildContext context) async {
  FocusScope.of(context).unfocus();
  await Future<void>.delayed(const Duration(milliseconds: 140));
}

class _AuthBackdrop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AppAtmosphereBackdrop();
  }
}

class _EnrollmentStatusCard extends StatelessWidget {
  const _EnrollmentStatusCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.note,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final Gradient gradient;
  final String title;
  final String body;
  final String? note;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 102,
          height: 102,
          decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 52),
        ),
        const Gap(28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Gap(10),
        Text(
          body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.mutedForeground,
            height: 1.6,
          ),
        ),
        if (note != null) ...[
          const Gap(20),
          AppCard(
            color: AppColors.muted,
            border: Border.all(color: AppColors.border),
            child: Text(
              note!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.deepBlue,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const Gap(22),
        AppButton(label: primaryLabel, onPressed: onPrimary),
        if (secondaryLabel != null && onSecondary != null) ...[
          const Gap(10),
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
        ],
      ],
    );
  }
}
