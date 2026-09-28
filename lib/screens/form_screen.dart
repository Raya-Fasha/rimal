import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/widgets.dart';

class FormScreen extends StatelessWidget {
  final AppState state;
  final Map<String, dynamic> t;
  const FormScreen({super.key, required this.state, required this.t});

  @override
  Widget build(BuildContext context) {
    final steps = t['form_steps'] as List;
    final step  = state.formStep;

    return RimalScaffold(
      state: state,
      t: t,
      backView: 'dash',
      body: Column(children: [
        // ── Step indicator ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: C.border))),
          child: Row(
            children: List.generate(steps.length, (i) {
              final n      = i + 1;
              final done   = n < step;
              final active = n == step;
              return Expanded(
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: i > 0
                            ? Container(
                                height: 1,
                                color: done ? C.blue : C.border)
                            : const SizedBox(),
                      ),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: done
                              ? C.blue
                              : active
                                  ? Colors.transparent
                                  : C.border,
                          shape: BoxShape.circle,
                          border: active
                              ? Border.all(color: C.blue, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 14)
                              : Text('$n',
                                  style: TextStyle(
                                      color:
                                          active ? C.blue : C.textDim,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                      Expanded(
                        child: i < steps.length - 1
                            ? Container(
                                height: 1,
                                color: done ? C.blue : C.border)
                            : const SizedBox(),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      steps[i].toString(),
                      style: TextStyle(
                        color: active ? C.textMut : C.textDim,
                        fontSize: 8,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        // ── Body ─────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RSectionLabel(t['form_label']),
                const SizedBox(height: 4),
                Text(steps[step - 1],
                    style: const TextStyle(
                        color: C.textPrim,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _buildStep(step, state, t),

                // Validation error banner
                if (state.formValidationError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A0A0A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: C.red.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: C.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t[state.formValidationError] ??
                              state.formValidationError!,
                          style: const TextStyle(
                              color: C.red, fontSize: 13),
                        ),
                      ),
                    ]),
                  ),
                ],

                if (state.formSubmissionError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A0A0A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: C.red.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: C.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.formSubmissionError!,
                          style: const TextStyle(
                              color: C.red, fontSize: 13),
                        ),
                      ),
                    ]),
                  ),
                ],

                const SizedBox(height: 24),

                // Nav buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RBtn(
                      label: step == 1
                          ? t['form_cancel']
                          : t['form_prev'],
                      onTap: step == 1
                          ? () => state.go('dash')
                          : state.formPrev,
                      ghost: true,
                    ),
                    Text('$step ${t['form_of']} 5',
                        style: const TextStyle(
                            color: C.textDim, fontSize: 12)),
                    step < 5
                        ? RBtn(
                            label: t['form_next'],
                            onTap: () => state.formNext(),
                          )
                        : _SubmitBtn(
                            label: state.isFormSubmitting
                                ? t['form_submitting'] ?? 'Submitting...'
                                : t['form_submit'],
                            onTap: state.isFormSubmitting
                                ? () {}
                                : () => state.submitForm(),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Step builders ─────────────────────────────────────────────────────
  Widget _buildStep(int step, AppState state, Map<String, dynamic> t) {
    final fd = state.formData;
    switch (step) {
      // ── Step 1 — Organisation ────────────────────────────────────────
      case 1:
        return Column(children: [
          _field('Organization name *',
              RInput(placeholder: 'e.g. TechVision Jordan', controller: fd.orgName)),
          _field('Registration number *',
              RInput(
                  placeholder: 'e.g. CR12345',
                  controller: fd.regNumber)),
          _field('Contact person *',
              RInput(placeholder: 'Full name', controller: fd.contactPerson)),
          _field('Email *',
              RInput(
                  placeholder: 'contact@company.jo',
                  controller: fd.email,
                  keyboardType: TextInputType.emailAddress)),
          _field('Phone',
              RInput(
                  placeholder: '+962 x xxxx xxxx',
                  controller: fd.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()\-]'))])),
          _field('Website',
              RInput(
                  placeholder: 'https://',
                  controller: fd.website,
                  keyboardType: TextInputType.url)),
        ]);

      // ── Step 2 — Project ─────────────────────────────────────────────
      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field('Project name *',
              RInput(
                  placeholder: 'e.g. CitizenAI Assistant',
                  controller: fd.projectName)),
          _field('Description *',
              RInput(
                  placeholder: 'Describe your project...',
                  controller: fd.description,
                  maxLines: 3)),
          _field('Intended users',
              RInput(
                  placeholder: 'e.g. Citizens, Government agencies',
                  controller: fd.intendedUsers)),
          _field('Deployment region',
              RInput(
                  placeholder: 'e.g. Jordan — Amman',
                  controller: fd.deployRegion)),
          RLabel('Development stage *'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (t['form_stage_opts'] as List).map((s) {
              final active = fd.selectedStage == s;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => state.setStage(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF002040)
                          : C.bg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: active ? C.blue : C.border),
                    ),
                    child: Text(s,
                        style: TextStyle(
                            color: active ? C.blue : C.textMut,
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ),
                ),
              );
            }).toList(),
          ),
        ]);

      // ── Step 3 — AI System ───────────────────────────────────────────
      case 3:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RLabel('AI use case type *'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (t['form_ai_types'] as List).map((s) {
              final selected = fd.selectedAiTypes.contains(s);
              return _checkChip(
                label: s,
                selected: selected,
                onTap: () => state.toggleAiType(s),
                selectedColor: C.blue,
                selectedBg: const Color(0xFF002040),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _field('Model type',
              RInput(
                  placeholder: 'e.g. Large Language Model',
                  controller: fd.modelType)),
          _field('How the model works',
              RInput(
                  placeholder: 'Describe the model architecture...',
                  controller: fd.modelDesc,
                  maxLines: 3)),

          // Phase 4 — "Does the system make decisions?" (was missing)
          const SizedBox(height: 4),
          RLabel('${t['form_makes_decisions']} *'),
          const SizedBox(height: 6),
          RYesNo(
            value: fd.makesDecisions,
            yesLabel: t['form_yes'],
            noLabel: t['form_no'],
            onChanged: state.setMakesDecisions,
          ),
          const SizedBox(height: 16),

          // Phase 4 — "Is there human oversight?" (was missing)
          RLabel('${t['form_human_oversight']} *'),
          const SizedBox(height: 6),
          RYesNo(
            value: fd.hasHumanOversight,
            yesLabel: t['form_yes'],
            noLabel: t['form_no'],
            onChanged: state.setHumanOversight,
          ),
        ]);

      // ── Step 4 — Risk & Data ─────────────────────────────────────────
      case 4:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RLabel('Data types used *'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (t['form_data_types'] as List).map((s) {
              final selected = fd.selectedDataTypes.contains(s);
              return _checkChip(
                label: s,
                selected: selected,
                onTap: () => state.toggleDataType(s),
                selectedColor: C.blue,
                selectedBg: const Color(0xFF002040),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          RLabel('${t['form_sensitive_data']} *'),
          const SizedBox(height: 6),
          RYesNo(
            value: fd.processesSensitiveData,
            yesLabel: t['form_yes'],
            noLabel: t['form_no'],
            onChanged: state.setProcessesSensitiveData,
          ),
          const SizedBox(height: 16),
          _field('Who is affected?',
              RInput(
                  placeholder: 'e.g. Citizens, Employees',
                  controller: fd.affectedUsers)),
          _field('Estimated users',
              RInput(
                  placeholder: 'e.g. 50000',
                  controller: fd.estimatedUsers,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          RLabel('Known risks'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (t['form_risks'] as List).map((s) {
              final selected = fd.selectedRisks.contains(s);
              return GestureDetector(
                onTap: () => state.toggleRisk(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF2A1000)
                        : const Color(0xFF1A0800),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: selected
                            ? C.orange
                            : const Color(0xFF3A1800)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: selected
                            ? C.orange
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: C.orange),
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 10)
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(s,
                        style: const TextStyle(
                            color: C.orange, fontSize: 12)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _field('Risk mitigation plan',
              RInput(
                  placeholder:
                      'Describe how you will mitigate identified risks...',
                  controller: fd.mitigationPlan,
                  maxLines: 4)),
        ]);

      // ── Step 5 — Documents ───────────────────────────────────────────
      case 5:
        return Column(
          children: (t['form_doc_types'] as List).map((doc) {
            final uploaded = fd.uploadedFiles[doc];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: uploaded != null ? C.green : C.borderHi),
                  color: uploaded != null
                      ? const Color(0xFF001A11)
                      : Colors.transparent,
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc,
                              style: const TextStyle(
                                  color: C.textPrim,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          uploaded != null
                              ? Text(uploaded,
                                  style: const TextStyle(
                                      color: C.green, fontSize: 11),
                                  overflow: TextOverflow.ellipsis)
                              : Text(t['form_doc_note'],
                                  style: const TextStyle(
                                      color: C.textDim, fontSize: 11)),
                        ]),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                        withData: true,
                      );
                      if (result != null &&
                          result.files.isNotEmpty) {
                        final file = result.files.first;
                        state.setUploadedFile(
                            doc, file.name, file.bytes);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: uploaded != null
                                ? C.green
                                : C.borderHi),
                        color: uploaded != null
                            ? const Color(0xFF003322)
                            : Colors.transparent,
                      ),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (uploaded != null) ...[
                              const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: C.green,
                                  size: 13),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              uploaded != null
                                  ? 'Uploaded'
                                  : t['form_upload'],
                              style: TextStyle(
                                  color: uploaded != null
                                      ? C.green
                                      : C.textMut,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ]),
                    ),
                  ),
                ]),
              ),
            );
          }).toList(),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _field(String label, Widget input) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RLabel(label),
          const SizedBox(height: 6),
          input,
        ]),
      );

  Widget _checkChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color selectedColor,
    required Color selectedBg,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? selectedBg : C.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? selectedColor : C.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: selected ? selectedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border:
                    Border.all(color: selected ? selectedColor : C.border),
              ),
              child: selected
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 10)
                  : null,
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? C.textPrim : C.textMut,
                    fontSize: 12)),
          ]),
        ),
      );
}

// ── Green submit button with hover animation ───────────────────────────────

class _SubmitBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SubmitBtn({required this.label, required this.onTap});

  @override
  State<_SubmitBtn> createState() => _SubmitBtnState();
}

class _SubmitBtnState extends State<_SubmitBtn> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() { _hovered = false; _pressed = false; }),
      child: GestureDetector(
        onTap:       widget.onTap,
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) => setState(() => _pressed = false),
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedScale(
          scale:    _pressed ? 0.95 : (_hovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve:    Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve:    Curves.easeOut,
            padding:  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _hovered ? const Color(0xFF004C33) : const Color(0xFF003322),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _hovered ? C.green : const Color(0xFF004433),
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color:      C.green.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset:     const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                color:      C.green,
                fontSize:   13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
