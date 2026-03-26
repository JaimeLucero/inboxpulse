import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasNav = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (hasNav)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                if (hasNav) const SizedBox(width: 4),
                const IpWordmark(compact: true),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Policy',
                        style: GoogleFonts.figtree(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Last updated: March 26, 2026',
                        style: GoogleFonts.figtree(
                            fontSize: 14, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 32),
                      _body(
                        'InboxPulse is a service that connects your Google Analytics account and delivers automated website metric reports to your inbox. This policy explains what data we collect, how we use it, and your rights.',
                      ),
                      _section('1. Information We Collect'),
                      _bullets([
                        'Account information — your email address and display name when you sign up.',
                        'Google Analytics OAuth tokens — an access token and refresh token so we can read your website metrics on your behalf.',
                        'GA4 property selection — the property ID and name you choose to track.',
                        'Report preferences — delivery frequency, time of day, and selected metrics.',
                        'Report logs — timestamps and delivery status of reports sent to you.',
                      ]),
                      _section('2. How We Use Your Information'),
                      _bullets([
                        'To authenticate you and manage your account.',
                        'To read your Google Analytics data (read-only) and generate metric summaries.',
                        'To send scheduled email reports according to your preferences.',
                        'To display your connection status and report history in the app.',
                      ]),
                      _body(
                        'We do not sell, share, or use your data for advertising. We never modify any data in your Google Analytics account.',
                      ),
                      _section('3. Data Storage'),
                      _body(
                        'Your data is stored in Google Firebase Firestore, a cloud database operated by Google. OAuth tokens are stored encrypted at rest. We retain your data for as long as your account is active.',
                      ),
                      _section('4. Third-Party Services'),
                      _bullets([
                        'Google Firebase — authentication and database.',
                        'Google Analytics Admin API & Data API — to list your properties and fetch metrics.',
                        'Resend — email delivery.',
                      ]),
                      _section('5. Google API Data'),
                      _body(
                        "InboxPulse's use of information received from Google APIs adheres to the Google API Services User Data Policy, including the Limited Use requirements. We only request the analytics.readonly scope and use it exclusively to generate your reports.",
                      ),
                      _section('6. Your Rights'),
                      _bullets([
                        'Disconnect Google Analytics — revoke access at any time from within the app.',
                        'Delete your account — contact us to have all your data permanently removed.',
                        'Access your data — contact us to receive a copy of the data we hold.',
                      ]),
                      _section('7. Contact'),
                      _body(
                        'For any privacy questions or data deletion requests, email us at jaimeemanuellucero@gmail.com.',
                      ),
                      const SizedBox(height: 48),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 20),
                      Text(
                        '© 2026 InboxPulse. All rights reserved.',
                        style: GoogleFonts.figtree(
                            fontSize: 13, color: AppColors.textMuted),
                      ),
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

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 10),
        child: Text(
          title,
          style: GoogleFonts.figtree(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      );

  Widget _body(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(
          text,
          style: GoogleFonts.figtree(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.7,
          ),
        ),
      );

  Widget _bullets(List<String> items) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.figtree(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );
}
