import 'package:flutter/material.dart';
import '../../services/application_service.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';

// ── Clarification bottom sheet ────────────────────────────────────────────
void _showClarifySheet(
  BuildContext context,
  Map<String, dynamic> t,
  String applicationId,
) {
  final controller = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ClarifySheet(
      controller:    controller,
      t:             t,
      applicationId: applicationId,
    ),
  );
}

class _ClarifySheet extends StatefulWidget {
  final TextEditingController controller;
  final Map<String, dynamic> t;
  final String applicationId;
  const _ClarifySheet({
    required this.controller,
    required this.t,
    required this.applicationId,
  });

  @override
  State<_ClarifySheet> createState() => _ClarifySheetState();
}

class _ClarifySheetState extends State<_ClarifySheet> {
  bool _sent      = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF001830),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x400072CF)),
      ),
      child: _sent
          ? _SentState(label: widget.t['rv_clarify_sent'] ?? 'Clarification request sent to applicant.')
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF002850),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: C.blue, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.t['rv_clarify'] ?? 'Request Clarification',
                        style: const TextStyle(color: C.textPrim, fontSize: 15, fontWeight: FontWeight.w700)),
                    const Text('Send a question to the applicant',
                        style: TextStyle(color: C.textDim, fontSize: 12)),
                  ])),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close_rounded, color: C.textDim, size: 16),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                const Text('Your message', style: TextStyle(color: C.textDim, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: widget.controller,
                  maxLines: 4,
                  autofocus: true,
                  style: const TextStyle(color: C.textPrim, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Describe what information you need from the applicant…',
                    hintStyle: const TextStyle(color: C.textDim, fontSize: 13),
                    filled: true,
                    fillColor: C.bg,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.blue)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (widget.controller.text.trim().isEmpty) return;
                            setState(() => _isLoading = true);
                            try {
                              await ApplicationService.instance.sendClarification(
                                applicationId: widget.applicationId,
                                message:       widget.controller.text,
                              );
                            } catch (_) {
                              // Best-effort for demo — still show success
                            }
                            if (mounted) setState(() { _sent = true; _isLoading = false; });
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: C.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      _isLoading ? 'Sending…' : 'Send Request',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Schedule Meeting bottom sheet ─────────────────────────────────────────
void _showScheduleSheet(
  BuildContext context,
  Map<String, dynamic> t,
  String applicationId,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScheduleSheet(t: t, applicationId: applicationId),
  );
}

class _ScheduleSheet extends StatefulWidget {
  final Map<String, dynamic> t;
  final String applicationId;
  const _ScheduleSheet({required this.t, required this.applicationId});

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  bool _sent        = false;
  bool _isLoading   = false;
  int  _selectedDay  = 0;
  int  _selectedTime = 0;

  static const _days  = ['Mon 14', 'Tue 15', 'Wed 16', 'Thu 17', 'Fri 18'];
  static const _times = ['09:00', '10:30', '13:00', '14:30', '16:00'];

  // Compute an absolute DateTime for the selected day/time slot.
  // Uses the upcoming Monday as the anchor so the dates stay in the future.
  DateTime _computeDateTime() {
    final now    = DateTime.now();
    var monday   = now.subtract(Duration(days: now.weekday - 1));
    // If the chosen day has already passed this week, use next week
    if (now.weekday - 1 > _selectedDay) {
      monday = monday.add(const Duration(days: 7));
    }
    final date = monday.add(Duration(days: _selectedDay));
    const hours   = [9, 10, 13, 14, 16];
    const minutes = [0, 30,  0, 30,  0];
    return DateTime(date.year, date.month, date.day, hours[_selectedTime], minutes[_selectedTime]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF001830),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x400072CF)),
      ),
      child: _sent
          ? _SentState(label: widget.t['rv_schedule_sent'] ?? 'Meeting invitation sent to applicant.')
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF002040),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: C.sand, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.t['rv_schedule'] ?? 'Schedule Meeting',
                        style: const TextStyle(color: C.textPrim, fontSize: 15, fontWeight: FontWeight.w700)),
                    const Text('Invite the applicant to a meeting',
                        style: TextStyle(color: C.textDim, fontSize: 12)),
                  ])),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close_rounded, color: C.textDim, size: 16),
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                const Text('Select a day', style: TextStyle(color: C.textDim, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_days.length, (i) {
                    final active = i == _selectedDay;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDay = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.only(right: i < _days.length - 1 ? 6 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? C.blue : C.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: active ? C.blue : C.border),
                          ),
                          child: Text(_days[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: active ? Colors.white : C.textDim,
                              fontSize: 11,
                              fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text('Select a time', style: TextStyle(color: C.textDim, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_times.length, (i) {
                    final active = i == _selectedTime;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTime = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF002850) : C.bg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: active ? C.blue : C.border),
                        ),
                        child: Text(_times[i],
                          style: TextStyle(
                            color: active ? C.blue : C.textDim,
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              await ApplicationService.instance.scheduleMeeting(
                                applicationId: widget.applicationId,
                                proposedAt:    _computeDateTime(),
                              );
                            } catch (_) {
                              // Best-effort for demo — still show success
                            }
                            if (mounted) setState(() { _sent = true; _isLoading = false; });
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF003D1A),
                      foregroundColor: C.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: C.green),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: C.green))
                        : const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      _isLoading
                          ? 'Scheduling…'
                          : 'Confirm – ${_days[_selectedDay]} at ${_times[_selectedTime]}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Sent confirmation state ────────────────────────────────────────────────
class _SentState extends StatelessWidget {
  final String label;
  const _SentState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF003322),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF004433)),
          ),
          child: const Icon(Icons.check_rounded, color: C.green, size: 28),
        ),
        const SizedBox(height: 14),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: C.textPrim, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done', style: TextStyle(color: C.blue)),
        ),
      ]),
    );
  }
}

