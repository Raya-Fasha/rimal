import 'package:flutter/material.dart';

// ── Form Data Model ────────────────────────────────────────────────────────
class FormData {
  // Step 1 — Organisation
  final orgName       = TextEditingController();
  final regNumber     = TextEditingController();
  final contactPerson = TextEditingController();
  final email         = TextEditingController();
  final phone         = TextEditingController();
  final website       = TextEditingController();

  // Step 2 — Project
  final projectName   = TextEditingController();
  final description   = TextEditingController();
  final intendedUsers = TextEditingController();
  final deployRegion  = TextEditingController();
  String? selectedStage;

  // Step 3 — AI System
  final modelType  = TextEditingController();
  final modelDesc  = TextEditingController();
  Set<String> selectedAiTypes = {};
  bool? makesDecisions;
  bool? hasHumanOversight;

  // Step 4 — Risk & Data
  final affectedUsers  = TextEditingController();
  final estimatedUsers = TextEditingController();
  final mitigationPlan = TextEditingController();
  Set<String> selectedDataTypes = {};
  Set<String> selectedRisks     = {};
  bool? processesSensitiveData;

  // Step 5 — uploaded file names and raw bytes
  Map<String, String?> uploadedFiles = {
    'Project brief': null,
    'Model documentation': null,
    'Compliance documentation': null,
    'Testing report': null,
    'Data sheet': null,
    'Additional attachments': null,
  };

  Map<String, List<int>?> uploadedFileBytes = {
    'Project brief': null,
    'Model documentation': null,
    'Compliance documentation': null,
    'Testing report': null,
    'Data sheet': null,
    'Additional attachments': null,
  };

  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
  }

  List<TextEditingController> get _controllers => [
        orgName, regNumber, contactPerson, email, phone, website,
        projectName, description, intendedUsers, deployRegion,
        modelType, modelDesc,
        affectedUsers, estimatedUsers, mitigationPlan,
      ];

  void reset() {
    for (final c in _controllers) {
      c.clear();
    }
    selectedStage        = null;
    selectedAiTypes      = {};
    makesDecisions       = null;
    hasHumanOversight    = null;
    selectedDataTypes    = {};
    selectedRisks        = {};
    processesSensitiveData = null;
    uploadedFiles = {
      'Project brief': null,
      'Model documentation': null,
      'Compliance documentation': null,
      'Testing report': null,
      'Data sheet': null,
      'Additional attachments': null,
    };
    uploadedFileBytes = {
      'Project brief': null,
      'Model documentation': null,
      'Compliance documentation': null,
      'Testing report': null,
      'Data sheet': null,
      'Additional attachments': null,
    };
  }

  // ── Per-step validation ──────────────────────────────────────────────────
  /// Returns null if valid, or an error key to look up in translations.
  String? validateStep(int step) {
    switch (step) {
      case 1:
        if (orgName.text.trim().isEmpty ||
            contactPerson.text.trim().isEmpty ||
            email.text.trim().isEmpty) {
          return 'form_validation_required';
        }
        if (regNumber.text.trim().isNotEmpty &&
            !RegExp(r'^[A-Za-z0-9\-]{4,20}$').hasMatch(regNumber.text.trim())) {
          return 'form_validation_reg_number';
        }
        final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
            .hasMatch(email.text.trim());
        if (!emailOk) return 'form_validation_email';
        return null;
      case 2:
        if (projectName.text.trim().isEmpty ||
            description.text.trim().isEmpty) {
          return 'form_validation_required';
        }
        if (selectedStage == null) return 'form_validation_select';
        return null;
      case 3:
        if (selectedAiTypes.isEmpty) return 'form_validation_select';
        if (makesDecisions == null || hasHumanOversight == null) {
          return 'form_validation_select';
        }
        return null;
      case 4:
        if (selectedDataTypes.isEmpty || processesSensitiveData == null) {
          return 'form_validation_select';
        }
        return null;
      default:
        return null;
    }
  }
}

