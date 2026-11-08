import 'package:codewithgideon/src/features/profile/badge_medal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every badge medal paints in every state', (tester) async {
    const tiers = [
      'Starter',
      'Ignited',
      'Charged',
      'Milestone',
      'Crusher',
      'Midpoint',
      'Focused',
      'Elevated',
      'Diamond',
      'Launch',
      'Legend',
      'Champion',
      'Unknown',
    ];
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(
                children: [
                  for (final tier in tiers)
                    for (final state in MedalState.values)
                      BadgeMedal(
                        tier: tier,
                        color: const Color(0xFFFB923C),
                        state: state,
                        size: 48,
                      ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(BadgeMedal), findsNWidgets(tiers.length * 4));
    }
  });
}
