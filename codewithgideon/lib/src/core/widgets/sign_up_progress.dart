import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Three bars and "2 of 3": details, weeks, review and pay.
class SignUpProgress extends StatelessWidget {
  const SignUpProgress({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Step $step of 3',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 1; i <= 3; i++)
            Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: i <= step
                      ? AppColors.teal
                      : (isDark ? AppColors.darkMuted : const Color(0xFFC9D3E1)),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          const SizedBox(width: 4),
          Text(
            '$step of 3',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
