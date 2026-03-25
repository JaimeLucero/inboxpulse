import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const bg = Color(0xFF0B0B0F);
  static const surface = Color(0xFF111118);
  static const surfaceHigh = Color(0xFF18181F);
  static const surfaceHigher = Color(0xFF1E1E28);

  // Borders
  static const border = Color(0xFF222230);
  static const borderLight = Color(0xFF2C2C3E);

  // Text
  static const textPrimary = Color(0xFFF2F2F5);
  static const textSecondary = Color(0xFF7C7C94);
  static const textMuted = Color(0xFF4A4A62);

  // Accent — emerald (revenue, growth, money)
  static const accent = Color(0xFF10B981);
  static const accentDim = Color(0xFF0A2E20);
  static const accentMid = Color(0xFF065F46);

  // Status
  static const success = Color(0xFF10B981);
  static const successDim = Color(0xFF0A2E20);
  static const warning = Color(0xFFF59E0B);
  static const warningDim = Color(0xFF2D1A00);
  static const error = Color(0xFFEF4444);
  static const errorDim = Color(0xFF2D0A0A);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final figtree = GoogleFonts.figtreeTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: figtree,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.figtree(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.figtree(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.figtree(color: AppColors.textMuted, fontSize: 14),
        errorStyle: GoogleFonts.figtree(color: AppColors.error, fontSize: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w600),
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.accent : Colors.transparent),
        side: const BorderSide(color: AppColors.borderLight, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.accent : AppColors.surfaceHigher),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surfaceHigh,
          selectedBackgroundColor: AppColors.accentMid,
          selectedForegroundColor: AppColors.accent,
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border),
          textStyle: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigher,
        contentTextStyle: GoogleFonts.figtree(color: AppColors.textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceHigh,
        labelStyle: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w500),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class IpCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const IpCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );
  }
}

class IpSectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const IpSectionCard({super.key, required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return IpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class IpStatusDot extends StatelessWidget {
  final bool active;
  const IpStatusDot({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.success : AppColors.textMuted,
        shape: BoxShape.circle,
        boxShadow: active
            ? [BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)]
            : null,
      ),
    );
  }
}

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    const dotRadius = 1.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Logo mark widget
class IpLogo extends StatelessWidget {
  final double size;
  const IpLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: Text(
          'IP',
          style: GoogleFonts.figtree(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class IpWordmark extends StatelessWidget {
  final bool compact;
  const IpWordmark({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IpLogo(size: compact ? 28 : 32),
        const SizedBox(width: 10),
        Text(
          'InboxPulse',
          style: GoogleFonts.figtree(
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
