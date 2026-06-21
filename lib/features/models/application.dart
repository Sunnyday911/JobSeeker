import 'package:cloud_firestore/cloud_firestore.dart';

/// One status transition in an application's history (US13.4).
class StatusChange {
  final String status;
  final DateTime at;
  const StatusChange({required this.status, required this.at});

  factory StatusChange.fromMap(Map<String, dynamic> m) => StatusChange(
        status: (m['status'] ?? '').toString(),
        at: (m['at'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> toMap() => {'status': status, 'at': Timestamp.fromDate(at)};
}

/// A recorded job application (US12–US14). Combined schema: applicant bio +
/// job reference + apply date + status workflow.
class Application {
  final String id;
  final String userId;
  final String? jobId;
  final String jobTitle;
  final String company;
  final String fullName;
  final String dateOfBirth;
  final String address;
  final String phone;
  final String status;
  final List<StatusChange> statusHistory;
  final String notes;
  final DateTime? appliedAt;
  final DateTime? updatedAt;

  const Application({
    required this.id,
    required this.userId,
    required this.jobTitle,
    required this.company,
    required this.fullName,
    required this.dateOfBirth,
    required this.address,
    required this.phone,
    required this.status,
    required this.statusHistory,
    this.jobId,
    this.notes = '',
    this.appliedAt,
    this.updatedAt,
  });

  factory Application.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Application(
      id: doc.id,
      userId: (d['userId'] ?? '').toString(),
      jobId: d['jobId']?.toString(),
      jobTitle: (d['jobTitle'] ?? '').toString(),
      company: (d['company'] ?? '').toString(),
      fullName: (d['fullName'] ?? '').toString(),
      dateOfBirth: (d['dateOfBirth'] ?? '').toString(),
      address: (d['address'] ?? '').toString(),
      phone: (d['phone'] ?? '').toString(),
      status: (d['status'] ?? 'Dikirim').toString(),
      statusHistory: (d['statusHistory'] as List<dynamic>? ?? [])
          .map((e) => StatusChange.fromMap(e as Map<String, dynamic>))
          .toList(),
      notes: (d['notes'] ?? '').toString(),
      appliedAt: (d['appliedAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'company': company,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'phone': phone,
        'status': status,
        'statusHistory': statusHistory.map((s) => s.toMap()).toList(),
        'notes': notes,
        'appliedAt':
            appliedAt != null ? Timestamp.fromDate(appliedAt!) : Timestamp.now(),
        'updatedAt':
            updatedAt != null ? Timestamp.fromDate(updatedAt!) : Timestamp.now(),
      };
}
