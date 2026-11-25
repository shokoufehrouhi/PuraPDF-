import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/material.dart';

/// Wraps the whole app and plays the brand intro on top of it once per cold
/// start. The real app is built underneath from the first frame (share
/// intents, ads and routing all keep working), the overlay just lifts away
/// when the animation ends.
///
/// Story: pages of different tools fly in from every side, merge into one
/// sheet (a nod to "merge PDF"), a shock ring rolls out, the ribbon "P" is
/// drawn by a glowing pen that bursts into sparkles, and the name pops in.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child});

  final Widget child;

  /// Only the first mount of the app plays the intro; a locale/theme rebuild
  /// must not replay it.
  static bool _played = false;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );
  bool _show = !SplashOverlay._played;

  @override
  void initState() {
    super.initState();
    SplashOverlay._played = true;
    if (_show) {
      _c.forward().whenComplete(() {
        if (mounted) setState(() => _show = false);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return widget.child;
    final bool dark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Tap to skip straight to the exit.
            onTap: () {
              if (_c.value < 0.9) _c.animateTo(0.9, duration: Duration.zero);
            },
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => _SplashFrame(t: _c.value, dark: dark),
            ),
          ),
        ),
      ],
    );
  }
}

double _seg(double t, double a, double b, [Curve curve = Curves.linear]) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return curve.transform((t - a) / (b - a));
}

class _SplashFrame extends StatelessWidget {
  const _SplashFrame({required this.t, required this.dark});

  final double t;
  final bool dark;

  static const Color _red = Color(0xFFE02020);
  static const List<String> _letters = [
    'P', 'u', 'r', 'a', 'P', 'D', 'F', '+',
  ];

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double mark = math.min(size.width * 0.58, 260);

    final double exit = _seg(t, 0.90, 1.0, Curves.easeInCubic);
    final Color start = dark ? const Color(0xFF1E1E21) : Colors.white;

    return Opacity(
      opacity: 1 - exit,
      child: Transform.scale(
        scale: 1 + 0.10 * exit,
        child: CustomPaint(
          painter: _BackgroundPainter(
            t: t,
            from: start,
            to: _red,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.04),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: mark,
                    height: mark,
                    child: CustomPaint(painter: _MarkPainter(t)),
                  ),
                  SizedBox(height: mark * 0.12),
                  _wordmark(mark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _wordmark(double mark) {
    final double fontSize = mark * 0.15;
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        for (int i = 0; i < _letters.length; i++)
          _letter(_letters[i], i, fontSize),
      ],
    );
  }

  Widget _letter(String ch, int i, double fontSize) {
    final bool plus = i == _letters.length - 1;
    final double begin = 0.62 + i * 0.02;
    final double p = _seg(t, begin, begin + 0.16, Curves.elasticOut);
    final double o = _seg(t, begin, begin + 0.05);

    Widget text = Text(
      ch,
      style: TextStyle(
        fontSize: plus ? fontSize * 1.25 : fontSize,
        fontWeight: plus ? FontWeight.w500 : FontWeight.w800,
        letterSpacing: 1.2,
        height: 1.0,
        color: plus ? const Color(0xFFFFE082) : Colors.white,
        decoration: TextDecoration.none,
        shadows: const [
          Shadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
    );
    if (plus) {
      // The "+" spins in and overshoots.
      text = Transform.rotate(
        angle: (1 - p) * -math.pi * 1.5,
        child: Transform.scale(scale: p.clamp(0.0, 1.6), child: text),
      );
      return Opacity(opacity: o, child: text);
    }
    return Opacity(
      opacity: o,
      child: Transform.translate(
        offset: Offset(0, (1 - p) * fontSize * 1.4),
        child: Transform.rotate(angle: (1 - p) * 0.35, child: text),
      ),
    );
  }
}

/// Ink-spread background plus faint pages drifting upwards.
class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({required this.t, required this.from, required this.to});

  final double t;
  final Color from;
  final Color to;

  static const List<List<double>> _drift = [
    // x (0..1), speed, size, phase, rot
    [0.10, 0.9, 0.16, 0.00, -0.3],
    [0.30, 0.6, 0.11, 0.35, 0.2],
    [0.52, 1.1, 0.19, 0.60, 0.4],
    [0.72, 0.7, 0.13, 0.15, -0.5],
    [0.90, 1.0, 0.17, 0.80, 0.3],
    [0.20, 0.8, 0.09, 0.50, 0.6],
    [0.82, 0.5, 0.10, 0.95, -0.2],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double reveal = _seg(t, 0.0, 0.16, Curves.easeOutCubic);
    canvas.drawRect(Offset.zero & size, Paint()..color = from);
    final Offset center = size.center(Offset.zero);
    final double maxR = size.bottomRight(Offset.zero).distance / 2 + 8;
    final double r = maxR * reveal;
    if (r > 0) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFF03030), Color(0xFFBE1010)],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    // Drifting pages, only once the red has taken over.
    final double fade = _seg(t, 0.10, 0.30);
    if (fade > 0) {
      for (final List<double> d in _drift) {
        final double w = size.width * d[2];
        final double h = w * 1.3;
        final double travel = size.height + h * 2;
        final double y =
            size.height + h - ((t * d[1] * 1.6 + d[3]) % 1.0) * travel;
        final double x = size.width * d[0] + math.sin(t * 6 + d[3] * 9) * 12;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(d[4] + t * 1.2 * d[4]);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: h),
            Radius.circular(w * 0.1),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.10 * fade),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.t != t;
}

class _Flyer {
  const _Flyer(this.angle, this.accent, this.fanX, this.fanY, this.fanRot,
      this.spin);
  final double angle; // direction it flies in from
  final Color accent; // little "tool" tab colour
  final double fanX, fanY, fanRot; // resting fan position
  final double spin; // extra turns while flying
}

/// The PuraPDF+ mark, drawn in the 1024-unit coordinate space of the app
/// icon. It paints outside its own box on purpose (flying pages, shock ring).
class _MarkPainter extends CustomPainter {
  _MarkPainter(this.t);

