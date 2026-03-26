import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme.dart';


class GaConnectScreen extends StatefulWidget {
  const GaConnectScreen({super.key});

  @override
  State<GaConnectScreen> createState() => _GaConnectScreenState();
}

class _GaConnectScreenState extends State<GaConnectScreen>
    with WidgetsBindingObserver {
  bool _loading = false;
  bool _awaitingReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingReturn) {
      setState(() { _awaitingReturn = false; });
    }
  }

  Future<void> _connectGa() async {
    final clientId = dotenv.env['GOOGLE_OAUTH_CLIENT_ID'] ?? '';
    final callbackUrl = dotenv.env['GA_CALLBACK_URL'] ?? '';
    if (clientId.isEmpty || callbackUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GOOGLE_OAUTH_CLIENT_ID or GA_CALLBACK_URL not configured.')),
      );
      return;
    }
    setState(() { _loading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final idToken = await user.getIdToken();
      final uri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': callbackUrl,
        'response_type': 'code',
        'scope': 'https://www.googleapis.com/auth/analytics.readonly',
        'access_type': 'offline',
        'prompt': 'consent',
        'state': idToken,
      });
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) {
        if (mounted) setState(() { _awaitingReturn = true; });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google authorization page.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _showPropertyPicker(
      String docId, List<dynamic> properties) async {
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PropertyPickerDialog(properties: properties),
    );
    if (picked == null) return;
    setState(() { _loading = true; });
    await FirebaseFirestore.instance
        .collection('ga_connections')
        .doc(docId)
        .update({
      'propertyId': picked['id'],
      'propertyName': picked['name'],
    });
    if (mounted) setState(() { _loading = false; });
  }

  Future<void> _disconnect(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Disconnect Google Analytics?',
        body: 'Your GA account will be unlinked. Reports will stop until you reconnect.',
        confirmLabel: 'Disconnect',
        destructive: true,
      ),
    );
    if (confirmed != true) return;
    setState(() { _loading = true; });
    await FirebaseFirestore.instance
        .collection('ga_connections')
        .doc(docId)
        .delete();
    if (mounted) setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _SubNav(title: 'Google Analytics'),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('ga_connections')
                        .where('userId', isEqualTo: uid)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator(
                            color: AppColors.accent, strokeWidth: 2);
                      }
                      final docs = snapshot.data!.docs;
                      final connected = docs.isNotEmpty;
                      final docId = connected ? docs.first.id : null;
                      final data = connected
                          ? docs.first.data() as Map<String, dynamic>
                          : null;
                      final propertyId = data?['propertyId'] as String?;
                      final propertyName = data?['propertyName'] as String?;
                      final properties =
                          (data?['properties'] as List<dynamic>?) ?? [];
                      final needsPicker = connected && propertyId == null;

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
                                        color: connected
                                            ? AppColors.successDim
                                            : AppColors.surfaceHigher,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: connected
                                              ? AppColors.accentMid
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Icon(
                                        connected
                                            ? Icons.analytics_rounded
                                            : Icons.analytics_outlined,
                                        color: connected
                                            ? AppColors.success
                                            : AppColors.textMuted,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          connected
                                              ? (propertyName ??
                                                  'Select a property')
                                              : 'Not connected',
                                          style: GoogleFonts.figtree(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          connected
                                              ? (propertyId != null
                                                  ? 'Google Analytics · Read-only'
                                                  : 'Choose your GA4 property below')
                                              : 'OAuth required',
                                          style: GoogleFonts.figtree(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
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
                                      ? 'Your Google Analytics account is linked. InboxPulse reads your website metrics to generate reports. No data is modified.'
                                      : 'Connect your Google Analytics account to start receiving automated website reports. InboxPulse only requests read-only access.',
                                  style: GoogleFonts.figtree(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (needsPicker && properties.isNotEmpty)
                                  SizedBox(
                                    height: 48,
                                    child: FilledButton(
                                      onPressed: _loading
                                          ? null
                                          : () => _showPropertyPicker(
                                              docId!, properties),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                              Icons.domain_verification_rounded,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Text('Select GA4 Property',
                                              style: GoogleFonts.figtree(
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  )
                                else if (needsPicker && properties.isEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorDim,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppColors.error
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded,
                                            size: 16, color: AppColors.error),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'No GA4 properties found. Make sure the Google Analytics Admin API is enabled in your Google Cloud project.',
                                            style: GoogleFonts.figtree(
                                                fontSize: 13,
                                                color: AppColors.error,
                                                height: 1.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 44,
                                          child: FilledButton(
                                            onPressed:
                                                _loading ? null : _connectGa,
                                            child: Text('Reconnect',
                                                style: GoogleFonts.figtree(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        height: 44,
                                        child: OutlinedButton(
                                          onPressed: _loading
                                              ? null
                                              : () => _disconnect(docId!),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                            side: BorderSide(
                                                color: AppColors.error
                                                    .withValues(alpha: 0.4)),
                                          ),
                                          child: Text('Disconnect',
                                              style: GoogleFonts.figtree(
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (connected)
                                  SizedBox(
                                    height: 44,
                                    child: OutlinedButton(
                                      onPressed: _loading
                                          ? null
                                          : () => _disconnect(docId!),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: BorderSide(
                                            color: AppColors.error
                                                .withValues(alpha: 0.4)),
                                        minimumSize:
                                            const Size(double.infinity, 44),
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.error))
                                          : Text('Disconnect',
                                              style: GoogleFonts.figtree(
                                                  fontWeight: FontWeight.w600)),
                                    ),
                                  )
                                else ...[
                                  if (_awaitingReturn) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentDim,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.accentMid),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.accent),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Authorize in your browser, then return here.',
                                              style: GoogleFonts.figtree(
                                                  fontSize: 13,
                                                  color: AppColors.accent),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 44,
                                      child: OutlinedButton(
                                        onPressed: () => setState(
                                            () { _awaitingReturn = false; }),
                                        child: Text('Back to Connect',
                                            style: GoogleFonts.figtree(
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ] else
                                    SizedBox(
                                      height: 48,
                                      child: FilledButton(
                                        onPressed: _loading ? null : _connectGa,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.link_rounded,
                                                size: 18),
                                            const SizedBox(width: 8),
                                            Text('Connect Google Analytics',
                                                style: GoogleFonts.figtree(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          IpCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded,
                                    size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'InboxPulse requests read-only access to your Google Analytics data. Your data is never shared or modified.',
                                    style: GoogleFonts.figtree(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                        height: 1.5),
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

// ── Property picker dialog ──────────────────────────────────────────────────────

class _PropertyPickerDialog extends StatefulWidget {
  final List<dynamic> properties;
  const _PropertyPickerDialog({required this.properties});

  @override
  State<_PropertyPickerDialog> createState() => _PropertyPickerDialogState();
}

class _PropertyPickerDialogState extends State<_PropertyPickerDialog> {
  String? _selectedId;

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
            Text(
              'Select GA4 Property',
              style: GoogleFonts.figtree(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose which property to track',
              style: GoogleFonts.figtree(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Column(
                  children: widget.properties.map((p) {
                    final prop = p as Map<String, dynamic>;
                    final id = prop['id'] as String;
                    final name = prop['name'] as String? ?? id;
                    final selected = _selectedId == id;
                    return GestureDetector(
                      onTap: () => setState(() { _selectedId = id; }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accentDim
                              : AppColors.surfaceHigher,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.accentMid
                                : AppColors.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.analytics_outlined,
                                size: 16,
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.textMuted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.figtree(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: selected
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_rounded,
                                  size: 16, color: AppColors.accent),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: GoogleFonts.figtree(fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: FilledButton(
                      onPressed: _selectedId == null
                          ? null
                          : () {
                              final prop = widget.properties.firstWhere(
                                  (p) =>
                                      (p as Map<String, dynamic>)['id'] ==
                                      _selectedId) as Map<String, dynamic>;
                              Navigator.pop(context, prop);
                            },
                      child: Text('Confirm',
                          style: GoogleFonts.figtree(
                              fontSize: 14, fontWeight: FontWeight.w600)),
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

// ── Shared widgets ──────────────────────────────────────────────────────────────

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
            Text(title,
                style: GoogleFonts.figtree(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text(body,
                style: GoogleFonts.figtree(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel',
                          style: GoogleFonts.figtree(fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            destructive ? AppColors.error : AppColors.accent,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(confirmLabel,
                          style: GoogleFonts.figtree(
                              fontSize: 14, fontWeight: FontWeight.w600)),
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
            icon: const Icon(Icons.arrow_back_rounded,
                size: 20, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.figtree(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
