import 'dart:developer' as developer;

import 'package:poms/features/nurse/domain/models/assessment_detail.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Individual question answer
// ─────────────────────────────────────────────────────────────────────────────

class AssessmentDetailItemResponse {
  const AssessmentDetailItemResponse({
    required this.questionId,
    required this.questionText,
    required this.selectedOptionId,
    required this.optionText,
    required this.scoreEarned,
  });

  final int questionId;
  final String questionText;
  final int selectedOptionId;
  final String optionText;
  final int scoreEarned;

  // ignore: sort_constructors_first
  factory AssessmentDetailItemResponse.fromJson(Map<String, dynamic> json) {
    return AssessmentDetailItemResponse(
      questionId: _parseInt(json['questionId']) ?? 0,
      questionText: (json['questionText'] as String?) ?? '',
      selectedOptionId: _parseInt(json['selectedOptionId']) ?? 0,
      optionText: (json['optionText'] as String?) ?? '',
      scoreEarned: _parseInt(json['scoreEarned']) ?? 0,
    );
  }

  AssessmentDetailItem toDomain() {
    return AssessmentDetailItem(
      questionId: questionId,
      questionText: questionText,
      selectedOptionId: selectedOptionId,
      optionText: optionText,
      scoreEarned: scoreEarned,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single assessment record
// ─────────────────────────────────────────────────────────────────────────────

class AssessmentDetailResponse {
  const AssessmentDetailResponse({
    required this.assessmentId,
    required this.caseId,
    required this.evaluationDateTime,
    required this.podContext,
    required this.totalScore,
    required this.triageColor,
    required this.details,
  });

  final int assessmentId;
  final String caseId;
  final DateTime evaluationDateTime;
  final int podContext;
  final int totalScore;
  final String triageColor;
  final List<AssessmentDetailItemResponse> details;

  // ignore: sort_constructors_first
  factory AssessmentDetailResponse.fromJson(Map<String, dynamic> json) {
    // evaluationDatetime (lowercase t) is the canonical backend field name.
    // Also accept evaluationDateTime (uppercase T) as fallback.
    final rawDate =
        json['evaluationDatetime'] as String? ??
        json['evaluationDateTime'] as String? ??
        json['created_at'] as String? ??
        json['createdAt'] as String?;

    DateTime evaluationDateTime;
    try {
      evaluationDateTime = rawDate != null
          ? DateTime.parse(rawDate)
          : DateTime.now();
    } catch (_) {
      evaluationDateTime = DateTime.now();
    }

    // details field — tolerate null or absent.
    final rawDetails = json['details'];
    final List<AssessmentDetailItemResponse> details;
    if (rawDetails is List) {
      details = rawDetails
          .whereType<Map<String, dynamic>>()
          .map(AssessmentDetailItemResponse.fromJson)
          .toList();
    } else {
      details = [];
    }

    return AssessmentDetailResponse(
      assessmentId: _parseInt(json['assessmentId']) ?? 0,
      caseId: (json['caseId'] as String?) ?? '',
      evaluationDateTime: evaluationDateTime,
      podContext: _parseInt(json['podContext']) ?? 0,
      totalScore: _parseInt(json['totalScore']) ?? 0,
      triageColor: (json['triageColor'] as String?) ?? 'GREEN',
      details: details,
    );
  }

  AssessmentDetail toDomain() {
    return AssessmentDetail(
      assessmentId: assessmentId,
      caseId: caseId,
      evaluationDateTime: evaluationDateTime,
      podContext: podContext,
      totalScore: totalScore,
      triageColor: triageColor,
      details: details.map((e) => e.toDomain()).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History list wrapper — handles multiple backend response shapes
// ─────────────────────────────────────────────────────────────────────────────

class AssessmentHistoryResponse {
  const AssessmentHistoryResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  /// Safely parses any of these shapes:
  ///   1. Paginated map : { "data": [...], "total": n, "page": n, "limit": n }
  ///   2. Direct array  : [ {...}, {...} ]
  ///   3. Alternate key : { "assessments": [...] } / "items" / "records"
  factory AssessmentHistoryResponse.fromRaw(dynamic raw) {
    try {
      // Shape 2 — bare array
      if (raw is List) {
        return AssessmentHistoryResponse(
          data: _parseItems(raw),
          total: raw.length,
          page: 1,
          limit: raw.length,
        );
      }

      if (raw is Map<String, dynamic>) {
        // Shape 1 — { data: [...] }
        if (raw['data'] is List) {
          final items = _parseItems(raw['data'] as List);
          return AssessmentHistoryResponse(
            data: items,
            total: _parseInt(raw['total']) ?? items.length,
            page: _parseInt(raw['page']) ?? 1,
            limit: _parseInt(raw['limit']) ?? items.length,
          );
        }

        // Shape 3 — alternate key
        for (final key in ['assessments', 'items', 'records', 'results']) {
          if (raw[key] is List) {
            final items = _parseItems(raw[key] as List);
            return AssessmentHistoryResponse(
              data: items,
              total: _parseInt(raw['total']) ?? items.length,
              page: _parseInt(raw['page']) ?? 1,
              limit: _parseInt(raw['limit']) ?? items.length,
            );
          }
        }
      }
    } catch (e, st) {
      developer.log(
        'AssessmentHistoryResponse.fromRaw error: $e',
        name: 'AssessmentHistoryResponse',
        error: e,
        stackTrace: st,
      );
    }

    return const AssessmentHistoryResponse(data: [], total: 0, page: 1, limit: 50);
  }

  /// Legacy compatibility alias.
  factory AssessmentHistoryResponse.fromJson(Map<String, dynamic> json) =>
      AssessmentHistoryResponse.fromRaw(json);

  final List<AssessmentDetailResponse> data;
  final int total;
  final int page;
  final int limit;

  static List<AssessmentDetailResponse> _parseItems(List<dynamic> list) {
    final result = <AssessmentDetailResponse>[];
    for (final e in list) {
      if (e is Map<String, dynamic>) {
        try {
          result.add(AssessmentDetailResponse.fromJson(e));
        } catch (err) {
          developer.log(
            'Skipping unparseable assessment item: $err\nRaw: $e',
            name: 'AssessmentHistoryResponse',
          );
        }
      }
    }
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