  final double t;

  static const double _u = 1024;
  static const Rect _sheet = Rect.fromLTRB(278, 152, 803, 832);
  static const double _ear = 173;

  static const List<_Flyer> _flyers = [
    _Flyer(-2.6, Color(0xFFFFB300), -150, -40, -0.42, 1.2),
    _Flyer(-0.9, Color(0xFF29B6F6), 140, -70, 0.38, -1.0),
    _Flyer(0.4, Color(0xFF66BB6A), 160, 60, 0.18, 1.5),
    _Flyer(1.7, Color(0xFFAB47BC), -120, 70, -0.20, -1.3),
    _Flyer(2.6, Color(0xFFFF7043), 0, -10, 0.05, 0.9),
  ];

  Path get _sheetPath => Path()
    ..moveTo(_sheet.left + 40, _sheet.top)
    ..lineTo(_sheet.right - _ear, _sheet.top)
    ..lineTo(_sheet.right, _sheet.top + _ear)
    ..lineTo(_sheet.right, _sheet.bottom - 40)
    ..quadraticBezierTo(
        _sheet.right, _sheet.bottom, _sheet.right - 40, _sheet.bottom)
    ..lineTo(_sheet.left + 40, _sheet.bottom)
    ..quadraticBezierTo(
        _sheet.left, _sheet.bottom, _sheet.left, _sheet.bottom - 40)
    ..lineTo(_sheet.left, _sheet.top + 40)
    ..quadraticBezierTo(_sheet.left, _sheet.top, _sheet.left + 40, _sheet.top)
    ..close();

  /// Centre-line of the P: up the stem, across the top, round the bowl.
  Path get _pLine {
    const double cx = 555, cy = 552, r = 122;
    return Path()
      ..moveTo(300, 880)
      ..lineTo(300, 430)
      ..lineTo(cx, 430)
      ..arcTo(Rect.fromCircle(center: const Offset(cx, cy), radius: r),
          -math.pi / 2, math.pi, false)
      ..lineTo(490, cy + r);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _u);
    final Offset c = _sheet.center;

    _paintFlyers(canvas, c);
    _paintRing(canvas, c);
    _paintMainSheet(canvas, c);
    canvas.restore();
  }

