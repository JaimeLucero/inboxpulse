import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme.dart';

const _stripeClientId = 'YOUR_STRIPE_CLIENT_ID';
const _stripeCallbackUrl = 'https://us-central1-inboxpulse-a6458.cloudfunctions.net/stripe_callback';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _loading = false;

  Future<void> _connectStripe() async {
    final user = FirebaseAuth.instance.currentUser!;
    final idToken = await user.getIdToken();
    final uri = Uri.https('connect.stripe.com', '/oauth/authorize', {
      'response_type': 'code',
      'client_id': _stripeClientId,
      'scope': 'read_only',
      'redirect_uri': _stripeCallbackUrl,
      'state': idToken,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Stripe authorization page.')),
        );
      }
    }
  }

  Future<void> _disconnectStripe(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Disconnect Stripe?',
        body: 'Your Stripe account will be unlinked. Reports will stop until you reconnect.',
        confirmLabel: 'Disconnect',
        destructive: true,
      ),
    );
    if (confirmed != true) return;
    setState(() { _loading = true; });
    await FirebaseFirestore.instance.collection('stripe_accounts').doc(docId).delete();
    if (mounted) setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _SubNav(title: 'Stripe Connection'),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('stripe_accounts')
                        .where('userId', isEqualTo: uid)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2);
                      }
                      final connected = snapshot.data!.docs.isNotEmpty;
                      final docId = connected ? snapshot.data!.docs.first.id : null;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          IpCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: connected ? AppColors.successDim : AppColors.surfaceHigher,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: connected ? AppColors.accentMid : AppColors.border),
                                      ),
                                      child: Icon(
                                        connected ? Icons.check_rounded : Icons.credit_card_rounded,
                                        color: connected ? AppColors.success : AppColors.textMuted,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          connected ? 'Stripe Connected' : 'Stripe Not Connected',
                                          style: GoogleFonts.figtree(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          connected ? 'Read-only access' : 'OAuth required',
                                          style: GoogleFonts.figtree(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(color: AppColors.border),
                                const SizedBox(height: 20),
                                Text(
                                  connected
                                      ? 'Your Stripe account is linked. InboxPulse uses read-only access to pull revenue metrics for your reports. No transactions are affected.'
                                      : 'Connect your Stripe account to start receiving automated revenue reports. InboxPulse only requests read-only access — it cannot move money or modify your account.',
                                  style: GoogleFonts.figtree(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (connected)
                                  SizedBox(
                                    height: 44,
                                    child: OutlinedButton(
                                      onPressed: _loading ? null : () => _disconnectStripe(docId!),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                                        minimumSize: const Size(double.infinity, 44),
                                      ),
                                      child: _loading
                                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                                          : Text('Disconnect Stripe', style: GoogleFonts.figtree(fontWeight: FontWeight.w600)),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    height: 48,
                                    child: FilledButton(
                                      onPressed: _loading ? null : _connectStripe,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.link_rounded, size: 18),
                                          const SizedBox(width: 8),
                                          Text('Connect with Stripe', style: GoogleFonts.figtree(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          IpCard(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'InboxPulse uses OAuth and only requests read-only Stripe permissions.',
                                    style: GoogleFonts.figtree(fontSize: 12, color: AppColors.textMuted, height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
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

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final bool destructive;

  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.figtree(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text(body, style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel', style: GoogleFonts.figtree(fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: destructive ? AppColors.error : AppColors.accent,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(confirmLabel, style: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubNav extends StatelessWidget {
  final String title;
  const _SubNav({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
