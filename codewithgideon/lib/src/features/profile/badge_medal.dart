import 'dart:math' as math;

import 'package:flutter/material.dart';

// Badge medals, drawn the same way as the website's (BadgeMedal.tsx): a
// shaped emblem in the badge colour, a white icon with a dark outline, a
// rim, a gloss, and ribbons on the milestone weeks. Shapes get rarer through
// the course.

enum MedalState { earned, latest, next, locked }

enum _Shape { coin, hex, shield, seal, gem, burst, laurel }

class _Art {
  const _Art(this.icon, this.shape, {this.ribbon = false});

  final IconData icon;
  final _Shape shape;
  final bool ribbon;
}

/// Artwork per badge tier (unique per badge), same as the website.
const _art = <String, _Art>{
  'Starter': _Art(Icons.eco_rounded, _Shape.coin),
  'Ignited': _Art(Icons.local_fire_department_rounded, _Shape.coin),
  'Charged': _Art(Icons.bolt_rounded, _Shape.hex),
  'Milestone': _Art(Icons.event_available_rounded, _Shape.shield, ribbon: true),
  'Crusher': _Art(Icons.fitness_center_rounded, _Shape.hex),
  'Midpoint': _Art(Icons.waves_rounded, _Shape.seal, ribbon: true),
  'Focused': _Art(Icons.gps_fixed_rounded, _Shape.coin),
  'Elevated': _Art(Icons.flutter_dash_rounded, _Shape.seal),
  'Diamond': _Art(Icons.diamond_rounded, _Shape.gem),
  'Launch': _Art(Icons.rocket_launch_rounded, _Shape.shield),
  'Legend': _Art(Icons.star_rounded, _Shape.burst),
  'Champion': _Art(Icons.emoji_events_rounded, _Shape.laurel, ribbon: true),
};

const _ink = Color(0xFF08152E);