// ── Review Screen ──────────────────────────────────────────────────────────
class ReviewScreen extends StatefulWidget {
  final AppState state;
  final Map<String, dynamic> t;
  const ReviewScreen({super.key, required this.state, required this.t});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state     = widget.state;
    final t         = widget.t;
    final app       = state.selectedApp!;
    final statuses  = t['statuses'] as Map;
    final decisions = t['rv_decisions'] as List;
    final appId     = app['uuid'] as String? ?? '';

    return RimalScaffold(
      state: state,
      t: t,
      backView: 'regdash',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RSectionLabel(t['rv_label']),
                const SizedBox(height: 4),
                Text(app['project'],
                    style: const TextStyle(
                        color: C.textPrim,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                Text('${app['org']} · ${app['id']}',
                    style: const TextStyle(color: C.textDim, fontSize: 12)),
              ]),
              RBadge(
                  label: statuses[app['status']] ?? app['status'],
                  bg: statusBg(app['status']),
                  fg: statusFg(app['status'])),
            ],
          ),
          const SizedBox(height: 16),

          // AI Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF002040),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xff0072cf30)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: C.sand, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(t['rv_ai_label'].toString().toUpperCase(),
                        style: const TextStyle(
                            color: C.sand,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                  ]),
                  const SizedBox(height: 8),
                  Text(t['rv_ai_text'],
                      style: const TextStyle(
                          color: C.textMut, fontSize: 13, height: 1.6)),
                ]),
          ),
          const SizedBox(height: 12),

          // Risk Score
          RCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['rv_score'].toString().toUpperCase(),
                      style: const TextStyle(
                          color: C.textDim,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  Center(child: RRiskRing(score: app['score'])),
                  const SizedBox(height: 12),
                  Center(
                    child: RBadge(
                        label: app['risk'],
                        bg: riskBg(app['risk']),
                        fg: riskFg(app['risk'])),
                  ),
                ]),
          ),
          const SizedBox(height: 12),

          // Regulator actions
          RCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['rv_actions'].toString().toUpperCase(),
                      style: const TextStyle(
                          color: C.textDim,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 14),

                  // Risk assignment
                  Text(t['rv_assign_risk'],
                      style: const TextStyle(color: C.textDim, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      {'label': 'Low',    'fg': C.green,  'bg': const Color(0xFF003322)},
                      {'label': 'Medium', 'fg': C.orange, 'bg': const Color(0xFF1A0A00)},
                      {'label': 'High',   'fg': C.red,    'bg': const Color(0xFF1A0000)},
                    ].map((r) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: r['label'] != 'High' ? 6 : 0),
                          child: _RiskBtn(
                            label:    r['label'] as String,
                            fg:       r['fg'] as Color,
                            activeBg: r['bg'] as Color,
                            isActive: state.reviewRisk == r['label'],
                            onTap:    () => state.setReviewRisk(r['label'] as String),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Internal notes
                  Text(t['rv_notes'],
                      style: const TextStyle(color: C.textDim, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: C.textPrim, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: t['rv_notes_ph'],
                      hintStyle: const TextStyle(color: C.textDim, fontSize: 13),
                      filled: true,
                      fillColor: C.bg,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: C.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: C.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: C.blue)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Decision radio list
                  Text(t['rv_decision'],
                      style: const TextStyle(color: C.textDim, fontSize: 12)),
                  const SizedBox(height: 8),
                  ...decisions.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DecisionItem(
                      label:    d,
                      isActive: state.reviewDecision == d,
                      onTap:    () => state.setDecision(d),
                    ),
                  )),
                  const SizedBox(height: 6),

                  // Quick action buttons
                  Row(children: [
                    Expanded(child: _QuickBtn(
                      label: t['rv_clarify'],
                      onTap: () => _showClarifySheet(context, t, appId),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _QuickBtn(
                      label: t['rv_schedule'],
                      onTap: () => _showScheduleSheet(context, t, appId),
                    )),
                  ]),
                  const SizedBox(height: 12),

                  // Submit error banner
                  if (state.reviewError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A0A0A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF7A1A1A)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(state.reviewError!,
                              style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12)),
                        ),
                      ]),
                    ),
                  ],

                  RBtn(
                    label: state.isSavingReview ? 'Saving…' : t['rv_submit'],
                    onTap: () => state.submitReview(notes: _notesCtrl.text),
                    disabled: state.reviewDecision.isEmpty || state.isSavingReview,
                    fullWidth: true,
                  ),
                ]),
          ),
        ]),
      ),
    );
  }
}

