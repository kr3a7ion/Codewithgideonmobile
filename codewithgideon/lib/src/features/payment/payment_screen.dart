import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/payment_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/course_ring.dart';
import '../../core/widgets/sign_up_progress.dart';
import '../../core/widgets/states/app_state_widgets.dart';
import '../entry/state/auth_provider.dart';
import '../home/state/dashboard_provider.dart';
import '../student/models/student_profile_model.dart';
import 'models/payment_checkout_model.dart';
import 'state/payment_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.kind, this.returnTo});

  final PaymentFlowKind kind;
  final String? returnTo;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late Future<PaymentCheckoutModel> _checkoutFuture;
  late final TextEditingController _weeksController;
  bool _hasSeededWeeks = false;
  bool _processing = false;

  /// Second step: the summary and the Pay button.
  bool _reviewing = false;
  bool _paymentCompleted = false;

  /// Paystack has charged the card and the app is confirming it with the
  /// server. Shown as its own step so the student doesn't pay again.
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _weeksController = TextEditingController();
    final session = ref.read(authControllerProvider).session;
    _checkoutFuture = ref
        .read(paymentRepositoryProvider)
        .loadCheckout(uid: session!.uid, kind: widget.kind);
  }

  @override
  void dispose() {
    _weeksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 96;

    return AppScreen(
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: FutureBuilder<PaymentCheckoutModel>(
              future: _checkoutFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return AppLoadingState(
                    title: widget.kind == PaymentFlowKind.topUp
                        ? 'Preparing your top-up'
                        : 'Preparing your payment',
                    message:
                        'We are syncing your course plan, week limit, and secure checkout details.',
                    compact: true,
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return _PaymentErrorState(
                    message:
                        'We could not prepare your payment right now. Please try again.',
                    onBack: _handleExit,
                    onRetry: () {
                      setState(() {
                        final session = ref
                            .read(authControllerProvider)
                            .session;
                        _checkoutFuture = ref
                            .read(paymentRepositoryProvider)
                            .loadCheckout(uid: session!.uid, kind: widget.kind);
                      });
                    },
                  );
                }

                final checkout = snapshot.data!;
                if (!_hasSeededWeeks) {
                  _weeksController.text = '${checkout.suggestedWeeks}';
                  _hasSeededWeeks = true;
                }

                final requestedWeeks = _parseWeeks(checkout);
                final pricing = ref
                    .read(paymentRepositoryProvider)
                    .quote(checkout: checkout, weeks: requestedWeeks);
                final isWeeksValid =
                    checkout.maxAllowedWeeks > 0 &&
                    requestedWeeks >= 1 &&
                    requestedWeeks <= checkout.maxAllowedWeeks;

                return RefreshIndicator(
                  color: AppColors.deepBlue,
                  onRefresh: () async {
                    setState(() {
                      final session = ref.read(authControllerProvider).session;
                      _hasSeededWeeks = false;
                      _checkoutFuture = ref
                          .read(paymentRepositoryProvider)
                          .loadCheckout(uid: session!.uid, kind: widget.kind);
                    });
                    await _checkoutFuture;
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(22, 30, 22, bottomPadding),
                    children: _reviewing
                        ? _reviewStep(checkout, pricing, isWeeksValid)
                        : _weeksStep(checkout, pricing, requestedWeeks),
                  ),
                );
              },
            ),
          ),
          if (_processing)
            Positioned.fill(
              child: _PaymentProcessingOverlay(confirming: _confirming),
            ),
        ],
      ),
    );
  }


  /// Header shared by both steps: back button, and the sign-up progress for
  /// a first payment ("2 of 3", "3 of 3").
  Widget _stepHeader(PaymentCheckoutModel checkout, String title, int step) {
    final theme = Theme.of(context);
    final showProgress = checkout.kind == PaymentFlowKind.initial;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Back',
              child: InkWell(
                onTap: _processing ? null : _handleExit,
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.cardColor,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            if (showProgress) ...[
              const Gap(12),
              Expanded(child: SignUpProgress(step: step)),
            ],
          ],
        ),
        const Gap(18),
        Text(title, style: theme.textTheme.displaySmall),
      ],
    );
  }

  List<Widget> _weeksStep(
    PaymentCheckoutModel checkout,
    PaymentPriceBreakdown pricing,
    int requestedWeeks,
  ) {
    final theme = Theme.of(context);
    final max = checkout.maxAllowedWeeks;
    final weeks = max <= 0 ? 0 : requestedWeeks.clamp(1, max);
    final isTopUp = checkout.kind == PaymentFlowKind.topUp;
    final cohort = checkout.profile.cohortLabel?.trim() ?? '';
    final already = isTopUp ? checkout.committedWeeks : 0;
    final total = checkout.totalProgramWeeks < 1
        ? 1
        : checkout.totalProgramWeeks;
    final ring = List<CourseWeekState>.generate(total, (i) {
      if (i < already) return CourseWeekState.done;
      if (i < already + weeks) return CourseWeekState.unlocked;
      return CourseWeekState.locked;
    });
    final quick = <int>{
      if (max >= 4) 4,
      if (max >= 8) 8,
      if (max > 0) max,
    }.toList()..sort();

    return [
      _stepHeader(checkout, isTopUp ? 'Add weeks' : 'How many weeks?', 2),
      const Gap(18),
      AppCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        shadow: AppShadows.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              checkout.course.title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.teal,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const Gap(6),
            Text(
              '$total weeks · live classes, every class recorded',
              style: theme.textTheme.bodySmall?.copyWith(color: _muted(context)),
            ),
            if (cohort.isNotEmpty) ...[
              const Gap(6),
              Text(
                cohort,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
      if (checkout.hasMatchingPendingPayment) ...[
        const Gap(14),
        _PendingPaymentCard(checkout: checkout),
      ],
      const Gap(22),
      Center(
        child: SizedBox.square(
          dimension: 190,
          child: CustomPaint(
            painter: CourseRingPainter(
              states: ring,
              lockedColor: theme.brightness == Brightness.dark
                  ? AppColors.darkMuted
                  : const Color(0xFFC9D3E1),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$weeks',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 60,
                      height: 1,
                    ),
                  ),
                  Text(
                    weeks == 1 ? 'week' : 'weeks',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _muted(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const Gap(18),
      Row(
        children: [
          _RoundStep(
            icon: Icons.remove_rounded,
            label: 'One week fewer',
            filled: false,
            onTap: weeks > 1 ? () => _adjustWeeks(checkout, delta: -1) : null,
          ),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final option in quick)
                  ChoiceChip(
                    label: Text(
                      option == max && option > 8 ? 'All $option' : '$option',
                    ),
                    selected: option == weeks,
                    showCheckmark: false,
                    selectedColor: AppColors.teal.withValues(alpha: 0.14),
                    shape: const StadiumBorder(),
                    onSelected: (_) => _adjustWeeks(
                      checkout,
                      delta: option - weeks,
                    ),
                  ),
              ],
            ),
          ),
          _RoundStep(
            icon: Icons.add_rounded,
            label: 'One more week',
            filled: true,
            onTap: weeks < max ? () => _adjustWeeks(checkout, delta: 1) : null,
          ),
        ],
      ),
      const Gap(14),
      Text(
        max <= 0
            ? 'All course weeks are already unlocked.'
            : '${_formatNaira(pricing.weeklyRate)} a week. Add more weeks any time; every class is recorded.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(color: _muted(context)),
      ),
      const Gap(28),
      Row(
        children: [
          Expanded(
            child: Text(
              '$weeks ${weeks == 1 ? 'week' : 'weeks'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _muted(context),
              ),
            ),
          ),
          Text(
            _formatNaira(pricing.totalPrice),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      const Gap(12),
      AppButton(
        label: 'Continue',
        trailing: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
        onPressed: max <= 0 ? null : () => setState(() => _reviewing = true),
      ),
    ];
  }

  List<Widget> _reviewStep(
    PaymentCheckoutModel checkout,
    PaymentPriceBreakdown pricing,
    bool isWeeksValid,
  ) {
    final theme = Theme.of(context);
    final isTopUp = checkout.kind == PaymentFlowKind.topUp;
    final weeksLabel = isTopUp
        ? '${pricing.weeks} more (${checkout.committedWeeks + pricing.weeks} of ${checkout.totalProgramWeeks})'
        : '${pricing.weeks} of ${checkout.totalProgramWeeks}';
    return [
      _stepHeader(checkout, 'Review and pay', 3),
      const Gap(18),
      AppCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        shadow: AppShadows.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              checkout.course.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Gap(10),
            _SummaryRow(label: 'Weeks', value: weeksLabel),
            _SummaryRow(
              label: 'Price a week',
              value: _formatNaira(pricing.weeklyRate),
            ),
            const Divider(height: 24),
            _SummaryRow(
              label: 'Total today',
              value: _formatNaira(pricing.totalPrice),
              emphasize: true,
            ),
          ],
        ),
      ),
      const Gap(14),
      AppCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (final (icon, text) in const [
              (Icons.event_available_outlined, 'Live classes and reminders'),
              (Icons.chat_bubble_outline_rounded, 'Mentor chat with Gideon'),
              (Icons.groups_outlined, 'Your cohort group'),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.teal),
                    const Gap(12),
                    Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
      const Gap(28),
      AppButton(
        label: 'Pay ${_formatNaira(pricing.totalPrice)}',
        trailing: const Icon(Icons.lock_outline_rounded, color: Colors.white),
        isLoading: _processing,
        onPressed: !isWeeksValid || _processing
            ? null
            : () => _startPayment(checkout, pricing),
      ),
      const Gap(10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: _muted(context)),
          const Gap(6),
          Flexible(
            child: Text(
              'Secured by Paystack · card, transfer or USSD',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _muted(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  int _parseWeeks(PaymentCheckoutModel checkout) {
    final parsed = int.tryParse(_weeksController.text.trim());
    if (parsed == null) return checkout.suggestedWeeks;
    return parsed;
  }

  void _adjustWeeks(PaymentCheckoutModel checkout, {required int delta}) {
    final current = _parseWeeks(checkout);
    final upper = checkout.maxAllowedWeeks <= 0 ? 0 : checkout.maxAllowedWeeks;
    final next = upper == 0 ? 0 : (current + delta).clamp(1, upper);
    _weeksController.value = TextEditingValue(
      text: '$next',
      selection: TextSelection.collapsed(offset: '$next'.length),
    );
    setState(() {});
  }

  void _handleExit() {
    if (_reviewing) {
      setState(() => _reviewing = false);
      return;
    }
    final fallback = widget.kind == PaymentFlowKind.topUp
        ? '/dashboard'
        : '/continue-registration';
    final target = widget.returnTo ?? fallback;

    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }

    context.go(target);
  }

  Future<void> _startPayment(
    PaymentCheckoutModel checkout,
    PaymentPriceBreakdown pricing,
  ) async {
    if (_processing) return;
    final session = ref.read(authControllerProvider).session;
    if (session == null) {
      showAppSnackBar(context, 'Your session expired. Please sign in again.');
      return;
    }
    if (PaymentConfig.initializeUrl.isEmpty ||
        PaymentConfig.verifyUrl.isEmpty ||
        PaymentConfig.callbackUrl.isEmpty) {
      showAppSnackBar(
        context,
        'Payment is not configured yet. Add the Paystack URLs before trying again.',
      );
      return;
    }

    final paymentRepository = ref.read(paymentRepositoryProvider);
    final reference = paymentRepository.generateReference();

    final metadata = <String, Object?>{
      'uid': checkout.profile.uid,
      'kind': checkout.kind.apiValue,
      'weeks': pricing.weeks,
      'path': checkout.profile.pathTitle,
      'pathId': checkout.profile.pathId,
      'courseId': checkout.profile.courseId,
      'cohortId': checkout.profile.cohortId,
      'cohortLabel': checkout.profile.cohortLabel,
      'cohortKey': checkout.profile.cohortKey,
      'expectedAmountKobo': pricing.totalPriceKobo,
      'baseAmountKobo': pricing.basePriceKobo,
      'totalFeeKobo': pricing.totalFeeKobo,
      'yourFeeShareKobo': pricing.yourFeeShareKobo,
      'studentFeeShareKobo': pricing.studentFeeShareKobo,
      'baseAmount': pricing.basePrice,
      'weeklyRate': pricing.weeklyRate,
      'yourRevenue': pricing.yourRevenue,
      'app': 'codewithgideon-mobile',
      'ts': DateTime.now().millisecondsSinceEpoch,
    };

    setState(() => _processing = true);
    _paymentCompleted = false;
    try {
      final initialized = await paymentRepository.initializePayment(
        email: session.email,
        amountKobo: pricing.totalPriceKobo,
        reference: reference,
        metadata: metadata,
      );

      if (!mounted) return;

      try {
        await paymentRepository.setPendingPayment(
          uid: checkout.profile.uid,
          kind: checkout.kind,
          weeks: pricing.weeks,
          amount: pricing.totalPrice,
          reference: initialized.reference,
        );
        ref.invalidate(dashboardSnapshotProvider);
      } catch (_) {
        if (!mounted) return;
        showAppSnackBar(
          context,
          'Checkout is ready. Complete it now so your access can update immediately.',
        );
      }

      if (!mounted) return;
      await FlutterPaystackPlus.openPaystackPopup(
        customerEmail: session.email,
        amount: '${pricing.totalPriceKobo}',
        reference: initialized.reference,
        authorizationUrl: initialized.authorizationUrl,
        callBackUrl: PaymentConfig.callbackUrl,
        context: context,
        metadata: metadata,
        onClosed: () {
          if (!mounted) return;
          if (_paymentCompleted) return;
          setState(() => _processing = false);
          _handleExit();
        },
        onSuccess: () async {
          // Paystack has charged the card at this point. Whatever verify
          // says, don't leave the student on a screen that lets them pay
          // again: the webhook credits the payment even if verify fails.
          _paymentCompleted = true;
          if (mounted) setState(() => _confirming = true);
          final confirmedMessage = checkout.kind == PaymentFlowKind.topUp
              ? 'Top up confirmed. Your extra weeks are now available.'
              : 'Payment confirmed. Welcome to your dashboard.';
          String message;
          try {
            final result = await paymentRepository.verifyPayment(
              checkout: checkout,
              pricing: pricing,
              reference: initialized.reference,
            );
            if (result.needsReview) {
              message = "${result.message} Please don't pay again.";
            } else {
              message = confirmedMessage;
            }
          } catch (_) {
            // Paystack's webhook usually credits the weeks within seconds
            // even when this quick check fails, so wait for that first.
            final credited = await _waitForCredit(checkout);
            message = credited
                ? confirmedMessage
                : "Payment received. We're still confirming it, so please "
                      "don't pay again. Your weeks will appear shortly. If "
                      "they don't, contact support with reference "
                      '${initialized.reference}.';
          }
          try {
            if (!mounted) return;
            ref.invalidate(dashboardSnapshotProvider);
            await ref.read(authControllerProvider.notifier).refreshSession();
          } catch (_) {
            // The dashboard reloads on its own; a failed refresh isn't fatal.
          }
          try {
            if (!mounted) return;
            showAppSnackBar(context, message);
            context.go('/dashboard');
          } finally {
            if (mounted) {
              setState(() {
                _processing = false;
                _confirming = false;
              });
            }
          }
        },
      );
      if (mounted && !_paymentCompleted) {
        setState(() => _processing = false);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _processing = false);
      showAppSnackBar(context, _prettyPaymentError(error));
    }
  }
}

/// Checks the student's record for up to 30 seconds to see whether the
/// payment has been credited (by the webhook) after verify couldn't confirm.
extension on _PaymentScreenState {
  Future<bool> _waitForCredit(PaymentCheckoutModel checkout) async {
    final weeksBefore = checkout.profile.weeksToCommit;
    final wasPaid = checkout.profile.status == StudentEnrollmentState.complete;
    for (var attempt = 0; attempt < 6; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      try {
        final snapshot = await ref.refresh(dashboardSnapshotProvider.future);
        final profile = snapshot.profile;
        final paidNow = profile.status == StudentEnrollmentState.complete;
        if (!wasPaid && paidNow) return true;
        if (wasPaid && profile.weeksToCommit > weeksBefore) return true;
      } catch (_) {
        // Offline for a moment: try again on the next round.
      }
    }
    return false;
  }
}

class _PendingPaymentCard extends StatelessWidget {
  const _PendingPaymentCard({required this.checkout});

  final PaymentCheckoutModel checkout;

  @override
  Widget build(BuildContext context) {
    final pending = checkout.matchingPendingPayment!;
    return AppCard(
      color: AppColors.orange.withValues(alpha: 0.08),
      border: Border.all(color: AppColors.orange.withValues(alpha: 0.14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.orange),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkout.kind == PaymentFlowKind.topUp
                      ? 'Top-up checkout in progress'
                      : 'Checkout in progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(6),
                Text(
                  'We saved ${pending.weeks} week(s) for this checkout. Continue below and we will open a fresh secure Paystack window.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentProcessingOverlay extends StatefulWidget {
  const _PaymentProcessingOverlay({this.confirming = false});

  /// The card has been charged; show "Confirming your payment" and stop
  /// cycling through the checkout messages.
  final bool confirming;

  @override
  State<_PaymentProcessingOverlay> createState() =>
      _PaymentProcessingOverlayState();
}

class _PaymentProcessingOverlayState extends State<_PaymentProcessingOverlay> {
  int _stage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) return;
      setState(() {
        _stage = (_stage + 1) % _paymentStages.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.confirming
        ? _confirmingStage
        : _paymentStages[_stage];
    return IgnorePointer(
      child: Container(
        color: AppColors.deepBlueDark.withValues(alpha: 0.36),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppCard(
              radius: 30,
              shadow: AppShadows.premium,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PremiumLoader(size: 66, dotSize: 10),
                    const Gap(20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: Text(
                        stage.title,
                        key: ValueKey(stage.title),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Gap(8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: Text(
                        stage.message,
                        key: ValueKey(stage.message),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedForeground,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = emphasize
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: style?.copyWith(
                color: emphasize
                    ? (isDark
                          ? AppColors.darkForeground
                          : AppColors.deepBlueDark)
                    : _muted(context),
              ),
            ),
          ),
          const Gap(12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: style?.copyWith(
                color: isDark ? AppColors.darkForeground : AppColors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentErrorState extends StatelessWidget {
  const _PaymentErrorState({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumPageHeader(
            leading: PremiumIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
            title: 'Payment unavailable',
            subtitle: message,
          ),
          const Spacer(),
          AppButton(label: 'Try Again', onPressed: onRetry),
        ],
      ),
    );
  }
}

String _formatNaira(int amount) {
  final format = NumberFormat.currency(
    locale: 'en_NG',
    symbol: 'N',
    decimalDigits: 0,
  );
  return format.format(amount);
}

String _prettyPaymentError(Object error) {
  final raw = '$error'.replaceFirst('Bad state: ', '').trim();
  if (raw.contains('<html') ||
      raw.contains('Unexpected character') ||
      raw.contains('FormatException') ||
      raw.contains('valid payment data') ||
      raw.contains('Paystack secret') ||
      raw.contains('invalid initialization response') ||
      raw.contains('checkout URL was missing')) {
    return 'The payment service returned an unexpected response. Please try again. If it continues, contact support.';
  }
  if (raw.contains('XMLHttpRequest error') ||
      raw.contains('ClientException') ||
      raw.contains('SocketException')) {
    return 'We could not reach the payment service. Check your connection and try again.';
  }
  if (raw.contains('Could not initialize payment') ||
      raw.contains('We could not confirm your payment') ||
      raw.contains('Payment could not be started')) {
    return raw;
  }
  return 'Payment could not be started. Please try again.';
}

Color _muted(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkMutedForeground
      : AppColors.mutedForeground;
}

class _PaymentStageCopy {
  const _PaymentStageCopy(this.title, this.message);

  final String title;
  final String message;
}

const _confirmingStage = _PaymentStageCopy(
  'Confirming your payment',
  "Paystack has your payment. We're checking it now. Please keep this "
      "screen open and don't pay again.",
);

const _paymentStages = [
  _PaymentStageCopy(
    'Securing checkout',
    'We are preparing your protected payment session.',
  ),
  _PaymentStageCopy(
    'Connecting to Paystack',
    'Your payment window is being opened safely.',
  ),
  _PaymentStageCopy(
    'Keeping your access in sync',
    'We will update your dashboard and admin records right after payment confirmation.',
  ),
];

class _RoundStep extends StatelessWidget {
  const _RoundStep({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: CircleAvatar(
            radius: 26,
            backgroundColor: filled
                ? AppColors.teal
                : Theme.of(context).cardColor,
            child: Icon(
              icon,
              color: filled
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
