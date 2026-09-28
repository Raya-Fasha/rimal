import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../models/form_data.dart';
import '../theme/colors.dart';
import '../widgets/widgets.dart';

class SuccessScreen extends StatelessWidget {
  final AppState state;
  final Map<String, dynamic> t;
  const SuccessScreen({super.key, required this.state, required this.t});

  @override
  Widget build(BuildContext context) {
    final result     = state.submittedResult;
    final flagLabels = t['flag_labels'] as List;

    return RimalScaffold(
      state: state,
      t: t,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 8),

          // ── Check icon ──
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF003322),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF004433)),
            ),
            child: const Icon(Icons.check_rounded, color: C.green, size: 32),
          ),
          const SizedBox(height: 20),
          Text(t['success_title'],
              style: const TextStyle(
                  color: C.textPrim,
                  fontSize: 22,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(t['success_ref'],
              style: const TextStyle(color: C.textMut, fontSize: 13)),
          const SizedBox(height: 4),
          Text(state.submittedReference ?? 'APP-2024-006',
              style: const TextStyle(
                  color: C.sand,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace')),
          const SizedBox(height: 8),
          Text(t['success_sub'],
              style: const TextStyle(
                  color: C.textDim, fontSize: 13, height: 1.6),
              textAlign: TextAlign.center),

          // ── Risk Score Card ──
          if (result != null) ...[
            const SizedBox(height: 24),
            RCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['detail_score'].toString().toUpperCase(),
                        style: const TextStyle(
                            color: C.textDim,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 12),
                    Center(
                      child: RRiskRing(score: result.score),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: RBadge(
                          label: result.level,
                          bg: riskBg(result.level),
                          fg: riskFg(result.level)),
                    ),
                  ]),
            ),

            // ── Compliance Flags ──
            if (result.flags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0800),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3A1800)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['detail_flags'].toString().toUpperCase(),
                          style: const TextStyle(
                              color: C.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 10),
                      ...result.flags.map((fi) {
                        final icons = [
                          Icons.lock_outline_rounded,
                          Icons.supervised_user_circle_outlined,
                          Icons.warning_amber_rounded,
                          Icons.balance_rounded,
                        ];
                        final icon = fi < icons.length ? icons[fi] : Icons.flag_rounded;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            Icon(icon,
                                color: C.orange, size: 14),
                            const SizedBox(width: 8),
                            Text(flagLabels[fi],
                                style: const TextStyle(
                                    color: C.orange, fontSize: 13)),
                          ]),
                        );
                      }),
                    ]),
              ),
            ],

            // ── Score Breakdown ──
            if (result.breakdown.isNotEmpty) ...[
              const SizedBox(height: 12),
              RCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['detail_breakdown'].toString().toUpperCase(),
                          style: const TextStyle(
                              color: C.textDim,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 10),
                      ..._groupedBreakdown(result.breakdown),
                    ]),
              ),
            ],
          ],

          const SizedBox(height: 24),
          RBtn(
              label: t['success_btn'],
              onTap: () => state.go('dash'),
              fullWidth: true),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  List<Widget> _groupedBreakdown(List<ScoreBreakdownItem> items) {
    final Map<String, List<ScoreBreakdownItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    final widgets = <Widget>[];
    grouped.forEach((category, catItems) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(category.toUpperCase(),
            style: const TextStyle(
                color: C.blue,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ));
      for (final item in catItems) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(
                child: Text(item.label,
                    style:
                        const TextStyle(color: C.textMut, fontSize: 12))),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: C.bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: C.border)),
              child: Text('+${item.points}',
                  style: const TextStyle(
                      color: C.textPrim,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace')),
            ),
          ]),
        ));
      }
      widgets.add(const RDivider());
      widgets.add(const SizedBox(height: 8));
    });
    return widgets;
  }
}
