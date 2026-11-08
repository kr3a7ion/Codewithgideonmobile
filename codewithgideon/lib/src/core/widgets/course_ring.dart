import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum CourseWeekState { done, current, unlocked, locked }

/// One arc per course week, coloured by [CourseWeekState].
class CourseRingPainter extends CustomPainter {
  CourseRingPainter({required this.states, required this.lockedColor});

  final List<CourseWeekState> states;
  final Color lockedColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final count = states.length;
    // Gap between segments, in radians; none when the course is one week.
    final gap = count > 1 ? 0.07 : 0.0;
    final sweep = 2 * math.pi / count;
    for (var i = 0; i < count; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = switch (states[i]) {
          CourseWeekState.done => AppColors.teal,
          CourseWeekState.current => AppColors.orange,
          CourseWeekState.unlocked => AppColors.tealLight.withValues(
            alpha: 0.6,
          ),
          CourseWeekState.locked => lockedColor,
        };
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * sweep + gap / 2,
        sweep - gap,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CourseRingPainter old) =>
      old.lockedColor != lockedColor || !_sameStates(old.states, states);

  static bool _sameStates(List<CourseWeekState> a, List<CourseWeekState> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
