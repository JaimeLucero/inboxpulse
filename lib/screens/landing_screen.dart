import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  static const _count = 5;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _fades = List.generate(_count, (i) {
      final start = i * 0.12;
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, (start + 0.4).clamp(0, 1),
            curve: Curves.easeOut),
      );
    });

    _slides = List.generate(_count, (i) {
      final start = i * 0.12;
      return Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, (start + 0.5).clamp(0, 1),
            curve: Curves.easeOutCubic),
      ));
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openAuth({bool signup = false}) {
    context.go(signup ? '/signup' : '/login');
  }

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 860;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background dot grid
          Positioned.fill(
            child: CustomPaint(painter: DotGridPainter()),
          ),
          // Radial glow behind hero
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 600,
                height: 400,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                _Nav(onSignIn: () => _openAuth()),
                _Hero(
                  isWide: isWide,
                  animated: _animated,
                  onGetStarted: () => _openAuth(signup: true),
                  onSignIn: () => _openAuth(),
                ),
                _animated(2, const _StatStrip()),
                _animated(3, const _Features()),
                _animated(4, const _HowItWorks()),
                _Cta(onGetStarted: () => _openAuth(signup: true)),
                const _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav ────────────────────────────────────────────────────────────────────────

class _Nav extends StatelessWidget {
  final VoidCallback onSignIn;
  const _Nav({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          const IpWordmark(compact: true),
          const Spacer(),
          GestureDetector(
            onTap: onSignIn,
            child: Text(
              'Sign in',
              style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: onSignIn,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Get started',
                style: GoogleFonts.figtree(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero ───────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final bool isWide;
  final Widget Function(int, Widget) animated;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const _Hero({
    required this.isWide,
    required this.animated,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 28, vertical: isWide ? 80 : 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: _HeroText(animated: animated, onGetStarted: onGetStarted, onSignIn: onSignIn)),
                    const SizedBox(width: 48),
                    Expanded(flex: 4, child: animated(1, const _EmailMockup())),
                  ],
                )
              : Column(
                  children: [
                    _HeroText(animated: animated, onGetStarted: onGetStarted, onSignIn: onSignIn),
                    const SizedBox(height: 40),
                    animated(1, const _EmailMockup()),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final Widget Function(int, Widget) animated;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const _HeroText({
    required this.animated,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        animated(
          0,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accentDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentMid),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const IpStatusDot(active: true),
                const SizedBox(width: 8),
                Text(
                  'Google Analytics → your inbox',
                  style: GoogleFonts.figtree(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        animated(
          0,
          Text(
            'Your website metrics,\ndelivered.',
            style: GoogleFonts.figtree(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 18),
        animated(
          0,
          Text(
            'Connect your Google Analytics account and get automated\nreports sent straight to your inbox — daily or weekly.',
            style: GoogleFonts.figtree(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
        ),
        const SizedBox(height: 32),
        animated(
          1,
          Row(
            children: [
              GestureDetector(
                onTap: onGetStarted,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    'Start for free',
                    style: GoogleFonts.figtree(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onSignIn,
                child: Text(
                  'Sign in →',
                  style: GoogleFonts.figtree(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Email mockup ───────────────────────────────────────────────────────────────

class _EmailMockup extends StatelessWidget {
  const _EmailMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email header chrome
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    _dot(const Color(0xFFFF5F57)),
                    const SizedBox(width: 6),
                    _dot(const Color(0xFFFEBC2E)),
                    const SizedBox(width: 6),
                    _dot(const Color(0xFF28C840)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigher,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: Text(
                        'Weekly Report · InboxPulse',
                        style: GoogleFonts.figtree(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Email body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IpLogo(size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'InboxPulse',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Weekly',
                      style: GoogleFonts.figtree(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Your weekly\nanalytics report',
                  style: GoogleFonts.figtree(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),
                _metricRow('Users', '2,841', '+12%', positive: true),
                const SizedBox(height: 10),
                _metricRow('Sessions', '4,103', '+8%', positive: true),
                const SizedBox(height: 10),
                _metricRow('Pageviews', '11,240', '+5%', positive: true),
                const SizedBox(height: 10),
                _metricRow('Bounce rate', '38.2%', '-3%', positive: true),
                const SizedBox(height: 10),
                _metricRow('Avg. session', '2m 14s', '-4%', positive: false),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accentDim,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentMid),
                  ),
                  child: Center(
                    child: Text(
                      'View full report',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
      width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _metricRow(String label, String value, String delta,
      {required bool positive}) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.figtree(
                fontSize: 12, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.figtree(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: positive ? AppColors.accentDim : AppColors.errorDim,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            delta,
            style: GoogleFonts.figtree(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: positive ? AppColors.accent : AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat strip ─────────────────────────────────────────────────────────────────

class _StatStrip extends StatelessWidget {
  const _StatStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final narrow = c.maxWidth < 500;
        final items = [
          ('5', 'metrics tracked'),
          ('2 min', 'to connect'),
          ('Daily / Weekly', 'delivery options'),
          ('100%', 'free to use'),
        ];
        if (narrow) {
          return Column(
            children: items
                .map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _stat(s.$1, s.$2),
                    ))
                .toList(),
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((s) => _stat(s.$1, s.$2)).toList(),
        );
      }),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(
            value,
            style: GoogleFonts.figtree(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.figtree(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      );
}

// ── Features ───────────────────────────────────────────────────────────────────

class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              Text(
                'Everything you need,\nnothing you don\'t.',
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No dashboards to check, no logins to remember.',
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                    fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              LayoutBuilder(builder: (context, c) {
                final narrow = c.maxWidth < 600;
                final cards = [
                  (Icons.analytics_outlined, 'Google Analytics connected',
                      'Read-only access to your GA4 property. We track users, sessions, pageviews, bounce rate, and average session duration.'),
                  (Icons.schedule_rounded, 'On your schedule',
                      'Choose daily or weekly delivery. Pick the exact time and day. Your report arrives when you want it.'),
                  (Icons.mark_email_read_outlined, 'Inbox-ready formatting',
                      'Clean, scannable emails with week-over-week deltas. No noise — just the numbers that matter.'),
                ];
                if (narrow) {
                  return Column(
                    children: cards
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _FeatureCard(
                                  icon: c.$1, title: c.$2, body: c.$3),
                            ))
                        .toList(),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cards
                      .map((c) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: _FeatureCard(
                                  icon: c.$1, title: c.$2, body: c.$3),
                            ),
                          ))
                      .toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureCard(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentMid),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.figtree(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.figtree(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── How it works ───────────────────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              Text(
                'Up and running in minutes.',
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 48),
              LayoutBuilder(builder: (context, c) {
                final narrow = c.maxWidth < 600;
                final steps = [
                  ('01', 'Create your account',
                      'Sign up with Google or email. Takes 30 seconds — no credit card required.'),
                  ('02', 'Connect Google Analytics',
                      'Authorize read-only access to your GA4 account and select the property you want to track.'),
                  ('03', 'Set your schedule',
                      'Choose daily or weekly delivery, pick your time, and select which metrics to include. That\'s it.'),
                ];
                if (narrow) {
                  return Column(
                    children: steps
                        .asMap()
                        .entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _StepCard(
                                  number: e.value.$1,
                                  title: e.value.$2,
                                  body: e.value.$3,
                                  last: e.key == steps.length - 1),
                            ))
                        .toList(),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps
                      .asMap()
                      .entries
                      .map((e) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: _StepCard(
                                  number: e.value.$1,
                                  title: e.value.$2,
                                  body: e.value.$3,
                                  last: e.key == steps.length - 1),
                            ),
                          ))
                      .toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  final bool last;

  const _StepCard(
      {required this.number,
      required this.title,
      required this.body,
      required this.last});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              number,
              style: GoogleFonts.figtree(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
                letterSpacing: 1,
              ),
            ),
            if (!last) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.border,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.figtree(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: GoogleFonts.figtree(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

// ── CTA ────────────────────────────────────────────────────────────────────────

class _Cta extends StatelessWidget {
  final VoidCallback onGetStarted;
  const _Cta({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Text(
                'Stop checking dashboards.',
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Let your analytics come to you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                    fontSize: 17, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),
              GestureDetector(
                onTap: onGetStarted,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    'Get started for free →',
                    style: GoogleFonts.figtree(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No credit card required',
                style: GoogleFonts.figtree(
                    fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: Row(
        children: [
          const IpWordmark(compact: true),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/privacy'),
            child: Text(
              'Privacy Policy',
              style: GoogleFonts.figtree(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 24),
          Text(
            '© 2026 InboxPulse',
            style:
                GoogleFonts.figtree(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

