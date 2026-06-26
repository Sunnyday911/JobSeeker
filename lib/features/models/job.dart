import 'package:cloud_firestore/cloud_firestore.dart';

/// A job listing from the Adzuna API (US04/US05/US06).
///
/// Adzuna's search endpoint returns full job objects, so there is no separate
/// "get by id" call — the detail screen reuses the object from the list.
class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final double? salaryMin;
  final double? salaryMax;
  final String? category;
  final String description;
  final DateTime? created;
  final String? redirectUrl;
  final String? contractTime; // full_time / part_time
  final String? contractType; // permanent / contract
  final String? note; // user's personal note on a saved job (US07 UPDATE)
  final String? ownerId; // company `createdBy` uid (Change Plan 2.0); null for Adzuna

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    this.salaryMin,
    this.salaryMax,
    this.category,
    this.created,
    this.redirectUrl,
    this.contractTime,
    this.contractType,
    this.note,
    this.ownerId,
  });

  factory Job.fromAdzuna(Map<String, dynamic> j) {
    double? toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    return Job(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? 'Untitled').toString(),
      company: (j['company']?['display_name'] ?? 'Unknown').toString(),
      location: (j['location']?['display_name'] ?? '-').toString(),
      description: (j['description'] ?? '').toString(),
      salaryMin: toDouble(j['salary_min']),
      salaryMax: toDouble(j['salary_max']),
      category: j['category']?['label']?.toString(),
      created: DateTime.tryParse((j['created'] ?? '').toString()),
      redirectUrl: j['redirect_url']?.toString(),
      contractTime: j['contract_time']?.toString(),
      contractType: j['contract_type']?.toString(),
    );
  }

  /// Serializes for Firestore (saved jobs, US07) — Adzuna has no get-by-id, so
  /// the full object is stored.
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'company': company,
        'location': location,
        'description': description,
        'salaryMin': salaryMin,
        'salaryMax': salaryMax,
        'category': category,
        'created': created?.toIso8601String(),
        'redirectUrl': redirectUrl,
        'contractTime': contractTime,
        'contractType': contractType,
        'note': note,
      };

  factory Job.fromMap(Map<String, dynamic> m) => Job(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? 'Untitled').toString(),
        company: (m['company'] ?? 'Unknown').toString(),
        location: (m['location'] ?? '-').toString(),
        description: (m['description'] ?? '').toString(),
        salaryMin: (m['salaryMin'] as num?)?.toDouble(),
        salaryMax: (m['salaryMax'] as num?)?.toDouble(),
        category: m['category']?.toString(),
        created: m['created'] != null
            ? DateTime.tryParse(m['created'].toString())
            : null,
        redirectUrl: m['redirectUrl']?.toString(),
        contractTime: m['contractTime']?.toString(),
        contractType: m['contractType']?.toString(),
        note: m['note']?.toString(),
      );

  /// Adapts an internal company `jobs` Firestore doc into a [Job] so internal
  /// postings reuse the same detail + apply flow (#3 integration).
  factory Job.fromCompanyMap(String id, Map<String, dynamic> m) {
    final salaryNum = double.tryParse(
        (m['salary'] ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), ''));
    return Job(
      id: id,
      title: (m['title'] ?? 'Untitled').toString(),
      company: (m['company'] ?? 'Unknown').toString(),
      location: (m['location'] ?? '-').toString(),
      description: (m['description'] ?? '').toString(),
      salaryMin: salaryNum,
      category: m['category']?.toString(),
      created: (m['created_at'] as Timestamp?)?.toDate(),
      ownerId: m['createdBy']?.toString(),
    );
  }

  /// Human-readable salary range for cards/detail (US04.2/US06.2).
  String get salaryRange {
    String fmt(double v) => v.round().toString();
    if (salaryMin != null && salaryMax != null) {
      return '${fmt(salaryMin!)} - ${fmt(salaryMax!)}';
    }
    if (salaryMin != null || salaryMax != null) {
      return fmt((salaryMin ?? salaryMax)!);
    }
    return 'Salary not specified';
  }
}
