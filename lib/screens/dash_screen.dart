import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/widgets.dart';

class DashScreen extends StatelessWidget {
  final AppState state;
  final Map<String, dynamic> t;
  const DashScreen({super.key, required this.state, required this.t});

  @override
  Widget build(BuildContext context) {
    final stats      = t['dash_stats'] as List;
    final flagLabels = t['flag_labels'] as List;
    final statuses   = t['statuses'] as Map;
    final apps       = state.applications;

    final totalCount    = apps.length;
    final approvedCount = apps.where((a) =>
        a['status'].toString().toLowerCase() == 'approved').length;
    final pendingCount  = apps.where((a) {
      final s = a['status'].toString().toLowerCase();
      return s == 'submitted' || s == 'under review';
    }).length;

    return RimalScaffold(
      state: state,
      t: t,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RSectionLabel(t['dash_label']),
                  const SizedBox(height: 4),
                  Text(t['dash_title'],
                      style: const TextStyle(
                          color: C.textPrim,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ]),
                RBtn(
                  label: t['dash_new'],
                  onTap: () {
                    state.resetForm();
                    state.go('apply');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                [totalCount, 0],
                [pendingCount, 1],
                [approvedCount, 2],
              ].map((e) {
                final idx = e[1];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                    child: _StatCard(
                      value: '${e[0]}',
                      label: stats[idx],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Application list or empty state
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
            else if (apps.isEmpty)
              REmptyState(
                icon: Icons.inbox_outlined,
                title: t['dash_empty_title'],
                subtitle: t['dash_empty_sub'],
                actionLabel: t['dash_new'],
                onAction: () {
                  state.resetForm();
                  state.go('apply');
                },
              )
            else
              ...apps.map((app) {
                final flags = app['flags'] as List;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HoverLift(
                    onTap: () => state.selectApp(app, 'detail'),
                    child: RCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(app['id'],
                                  style: const TextStyle(
                                      color: C.textDim,
                                      fontSize: 11,
                                      fontFamily: 'monospace')),
                              const SizedBox(width: 8),
                              RBadge(
                                  label: statuses[app['status']] ??
                                      app['status'],
                                  bg: statusBg(app['status']),
                                  fg: statusFg(app['status'])),
                              const SizedBox(width: 6),
                              RBadge(
                                  label: app['risk'],
                                  bg: riskBg(app['risk']),
                                  fg: riskFg(app['risk'])),
                            ]),
                            const SizedBox(height: 6),
                            Text(app['project'],
                                style: const TextStyle(
                                    color: C.textPrim,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            Text('${app['org']} · ${app['sector']}',
                                style: const TextStyle(
                                    color: C.textDim, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: RScoreBar(score: app['score'])),
                              const SizedBox(width: 8),
                              Text('${app['score']}/100',
                                  style: const TextStyle(
                                      color: C.textDim, fontSize: 11)),
                            ]),
                            if (flags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(spacing: 6, children: [
                                Text(t['dash_flags'],
                                    style: const TextStyle(
                                        color: C.textDim, fontSize: 11)),
                                ...flags.map((fi) {
                                  final icons = [
                                    Icons.lock_outline_rounded,
                                    Icons.supervised_user_circle_outlined,
                                    Icons.warning_amber_rounded,
                                    Icons.balance_rounded,
                                  ];
                                  final icon = fi < icons.length ? icons[fi] : Icons.flag_rounded;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A0800),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      border: Border.all(
                                          color: const Color(0xFF3A1800)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon,
                                            color: C.orange, size: 10),
                                        const SizedBox(width: 3),
                                        Text(flagLabels[fi],
                                            style: const TextStyle(
                                                color: C.orange, fontSize: 9)),
                                      ],
                                    ),
                                  );
                                }),
                              ]),
                            ],
                          ]),
                    ),
                  ),
                );
              }),
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
            onTap:           widget.onTap,
            borderRadius:    BorderRadius.circular(16),
            splashColor:     C.blue.withValues(alpha: 0.1),
            highlightColor:  C.blue.withValues(alpha: 0.05),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ── Stat card with hover highlight ────────────────────────────────────────

class _StatCard extends StatefulWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        _hovered ? const Color(0xFF003D6B) : C.card,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: _hovered ? C.borderHi : C.border),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color:      C.blue.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset:     const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.value,
              style: const TextStyle(
                  color: C.textPrim,
                  fontSize: 22,
                  fontWeight: FontWeight.w900),
            ),
            Text(
              widget.label,
              style: const TextStyle(color: C.textDim, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
