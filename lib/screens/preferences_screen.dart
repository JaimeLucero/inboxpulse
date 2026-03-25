import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _loading = true;
  bool _saving = false;

  String _frequency = 'daily';
  int _dayOfWeek = 1;
  TimeOfDay _timeOfDay = const TimeOfDay(hour: 8, minute: 0);
  Map<String, bool> _metrics = {
    'revenue': true,
    'mrr': true,
    'new_customers': true,
    'churned_customers': true,
    'aov': true,
  };
  bool _emailEnabled = true;
  String? _existingDocId;

  static const _metricLabels = {
    'revenue': ('Daily Revenue', Icons.trending_up_rounded),
    'mrr': ('MRR', Icons.bar_chart_rounded),
    'new_customers': ('New Customers', Icons.person_add_rounded),
    'churned_customers': ('Churned Customers', Icons.person_remove_rounded),
    'aov': ('Avg Order Value', Icons.shopping_cart_outlined),
  };

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('report_preferences')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      _existingDocId = snap.docs.first.id;
      _frequency = data['frequency'] ?? 'daily';
      _dayOfWeek = data['dayOfWeek'] ?? 1;
      final parts = (data['timeOfDay'] ?? '08:00').split(':');
      _timeOfDay = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      if (data['metricsEnabled'] is Map) {
        final m = Map<String, dynamic>.from(data['metricsEnabled'] as Map);
        _metrics = m.map((k, v) => MapEntry(k, v as bool));
      }
      _emailEnabled = data['emailEnabled'] ?? true;
    }
    if (mounted) setState(() { _loading = false; });
  }

  Future<void> _save() async {
    setState(() { _saving = true; });
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final timeStr = '${_timeOfDay.hour.toString().padLeft(2, '0')}:${_timeOfDay.minute.toString().padLeft(2, '0')}';
    final data = {
      'userId': uid,
      'frequency': _frequency,
      'dayOfWeek': _dayOfWeek,
      'timeOfDay': timeStr,
      'metricsEnabled': _metrics,
      'emailEnabled': _emailEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final col = FirebaseFirestore.instance.collection('report_preferences');
    if (_existingDocId != null) {
      await col.doc(_existingDocId).update(data);
    } else {
      final doc = await col.add(data);
      _existingDocId = doc.id;
    }
    if (mounted) {
      setState(() { _saving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDay,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppColors.surfaceHigh,
            dialBackgroundColor: AppColors.surfaceHigher,
            hourMinuteColor: AppColors.surfaceHigher,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { _timeOfDay = picked; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _SubNav(title: 'Report Preferences'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Frequency
                      IpCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('FREQUENCY'),
                            const SizedBox(height: 14),
                            Row(
                              children: ['daily', 'weekly'].map((f) {
                                final selected = _frequency == f;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: f == 'daily' ? 8 : 0),
                                    child: _FreqOption(
                                      label: f == 'daily' ? 'Daily' : 'Weekly',
                                      sublabel: f == 'daily' ? 'Every day' : 'Once a week',
                                      selected: selected,
                                      onTap: () => setState(() { _frequency = f; }),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Schedule
                      IpCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('DELIVERY SCHEDULE'),
                            const SizedBox(height: 14),
                            if (_frequency == 'weekly') ...[
                              _SectionLabel('Day of week', small: true),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(7, (i) {
                                  final selected = _dayOfWeek == i + 1;
                                  return _DayChip(
                                    label: _days[i].substring(0, 3),
                                    selected: selected,
                                    onTap: () => setState(() { _dayOfWeek = i + 1; }),
                                  );
                                }),
                              ),
                              const SizedBox(height: 20),
                            ],
                            _SectionLabel('Delivery time', small: true),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _pickTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHigher,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: 10),
                                    Text(
                                      _timeOfDay.format(context),
                                      style: GoogleFonts.figtree(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Change',
                                      style: GoogleFonts.figtree(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Metrics
                      IpCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('METRICS'),
                            const SizedBox(height: 14),
                            ..._metrics.entries.map((entry) {
                              final meta = _metricLabels[entry.key];
                              if (meta == null) return const SizedBox.shrink();
                              return _MetricRow(
                                icon: meta.$2,
                                label: meta.$1,
                                value: entry.value,
                                onChanged: (v) => setState(() { _metrics[entry.key] = v; }),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Email toggle
                      IpCard(
                        child: Row(
                          children: [
                            const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email delivery',
                                    style: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    'Receive reports via email',
                                    style: GoogleFonts.figtree(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _emailEnabled,
                              onChanged: (v) => setState(() { _emailEnabled = v; }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Save preferences'),
                        ),
                      ),
                      const SizedBox(height: 24),
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

// ── Preferences widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool small;
  const _SectionLabel(this.text, {this.small = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.figtree(
        fontSize: small ? 12 : 11,
        fontWeight: FontWeight.w600,
        color: small ? AppColors.textSecondary : AppColors.textMuted,
        letterSpacing: small ? 0 : 0.6,
      ),
    );
  }
}

class _FreqOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _FreqOption({required this.label, required this.sublabel, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentDim : AppColors.surfaceHigher,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.accentMid : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.figtree(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: GoogleFonts.figtree(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 46,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentDim : AppColors.surfaceHigher,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.accentMid : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MetricRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 17, color: value ? AppColors.accent : AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    color: value ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              Checkbox(
                value: value,
                onChanged: (v) => onChanged(v!),
              ),
            ],
          ),
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
          Text(title, style: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