/// One weekly badge medal. Earned and latest are in colour (latest glows),
/// next is grey with a dashed ring in the badge colour, locked is grey with
/// a lock.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({
    super.key,
    required this.tier,
    required this.color,
    this.state = MedalState.earned,
    this.size = 96,
  });

  final String tier;
  final Color color;
  final MedalState state;

  /// Width; the height is 10% more to fit the ribbons.
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(size, size * 132 / 120),
        painter: _MedalPainter(
          art: _art[tier] ?? _art['Starter']!,
          color: color,
          state: state,
          dark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter({
    required this.art,
    required this.color,
    required this.state,
    required this.dark,
  });

  final _Art art;
  final Color color;
  final MedalState state;
  final bool dark;

  // Drawn in a 120 x 132 box, medal centred at (60, 56).
  static const cx = 60.0;
  static const cy = 56.0;
  static const r = 50.0;
  static const centre = Offset(cx, cy);

  bool get lit => state == MedalState.earned || state == MedalState.latest;

  Color _mix(Color to, double amount) => Color.lerp(color, to, amount)!;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120);

    final light = _mix(Colors.white, 0.45);
    final darkTone = _mix(_ink, 0.32);
    final deep = _mix(_ink, 0.58);
    final (outer, inner, iconScale) = _shapePaths(art.shape);
    final bounds = outer.getBounds();

    // Latest: a soft glow behind the medal.
    if (state == MedalState.latest) {
      canvas.drawCircle(
        centre,
        r * 0.95,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // Ribbons on milestone weeks.
    if (art.ribbon) {
      final ribbon = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: lit
              ? [darkTone, deep]
              : const [Color(0xFF94A3B8), Color(0xFF64748B)],
        ).createShader(const Rect.fromLTWH(0, cy, 120, 76));
      canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: lit ? 1 : 0.55));
      for (final s in const [-1.0, 1.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(cx + s * 21, cy + r * 0.6)
            ..lineTo(cx + s * 3, cy + r * 0.78)
            ..lineTo(cx + s * 11, cy + r + 25)
            ..lineTo(cx + s * 19, cy + r + 17)
            ..lineTo(cx + s * 29, cy + r + 23)
            ..close(),
          ribbon,
        );
      }
      canvas.restore();
    }

    final rimColors = lit
        ? [light, color, deep]
        : dark
        ? const [Color(0xFF3A4A63), Color(0xFF1E293B)]
        : const [Color(0xFFDBE3EE), Color(0xFFA9B6C8)];
    final rim = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: rimColors,
        stops: lit ? const [0, 0.55, 1] : null,
      ).createShader(bounds.inflate(10));

    // Laurel leaves around the Champion medal.
    if (art.shape == _Shape.laurel) {
      final rr = r * 0.92;
      for (var side = 0; side < 2; side++) {
        for (var k = 0; k < 7; k++) {
          final deg = side == 0 ? 118.0 + k * 20 : 62.0 - k * 20;
          final a = deg * math.pi / 180;
          final p = Offset(cx + math.cos(a) * rr, cy + math.sin(a) * rr);
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate((deg + (side == 0 ? -30 : 30)) * math.pi / 180);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: 8.4, height: 17.2),
            rim,
          );
          canvas.restore();
        }
      }
    }

    // Next: a dashed ring in the badge colour.
    if (state == MedalState.next) {
      final dash = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      const count = 26;
      for (var i = 0; i < count; i++) {
        final start = i * 2 * math.pi / count;
        canvas.drawArc(
          Rect.fromCircle(center: centre, radius: r + 5),
          start,
          0.08,
          false,
          dash,
        );
      }
    }

    // Rim, with a soft drop shadow.
    canvas.drawPath(
      outer.shift(const Offset(0, 3)),
      Paint()
        ..color = (lit ? deep : const Color(0xFF0F2B5B)).withValues(
          alpha: lit ? 0.4 : 0.14,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
    );
    canvas.drawPath(outer, rim);
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = (lit ? deep : const Color(0xFF0F2B5B)).withValues(
          alpha: lit ? 0.35 : 0.08,
        ),
    );

    // Dotted ring on round medals.
    if (art.shape == _Shape.coin ||
        art.shape == _Shape.laurel ||
        art.shape == _Shape.seal) {
      final dotR =
          r *
          switch (art.shape) {
            _Shape.laurel => 0.69,
            _Shape.seal => 0.79,
            _ => 0.89,
          };
      final dot = Paint()
        ..color = Colors.white.withValues(
          alpha: lit ? 0.5 : (dark ? 0.16 : 0.6),
        );
      for (final p in _ring(16, dotR)) {
        canvas.drawCircle(p, 1.25, dot);
      }
    }

    // Face.
    final faceColors = lit
        ? [color, darkTone]
        : dark
        ? const [Color(0xFF26344A), Color(0xFF152033)]
        : const [Color(0xFFF4F7FB), Color(0xFFDBE3EE)];
    final innerBounds = inner.getBounds();
    canvas.drawPath(
      inner,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.24, -0.4),
          radius: 0.85,
          colors: faceColors,
        ).createShader(innerBounds),
    );
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(
          alpha: lit ? 0.4 : (dark ? 0.12 : 0.7),
        ),
    );

    // Gloss across the top of the face.
    canvas.save();
    canvas.clipPath(inner);
    canvas.translate(cx - 10, cy - 26);
    canvas.rotate(-16 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 1.24, height: r * 0.6),
      Paint()
        ..color = Colors.white.withValues(
          alpha: lit ? 0.16 : (dark ? 0.05 : 0.35),
        ),
    );
    canvas.restore();

    // Icon: a dark outline under white reads on every colour.
    final iconSize = r * iconScale;
    if (lit) {
      _icon(
        canvas,
        art.icon,
        iconSize,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..color = deep.withValues(alpha: 0.55),
      );
      _icon(canvas, art.icon, iconSize, Paint()..color = Colors.white);
    } else {
      final ink = state == MedalState.next
          ? (dark ? color : darkTone).withValues(alpha: 0.8)
          : (dark ? const Color(0xFF5B6B85) : const Color(0xFF94A3B8));
      _icon(canvas, art.icon, iconSize, Paint()..color = ink);
    }

    // Lock.
    if (state == MedalState.locked) {
      final at = Offset(cx + r * 0.7, cy + r * 0.7);
      canvas.drawCircle(
        at,
        12.5,
        Paint()..color = dark ? const Color(0xFF1E293B) : Colors.white,
      );
      canvas.drawCircle(
        at,
        12.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = dark ? const Color(0xFF475569) : const Color(0xFFC2CDDC),
      );
      _icon(
        canvas,
        Icons.lock_rounded,
        14,
        Paint()
          ..color = dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
        at: at,
      );
    }

    canvas.restore();
  }

  void _icon(
    Canvas canvas,
    IconData icon,
    double size,
    Paint paint, {
    Offset at = centre,
  }) {
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          height: 1,
          foreground: paint,
        ),
      ),
    )..layout();
    painter.paint(
      canvas,
      at - Offset(painter.width / 2, painter.height / 2),
    );
  }

  static List<Offset> _ring(int count, double radius, [double start = -90]) {
    return List.generate(count, (i) {
      final a = (start + 360 / count * i) * math.pi / 180;
      return Offset(cx + math.cos(a) * radius, cy + math.sin(a) * radius);
    });
  }

  static Path _polygon(List<Offset> pts, double corner) {
    final path = Path();
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final prev = pts[(i - 1 + n) % n];
      final cur = pts[i];
      final next = pts[(i + 1) % n];
      Offset toward(Offset p) {
        final d = p - cur;
        final len = d.distance == 0 ? 1.0 : d.distance;
        final rr = math.min(corner, len / 2);
        return cur + d / len * rr;
      }

      final a = toward(prev);
      final b = toward(next);
      if (i == 0) {
        path.moveTo(a.dx, a.dy);
      } else {
        path.lineTo(a.dx, a.dy);
      }
      path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
    }
    return path..close();
  }

  static List<Offset> _scale(List<Offset> unit, double radius) =>
      [for (final p in unit) Offset(cx + p.dx * radius, cy + p.dy * radius)];

  static Path _circle(double radius) =>
      Path()..addOval(Rect.fromCircle(center: centre, radius: radius));

  static Path _seal(double radius, [int bumps = 14]) {
    final pts = _ring(bumps, radius * 0.9);
    final chord = (pts[1] - pts[0]).distance;
    final arc = Radius.circular(chord * 0.62);
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i <= bumps; i++) {
      final p = pts[i % bumps];
      path.arcToPoint(p, radius: arc);
    }
    return path..close();
  }

  static Path _burst(double radius, [int points = 12]) {
    final pts = <Offset>[
      for (var i = 0; i < points * 2; i++)
        Offset(
          cx +
              math.cos((-90 + 180 / points * i) * math.pi / 180) *
                  (i.isEven ? radius : radius * 0.84),
          cy +
              math.sin((-90 + 180 / points * i) * math.pi / 180) *
                  (i.isEven ? radius : radius * 0.84),
        ),
    ];
    return _polygon(pts, 2.5);
  }

  static const _shieldUnit = [
    Offset(-0.9, -0.84),
    Offset(0, -1),
    Offset(0.9, -0.84),
    Offset(0.88, 0.14),
    Offset(0, 1),
    Offset(-0.88, 0.14),
  ];
  static const _gemUnit = [
    Offset(-0.58, -0.86),
    Offset(0.58, -0.86),
    Offset(1, -0.26),
    Offset(0, 1),
    Offset(-1, -0.26),
  ];

  /// Outline of the medal, its inner face, and how big the icon is.
  static (Path, Path, double) _shapePaths(_Shape shape) {
    switch (shape) {
      case _Shape.hex:
        Path hex(double radius) => _polygon(_ring(6, radius), radius * 0.16);
        return (hex(r), hex(r * 0.76), 0.86);
      case _Shape.shield:
        return (
          _polygon(_scale(_shieldUnit, r), 7),
          _polygon(_scale(_shieldUnit, r * 0.76), 5),
          0.84,
        );
      case _Shape.seal:
        return (_seal(r), _circle(r * 0.68), 0.84);
      case _Shape.gem:
        return (
          _polygon(_scale(_gemUnit, r), 6),
          _polygon(_scale(_gemUnit, r * 0.72), 4),
          0.74,
        );
      case _Shape.burst:
        return (_burst(r), _circle(r * 0.66), 0.82);
      case _Shape.laurel:
        return (_circle(r * 0.78), _circle(r * 0.6), 0.72);
      case _Shape.coin:
        return (_circle(r), _circle(r * 0.78), 0.9);
    }
  }

  @override
  bool shouldRepaint(_MedalPainter old) =>
      old.color != color ||
      old.state != state ||
      old.dark != dark ||
      old.art != art;
}
