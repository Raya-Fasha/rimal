import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/form_data.dart';

final _db = Supabase.instance.client;

class ApplicationService {
  ApplicationService._();
  static final ApplicationService instance = ApplicationService._();

  Future<Map<String, dynamic>> createApplication(FormData fd) async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to submit an application.');
    }

    final score = RiskScorer.score(fd);
    final data = {
      'user_id':           user.id,
      'org_name':          fd.orgName.text.trim(),
      'reg_number':        fd.regNumber.text.trim(),
      'contact_person':    fd.contactPerson.text.trim(),
      'email':             fd.email.text.trim(),
      'phone':             fd.phone.text.trim(),
      'website':           fd.website.text.trim(),
      'project_name':      fd.projectName.text.trim(),
      'description':       fd.description.text.trim(),
      'intended_users':    fd.intendedUsers.text.trim(),
      'deploy_region':     fd.deployRegion.text.trim(),
      'dev_stage':         fd.selectedStage,
      'ai_types':          fd.selectedAiTypes.toList(),
      'makes_decisions':   fd.makesDecisions,
      'has_human_oversight': fd.hasHumanOversight,
      'model_type':        fd.modelType.text.trim(),
      'model_description': fd.modelDesc.text.trim(),
      'data_types':        fd.selectedDataTypes.toList(),
      'processes_sensitive': fd.processesSensitiveData,
      'affected_users':    fd.affectedUsers.text.trim(),
      'estimated_user_count': fd.estimatedUsers.text.isEmpty
          ? null
          : int.tryParse(fd.estimatedUsers.text.trim()),
      'selected_risks':      fd.selectedRisks.toList(),
      'risk_mitigation_plan': fd.mitigationPlan.text.trim(),
      'status':              'submitted',
      'risk_score':          score.score,
      'risk_level':          score.level,
      'risk_flags':          score.flags,
      'score_breakdown':     score.breakdown
          .map((item) => {
                'label': item.label,
                'points': item.points,
                'category': item.category,
              })
          .toList(),
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _db
        .from('applications')
        .insert(data)
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to submit the application.');
    }

    final appId = response['id'] as String;

    // Upload documents (best-effort — don't fail the submission if a file upload fails)
    for (final entry in fd.uploadedFiles.entries) {
      final docType = entry.key;
      final fileName = entry.value;
      final bytes = fd.uploadedFileBytes[docType];

      if (fileName != null && bytes != null) {
        try {
          final safeType = docType.replaceAll(' ', '_').toLowerCase();
          final storagePath = '${user.id}/$appId/$safeType.pdf';

          await _db.storage.from('documents').uploadBinary(
            storagePath,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(contentType: 'application/pdf'),
          );

          await _db.from('documents').insert({
            'application_id': appId,
            'doc_type':       docType,
            'file_path':      storagePath,
            'file_name':      fileName,
          });
        } catch (_) {
          // Silently skip failed uploads so the application still saves
        }
      }
    }

    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> fetchApplications({required bool all}) async {
    const cols = 'id, reference_id, org_name, project_name, dev_stage, deploy_region, ai_types, model_type, model_description, risk_score, risk_level, status, risk_flags, selected_risks, data_types, score_breakdown, created_at, submitted_at';

    if (all) {
      final response = await _db
          .from('applications')
          .select(cols)
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } else {
      final user = _db.auth.currentUser;
      if (user == null) {
        throw Exception('You must be signed in to load applications.');
      }
      final response = await _db
          .from('applications')
          .select(cols)
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    }
  }

  Future<Map<String, dynamic>?> getApplicationByReference(String referenceId) async {
    final response = await _db
        .from('applications')
        .select(
            'id, reference_id, org_name, project_name, dev_stage, deploy_region, ai_types, model_type, model_description, risk_score, risk_level, status, risk_flags, selected_risks, data_types, makes_decisions, has_human_oversight, score_breakdown, created_at, submitted_at')
        .eq('reference_id', referenceId)
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  // ── Regulator: submit review decision ─────────────────────────────────────
  Future<void> submitReview({
    required String applicationId,
    required String decision,
    required String assignedRisk,
    String? internalNotes,
  }) async {
    final regulatorId = _db.auth.currentUser?.id;
    if (regulatorId == null) throw Exception('Not signed in.');

    final dbDecision = _mapDecision(decision);

    await _db.from('reviews').insert({
      'application_id': applicationId,
      'regulator_id':   regulatorId,
      'decision':       dbDecision,
      'assigned_risk':  assignedRisk,
      'internal_notes': (internalNotes?.trim().isEmpty ?? true) ? null : internalNotes!.trim(),
      'decided_at':     DateTime.now().toUtc().toIso8601String(),
    });

    await _db
        .from('applications')
        .update({
          'status':     dbDecision,
          'risk_level': assignedRisk,
        })
        .eq('id', applicationId);
  }

  // ── Regulator: send clarification request ─────────────────────────────────
  Future<void> sendClarification({
    required String applicationId,
    required String message,
  }) async {
    final regulatorId = _db.auth.currentUser?.id;
    if (regulatorId == null) throw Exception('Not signed in.');

    await _db.from('clarifications').insert({
      'application_id': applicationId,
      'regulator_id':   regulatorId,
      'message':        message.trim(),
    });

    await _db
        .from('applications')
        .update({'status': 'info_required'})
        .eq('id', applicationId);
  }

  // ── Regulator: schedule a meeting ─────────────────────────────────────────
  Future<void> scheduleMeeting({
    required String applicationId,
    required DateTime proposedAt,
  }) async {
    final regulatorId = _db.auth.currentUser?.id;
    if (regulatorId == null) throw Exception('Not signed in.');

    await _db.from('meetings').insert({
      'application_id': applicationId,
      'regulator_id':   regulatorId,
      'proposed_at':    proposedAt.toUtc().toIso8601String(),
    });
  }

  // ── Documents ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchDocuments(String applicationId) async {
    final rows = await _db
        .from('documents')
        .select('doc_type, file_name')
        .eq('application_id', applicationId)
        .order('doc_type');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _mapDecision(String label) {
    final l = label.toLowerCase();
    if (l.contains('approv'))                              return 'approved';
    if (l.contains('reject'))                              return 'rejected';
    if (l.contains('more') || l.contains('information'))  return 'info_required';
    return 'under_review';
  }
}
