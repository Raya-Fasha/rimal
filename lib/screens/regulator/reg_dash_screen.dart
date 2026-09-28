import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../widgets/widgets.dart';

class RegDashScreen extends StatelessWidget {
  final AppState state;
  final Map<String, dynamic> t;
  const RegDashScreen({super.key, required this.state, required this.t});

  @override
  Widget build(BuildContext context) {
    final statuses = t['statuses'] as Map;
    final all      = t['reg_all'] as String;
    final sfOpts   = [all, 'Submitted', 'Under Review', 'Approved', 'Rejected', 'Info Required'];
    final rfOpts   = [all, 'Low', 'Medium', 'High'];
    final stats    = t['reg_stats'] as List;
    final apps     = state.applications;

    final filtered = apps.where((a) {
      final statusMatch = state.statusFilter == all ||
          state.statusFilter == 'All' ||
          a['status'].toString().toLowerCase() ==
              state.statusFilter.toLowerCase();
      final riskMatch = state.riskFilter == all ||
          state.riskFilter == 'All' ||
          a['risk'] == state.riskFilter;
      return statusMatch && riskMatch;
    }).toList();

    final totalCount    = apps.length;
    final pendingCount  = apps.where((a) => a['status'].toString().toLowerCase() == 'submitted' || a['status'].toString().toLowerCase() == 'under review').length;
    final approvedCount = apps.where((a) => a['status'].toString().toLowerCase() == 'approved').length;
    final highRiskCount = apps.where((a) => a['risk'] == 'High').length;

    return RimalScaffold(
      state: state,
      t: t,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RSectionLabel(t['reg_label']),
            const SizedBox(height: 4),
            Text(t['reg_title'],
                style: const TextStyle(
                    color: C.textPrim,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                [totalCount, 0],
                [pendingCount, 1],
                [highRiskCount, 2],
                [approvedCount, 3],
              ].map((e) {
                final idx = e[1];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: idx < 3 ? 8 : 0),
                    child: RCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e[0]}',
                              style: const TextStyle(
                                  color: C.textPrim,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900)),
                          Text(stats[idx],
                              style: const TextStyle(
                                  color: C.textDim, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Status filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sfOpts.map((f) {
                  final active = state.statusFilter == f ||
                      (state.statusFilter == 'All' && f == all);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _FilterChip(
                      label:    f == all ? f : statuses[f] ?? f,
                      isActive: active,
                      onTap:    () => state.setSF(f),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Risk filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: rfOpts.map((f) {
                  final active = state.riskFilter == f ||
                      (state.riskFilter == 'All' && f == all);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _FilterChip(
                      label:    f,
                      isActive: active,
                      onTap:    () => state.setRF(f),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Loading / error / results
            if (state.isAppLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.appError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(state.appError!,
                    style: const TextStyle(color: C.red, fontSize: 13),
                    textAlign: TextAlign.center),
              )
            else if (filtered.isEmpty)
              REmptyState(
                icon: Icons.filter_list_off_rounded,
                title: t['reg_empty_title'],
                subtitle: t['reg_empty_sub'],
              )
            else
              ...filtered.map((app) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HoverLift(
                      onTap: () => state.selectApp(app, 'review'),
                      child: RCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(app['id'] ?? '',
                                    style: const TextStyle(
                                        color: C.textDim,
                                        fontSize: 11,
                                        fontFamily: 'monospace')),
                                Row(children: [
                                  RBadge(
                                      label: app['risk'],
                                      bg: riskBg(app['risk']),
                                      fg: riskFg(app['risk'])),
                                  const SizedBox(width: 6),
                                  RBadge(
                                      label: statuses[app['status']] ?? app['status'],
                                      bg: statusBg(app['status']),
                                      fg: statusFg(app['status'])),
                                ]),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(app['project'] ?? '',
                                style: const TextStyle(
                                    color: C.textPrim,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            Text('${app['org']} · ${app['sector']}',
                                style: const TextStyle(
                                    color: C.textDim, fontSize: 12)),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: RBtn(
                                  label: t['reg_review'],
                                  onTap: () => state.selectApp(app, 'review')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

// ── Hover-lift wrapper for tappable cards ─────────────────────────────────

class _HoverLift extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverLift({required this.child, required this.onTap});

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color:      C.blue.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset:     const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:          widget.onTap,
            borderRadius:   BorderRadius.circular(16),
            splashColor:    C.blue.withValues(alpha: 0.1),
            highlightColor: C.blue.withValues(alpha: 0.05),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ── Filter chip with hover animation ─────────────────────────────────────

class _FilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? C.blue
                : (_hovered ? C.border : C.card),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? C.blue : (_hovered ? C.borderHi : C.border),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: active
                  ? Colors.white
                  : (_hovered ? C.textPrim : C.textMut),
              fontSize:   12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
