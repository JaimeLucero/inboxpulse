import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final firstName = (user.displayName ?? user.email ?? 'there').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _TopNav(user: user),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Good morning, $firstName',
                        style: GoogleFonts.figtree(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Here's your InboxPulse overview",
                        style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 28),

                      // Google Analytics card
                      _GaCard(uid: user.uid),
                      const SizedBox(height: 14),

                      // Preferences card
                      _PreferencesCard(uid: user.uid),
                      const SizedBox(height: 14),

                      // Report history
                      _ReportsCard(uid: user.uid),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top navigation bar ─────────────────────────────────────────────────────────

class _TopNav extends StatelessWidget {
  final User user;
  const _TopNav({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const IpWordmark(compact: true),
          const Spacer(),
          _UserMenu(user: user),
        ],
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  final User user;
  const _UserMenu({required this.user});

  @override
  Widget build(BuildContext context) {
    final initial = (user.displayName ?? user.email ?? 'U')[0].toUpperCase();
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      color: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      onSelected: (value) {
        if (value == 'signout') FirebaseAuth.instance.signOut();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName ?? 'User',
                style: GoogleFonts.figtree(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
              ),
              Text(
                user.email ?? '',
                style: GoogleFonts.figtree(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'signout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text('Sign out', style: GoogleFonts.figtree(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accentDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentMid),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.figtree(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

// ── Dashboard cards ────────────────────────────────────────────────────────────

class _GaCard extends StatelessWidget {
  final String uid;
  const _GaCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ga_connections')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.hasData ? snapshot.data!.docs : [];
        final connected = docs.isNotEmpty;
        final data = connected ? docs.first.data() as Map<String, dynamic> : null;
        final propertyName = data?['propertyName'] as String?;
        final propertyId = data?['propertyId'] as String?;
        final ready = connected && propertyName != null;
        final needsPicker = connected && propertyId == null;
        final String statusLabel = ready ? 'Connected' : (needsPicker ? 'Action needed' : 'Not connected');
        final String title = ready ? propertyName! : (needsPicker ? 'Select a property' : 'Connect Google Analytics');
        final String subtitle = ready
            ? 'InboxPulse can read your website metrics'
            : (needsPicker ? 'Tap Manage to pick your GA4 property' : 'Required to generate your reports');
        return IpSectionCard(
          title: 'GOOGLE ANALYTICS',
          trailing: _StatusPill(active: ready, label: statusLabel),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.figtree(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              _CardAction(
                label: ready ? 'Manage' : (needsPicker ? 'Manage' : 'Connect'),
                onTap: () => context.push('/ga'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  final String uid;
  const _PreferencesCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('report_preferences')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final hasPrefs = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        String detail = 'Not configured';
        if (hasPrefs) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final freq = data['frequency'] ?? 'daily';
          final time = data['timeOfDay'] ?? '08:00';
          detail = '${freq[0].toUpperCase()}${freq.substring(1)} at $time';
        }
        return IpSectionCard(
          title: 'REPORT SCHEDULE',
          trailing: _StatusPill(active: hasPrefs, label: hasPrefs ? 'Active' : 'Setup needed'),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPrefs ? detail : 'No schedule set',
                    style: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasPrefs ? 'Reports will be emailed automatically' : 'Configure your delivery frequency',
                    style: GoogleFonts.figtree(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              _CardAction(
                label: hasPrefs ? 'Edit' : 'Set up',
                onTap: () => context.push('/preferences'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportsCard extends StatelessWidget {
  final String uid;
  const _ReportsCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    return IpSectionCard(
      title: 'RECENT REPORTS',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('report_logs')
            .where('userId', isEqualTo: uid)
            .orderBy('sentAt', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigher,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'No reports sent yet',
                    style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
              final status = data['status'] ?? 'unknown';
              final sent = status == 'sent';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: sent ? AppColors.successDim : AppColors.errorDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        sent ? Icons.mail_rounded : Icons.error_outline_rounded,
                        size: 16,
                        color: sent ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sentAt != null ? _fmt(sentAt) : 'Unknown date',
                        style: GoogleFonts.figtree(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                    _StatusPill(active: sent, label: sent ? 'Sent' : 'Failed'),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Shared dashboard widgets ───────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool active;
  final String label;
  const _StatusPill({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.successDim : AppColors.surfaceHigher,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppColors.accentMid : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IpStatusDot(active: active),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.accent : AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CardAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigher,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.figtree(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