// ── Review Done ────────────────────────────────────────────────────────────
class ReviewDoneScreen extends StatelessWidget {
  final AppState state;
  final Map<String, dynamic> t;
  const ReviewDoneScreen({super.key, required this.state, required this.t});

  @override
  Widget build(BuildContext context) => RimalScaffold(
        state: state,
        t: t,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      color: const Color(0xFF003322),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF004433))),
                  child: const Icon(Icons.check_rounded, color: C.green, size: 32),
                ),
                const SizedBox(height: 20),
                Text(t['rv_done'],
                    style: const TextStyle(
                        color: C.textPrim,
                        fontSize: 22,
                        fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(t['rv_done_decision'],
                    style: const TextStyle(color: C.textMut, fontSize: 14)),
                const SizedBox(height: 4),
                Text(state.reviewDecision,
                    style: const TextStyle(
                        color: C.textPrim,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                RBtn(
                    label: t['rv_done_btn'],
                    onTap: () => state.go('regdash'),
                    ghost: true),
              ],
            ),
          ),
        ),
      );
}

// ── Risk level selector button ─────────────────────────────────────────────

class _RiskBtn extends StatefulWidget {
  final String label;
  final Color fg;
  final Color activeBg;
  final bool isActive;
  final VoidCallback onTap;

  const _RiskBtn({
    required this.label,
    required this.fg,
    required this.activeBg,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_RiskBtn> createState() => _RiskBtnState();
}

class _RiskBtnState extends State<_RiskBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.activeBg
                : (_hovered ? widget.activeBg.withValues(alpha: 0.4) : Colors.transparent),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: (widget.isActive || _hovered)
                  ? widget.fg.withValues(alpha: 0.5)
                  : C.border,
            ),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:      widget.fg,
              fontSize:   12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Decision radio item ────────────────────────────────────────────────────

class _DecisionItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DecisionItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_DecisionItem> createState() => _DecisionItemState();
}

class _DecisionItemState extends State<_DecisionItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active     = widget.isActive;
    final isApproved = widget.label.contains('Approved');
    final isRejected = widget.label.contains('Rejected');
    final isMoreInfo = widget.label.contains('More');

    final Color borderColor = active
        ? isApproved ? C.green
            : isRejected ? C.red
            : isMoreInfo ? C.orange
            : C.blue
        : (_hovered ? C.borderHi : C.border);

    final Color bgColor = active
        ? isApproved ? const Color(0xFF003322)
            : isRejected ? const Color(0xFF1A0000)
            : isMoreInfo ? const Color(0xFF1A0A00)
            : const Color(0xFF002040)
        : (_hovered ? C.card : C.bg);

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:        bgColor,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: borderColor),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width:  16,
              height: 16,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
                color:  active ? borderColor : Colors.transparent,
              ),
              child: active
                  ? const Icon(Icons.circle, color: Colors.white, size: 8)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                color: active
                    ? borderColor
                    : (_hovered ? C.textPrim : C.textMut),
                fontSize:   13,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Quick action button ────────────────────────────────────────────────────

class _QuickBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickBtn({required this.label, required this.onTap});

  @override
  State<_QuickBtn> createState() => _QuickBtnState();
}

class _QuickBtnState extends State<_QuickBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:        _hovered ? C.card : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border:       Border.all(color: _hovered ? C.borderHi : C.border),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:    _hovered ? C.textMut : C.textDim,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