  void _paintFlyers(Canvas canvas, Offset c) {
    for (int i = 0; i < _flyers.length; i++) {
      final _Flyer f = _flyers[i];
      final double s = i * 0.012;
      final double fly = _seg(t, 0.03 + s, 0.25 + s, Curves.easeOutCubic);
      final double merge = _seg(t, 0.27 + s * 0.5, 0.38, Curves.easeInBack);
      if (fly <= 0 || merge >= 1) continue;

      final Offset from = c + Offset(math.cos(f.angle), math.sin(f.angle)) * 1800;
      final Offset fan = c + Offset(f.fanX, f.fanY);
      Offset pos = Offset.lerp(from, fan, fly)!;
      pos = Offset.lerp(pos, c, merge)!;
      final double rot = (1 - fly) * f.spin * math.pi * 2 + f.fanRot * (1 - merge);
      // Smaller while flying, grows to full sheet size as it merges.
      final double scale = 0.62 * (0.7 + 0.3 * fly);
      final double k = scale + (1.0 - scale) * merge;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);
      canvas.scale(k);
      final Rect r = Rect.fromCenter(
          center: Offset.zero, width: _sheet.width, height: _sheet.height);
      final RRect rr = RRect.fromRectAndRadius(r, const Radius.circular(40));
      final double a = (1 - merge * 0.6).clamp(0.0, 1.0);
      canvas.drawRRect(
        rr.shift(const Offset(0, 20)),
        Paint()
          ..color = Color.fromRGBO(80, 0, 0, 0.28 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
      canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: a));
      // Tool-colour tab and fake text lines.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left + 50, r.top + 56, 170, 36),
          const Radius.circular(18),
        ),
        Paint()..color = f.accent.withValues(alpha: a),
      );
      final Paint line = Paint()
        ..color = const Color(0xFFD7D7DC).withValues(alpha: a);
      for (int l = 0; l < 6; l++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(r.left + 50, r.top + 150 + l * 70,
                r.width - 100 - (l.isOdd ? 120 : 0), 24),
            const Radius.circular(12),
          ),
          line,
        );
      }
      canvas.restore();
    }
  }

  void _paintRing(Canvas canvas, Offset c) {
    final double p = _seg(t, 0.36, 0.58, Curves.easeOutCubic);
    if (p <= 0 || p >= 1) return;
    canvas.drawCircle(
      c,
      200 + 1500 * p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 40 * (1 - p) + 4
        ..color = Colors.white.withValues(alpha: 0.7 * (1 - p)),
    );
  }

  void _paintMainSheet(Canvas canvas, Offset c) {
    final double pop = _seg(t, 0.36, 0.52, Curves.easeOutBack);
    final double o = _seg(t, 0.36, 0.40);
    if (o <= 0) return;

    // Squash-and-stretch on impact.
    final double wob = math.sin(pop * math.pi * 2.5) * (1 - pop) * 0.10;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(0.9 + 0.1 * pop + wob, 0.9 + 0.1 * pop - wob);
    canvas.translate(-c.dx, -c.dy);

    final Path sheet = _sheetPath;
    canvas.drawPath(
      sheet.shift(const Offset(0, 26)),
      Paint()
        ..color = Color.fromRGBO(90, 0, 0, 0.35 * o)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    canvas.drawPath(sheet, Paint()..color = Colors.white.withValues(alpha: o));

    // Dog-ear snaps over.
    final double earK = _seg(t, 0.56, 0.68, Curves.easeOutBack);
    if (earK > 0) {
      final Path fold = Path()
        ..moveTo(_sheet.right - _ear, _sheet.top)
        ..lineTo(_sheet.right - _ear, _sheet.top + _ear)
        ..lineTo(_sheet.right, _sheet.top + _ear)
        ..close();
      final Offset pivot = Offset(_sheet.right - _ear, _sheet.top + _ear);
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.scale(earK.clamp(0.0, 1.15));
      canvas.translate(-pivot.dx, -pivot.dy);
      canvas.drawPath(
        fold,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white, Colors.grey.shade300],
          ).createShader(
              Rect.fromLTWH(_sheet.right - _ear, _sheet.top, _ear, _ear)),
      );
      canvas.restore();
    }

    _paintP(canvas);

    // Shine sweep across the sheet.
    final double shine = _seg(t, 0.78, 0.92, Curves.easeInOutCubic);
    if (shine > 0 && shine < 1) {
      canvas.save();
      canvas.clipPath(sheet);
      final double x = _sheet.left - 200 + (_sheet.width + 400) * shine;
      canvas.drawRect(
        Rect.fromLTWH(x - 90, _sheet.top, 180, _sheet.height),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(x - 90, 0, 180, 1)),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  void _paintP(Canvas canvas) {
    final double pK = _seg(t, 0.46, 0.70, Curves.easeInOutCubic);
    if (pK <= 0) return;

    final List<PathMetric> metrics = _pLine.computeMetrics().toList();
    final double total = metrics.fold(0.0, (s, m) => s + m.length);
    double remaining = total * pK;
    final Path trimmed = Path();
    Tangent? tip;
    for (final PathMetric m in metrics) {
      final double take = math.min(remaining, m.length);
      if (take <= 0) break;
      trimmed.addPath(m.extractPath(0, take), Offset.zero);
      tip = m.getTangentForOffset(take);
      remaining -= take;
    }

    canvas.drawPath(
      trimmed,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 125
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFE41E1E), Color(0xFFB80000)],
        ).createShader(const Rect.fromLTWH(237, 368, 502, 560)),
    );

    // Glowing pen tip while drawing.
    if (tip != null && pK < 1) {
      final Offset p = tip.position;
      canvas.drawCircle(
        p,
        120,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFFFCDD2).withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0),
          ], stops: const [0, 0.35, 1])
              .createShader(Rect.fromCircle(center: p, radius: 120)),
      );
    }

    // Sparkle burst when the stroke lands.
    final double burst = _seg(t, 0.70, 0.86, Curves.easeOutCubic);
    if (burst > 0 && burst < 1) {
      const Offset end = Offset(470, 674);
      for (int i = 0; i < 12; i++) {
        final double ang = i / 12 * math.pi * 2 + 0.3;
        final double dist = (i.isEven ? 230 : 150) * burst;
        final Offset p = end + Offset(math.cos(ang), math.sin(ang)) * dist;
        final double s = (i.isEven ? 16 : 10) * (1 - burst);
        canvas.drawCircle(
          p,
          s,
          Paint()
            ..color = (i % 3 == 0 ? const Color(0xFFFFE082) : Colors.white)
                .withValues(alpha: 1 - burst),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t;
}