// ── Score Breakdown ────────────────────────────────────────────────────────
class ScoreBreakdownItem {
  final String label;
  final int points;
  final String category;
  const ScoreBreakdownItem({
    required this.label,
    required this.points,
    required this.category,
  });
}

class RiskResult {
  final int score;
  final String level; // 'Low' | 'Medium' | 'High'
  final List<int> flags;
  final List<ScoreBreakdownItem> breakdown;

  const RiskResult({
    required this.score,
    required this.level,
    required this.flags,
    required this.breakdown,
  });
}

// ── Risk Scoring Engine ────────────────────────────────────────────────────
class RiskScorer {
  static RiskResult score(FormData fd) {
    final items = <ScoreBreakdownItem>[];

    // Sector
    final sectorRaw = '${fd.description.text} ${fd.projectName.text} ${fd.deployRegion.text}'.toLowerCase();
    int sectorPts = 0;
    String sectorLabel = 'Other sector';

    if (_has(sectorRaw, ['health', 'medical', 'clinic', 'hospital', 'patient'])) {
      sectorPts = 30; sectorLabel = 'Healthcare sector';
    } else if (_has(sectorRaw, ['financ', 'bank', 'loan', 'credit', 'invest', 'payment'])) {
      sectorPts = 25; sectorLabel = 'Finance sector';
    } else if (_has(sectorRaw, ['government', 'citizen', 'public service', 'ministry', 'municipal'])) {
      sectorPts = 20; sectorLabel = 'Public services sector';
    } else if (_has(sectorRaw, ['transport', 'traffic', 'vehicle', 'road', 'transit'])) {
      sectorPts = 15; sectorLabel = 'Transportation sector';
    } else if (_has(sectorRaw, ['legal', 'justice', 'court', 'law', 'judicial'])) {
      sectorPts = 20; sectorLabel = 'Legal & Justice sector';
    } else if (_has(sectorRaw, ['educat', 'school', 'student', 'learn', 'university'])) {
      sectorPts = 10; sectorLabel = 'Education sector';
    } else if (_has(sectorRaw, ['agricult', 'farm', 'crop', 'soil'])) {
      sectorPts = 5; sectorLabel = 'Agriculture sector';
    } else if (_has(sectorRaw, ['energy', 'power', 'electric', 'solar', 'grid'])) {
      sectorPts = 10; sectorLabel = 'Energy sector';
    }

    if (sectorPts > 0) {
      items.add(ScoreBreakdownItem(label: sectorLabel, points: sectorPts, category: 'Sector'));
    }

    // Data sensitivity
    int dataPts = 0;
    if (fd.selectedDataTypes.contains('Biometric data') || fd.selectedDataTypes.contains('بيانات بيومترية')) {
      dataPts = 30;
      items.add(const ScoreBreakdownItem(label: 'Biometric data used', points: 30, category: 'Data'));
    } else if (fd.selectedDataTypes.contains('Health data') || fd.selectedDataTypes.contains('بيانات صحية')) {
      dataPts = 25;
      items.add(const ScoreBreakdownItem(label: 'Health data used', points: 25, category: 'Data'));
    } else if (fd.selectedDataTypes.contains('Personal data') || fd.selectedDataTypes.contains('بيانات شخصية') ||
               fd.selectedDataTypes.contains('Financial data') || fd.selectedDataTypes.contains('بيانات مالية')) {
      dataPts = 20;
      items.add(const ScoreBreakdownItem(label: 'Personal / financial data used', points: 20, category: 'Data'));
    } else if (fd.selectedDataTypes.contains('Government data') || fd.selectedDataTypes.contains('بيانات حكومية')) {
      dataPts = 15;
      items.add(const ScoreBreakdownItem(label: 'Government data used', points: 15, category: 'Data'));
    } else if (fd.selectedDataTypes.contains('Anonymized data') || fd.selectedDataTypes.contains('بيانات مجهولة') ||
               fd.selectedDataTypes.contains('Public data') || fd.selectedDataTypes.contains('بيانات عامة')) {
      dataPts = 5;
      items.add(const ScoreBreakdownItem(label: 'Anonymized / public data only', points: 5, category: 'Data'));
    }

    // Autonomy
    int autonomyPts = 0;
    if (fd.makesDecisions == true && fd.hasHumanOversight == false) {
      autonomyPts = 25;
      items.add(const ScoreBreakdownItem(label: 'Fully automated decisions', points: 25, category: 'Autonomy'));
    } else if (fd.makesDecisions == true && fd.hasHumanOversight == true) {
      autonomyPts = 10;
      items.add(const ScoreBreakdownItem(label: 'Decision support with human oversight', points: 10, category: 'Autonomy'));
    } else if (fd.makesDecisions == false) {
      autonomyPts = 5;
      items.add(const ScoreBreakdownItem(label: 'Human approval required', points: 5, category: 'Autonomy'));
    }

    // Sensitive data bonus
    if (fd.processesSensitiveData == true) {
      items.add(const ScoreBreakdownItem(label: 'Processes sensitive personal data', points: 10, category: 'Data'));
      dataPts += 10;
    }

    // Risk bonuses
    int riskBonus = 0;
    if (fd.selectedRisks.contains('Privacy') || fd.selectedRisks.contains('خصوصية')) {
      riskBonus += 5;
      items.add(const ScoreBreakdownItem(label: 'Privacy risk identified', points: 5, category: 'Risks'));
    }
    if (fd.selectedRisks.contains('Safety') || fd.selectedRisks.contains('سلامة')) {
      riskBonus += 5;
      items.add(const ScoreBreakdownItem(label: 'Safety risk identified', points: 5, category: 'Risks'));
    }
    if (fd.selectedRisks.contains('Bias') || fd.selectedRisks.contains('تحيز')) {
      riskBonus += 3;
      items.add(const ScoreBreakdownItem(label: 'Bias risk identified', points: 3, category: 'Risks'));
    }
    if (fd.selectedRisks.contains('Cybersecurity') || fd.selectedRisks.contains('أمن إلكتروني')) {
      riskBonus += 3;
      items.add(const ScoreBreakdownItem(label: 'Cybersecurity risk identified', points: 3, category: 'Risks'));
    }

    // AI type bonus
    if (fd.selectedAiTypes.contains('Biometric Recognition') || fd.selectedAiTypes.contains('التعرف البيومتري')) {
      items.add(const ScoreBreakdownItem(label: 'Biometric recognition AI', points: 8, category: 'AI Type'));
      riskBonus += 8;
    } else if (fd.selectedAiTypes.contains('Generative AI') || fd.selectedAiTypes.contains('ذكاء توليدي')) {
      items.add(const ScoreBreakdownItem(label: 'Generative AI system', points: 5, category: 'AI Type'));
      riskBonus += 5;
    }

    final rawScore  = sectorPts + dataPts + autonomyPts + riskBonus;
    final finalScore = rawScore.clamp(0, 100);

    final String level;
    if (finalScore >= 61) {
      level = 'High';
    } else if (finalScore >= 31) level = 'Medium';
    else                       level = 'Low';

    final flags = <int>[];
    if (fd.selectedDataTypes.contains('Personal data') || fd.selectedDataTypes.contains('بيانات شخصية') ||
        fd.selectedDataTypes.contains('Biometric data') || fd.selectedDataTypes.contains('بيانات بيومترية') ||
        fd.processesSensitiveData == true) {
      flags.add(0);
    }
    if (fd.makesDecisions == true && fd.hasHumanOversight != true) flags.add(1);
    if (fd.selectedRisks.contains('Safety') || fd.selectedRisks.contains('سلامة')) flags.add(2);
    if (fd.selectedRisks.contains('Bias')   || fd.selectedRisks.contains('تحيز'))   flags.add(3);

    return RiskResult(
      score: finalScore,
      level: level,
      flags: flags,
      breakdown: items,
    );
  }

  static bool _has(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}
