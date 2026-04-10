import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../theme/app_theme.dart';
import '../app_controls.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.title = 'Loading your workspace...',
    this.message = 'We are preparing the latest learning data for you.',
    this.compact = false,
  });

  final String title;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PremiumLoader(),
        const Gap(16),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const Gap(8),
        Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (compact) return Center(child: content);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: AppCard(
          color: Theme.of(
            context,
          ).cardColor.withValues(alpha: isDark ? 0.96 : 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: content,
          ),
        ),
      ),
    );
  }
}

class PremiumLoader extends StatefulWidget {
  const PremiumLoader({
    super.key,
    this.size = 56,
    this.dotSize = 8,
    this.primaryColor,
    this.trackColor,
  });

  final double size;
  final double dotSize;
  final Color? primaryColor;
  final Color? trackColor;

  @override
  State<PremiumLoader> createState() => _PremiumLoaderState();
}

class _PremiumLoaderState extends State<PremiumLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        widget.primaryColor ??
        (isDark ? AppColors.darkForeground : AppColors.deepBlue);
    final trackColor = widget.trackColor ?? primaryColor.withValues(alpha: 0.1);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: _controller.value * 6.28318,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: trackColor, width: 1.2),
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: widget.dotSize,
                      height: widget.dotSize,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: widget.size * 0.32,
                height: widget.size * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AppShimmerBlock extends StatefulWidget {
  const AppShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.radius = 16,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<AppShimmerBlock> createState() => _AppShimmerBlockState();
}

class _AppShimmerBlockState extends State<AppShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkMuted : AppColors.muted;
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.65);

    // The shimmer is intentionally soft so it reads like premium preloading,
    // not a loud placeholder flashing over the real content shell.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.2 + (_controller.value * 2.4), -0.2),
              end: Alignment(0.2 + (_controller.value * 2.4), 0.2),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.1, 0.45, 0.9],
            ),
          ),
        );
      },
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Semantics(
        label: title,
        child: Column(
          children: [
            Icon(icon, size: 44, color: AppColors.mutedForeground),
            const Gap(12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const Gap(16), action!],
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.wifi_tethering_error_rounded,
            color: AppColors.orange,
          ),
        ),
        const Gap(16),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const Gap(8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedForeground,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const Gap(16),
          AppButton(label: 'Try Again', expanded: !compact, onPressed: onRetry),
        ],
      ],
    );

    if (compact) return Center(child: child);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: AppCard(child: child)),
    );
  }
}

class AppOfflineBanner extends StatelessWidget {
  const AppOfflineBanner({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, -1.2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: visible ? 1 : 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Semantics(
              liveRegion: true,
              label: 'Offline notice',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.deepBlueDark,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        'You are offline. Showing the most recently available data.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          height: 1.4,
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
