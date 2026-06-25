/// A Claude-generated job match for the current CV profile (US09).
class JobRecommendation {
  final String jobId;
  final int matchScore; // 0-100 (US09.3)
  final List<String> skillGap; // skills the job needs that the user lacks (US09.5)
  final String? jobTitle; // enriched on save so the dashboard can show it (US15.3)
  final String? company;

  const JobRecommendation({
    required this.jobId,
    required this.matchScore,
    required this.skillGap,
    this.jobTitle,
    this.company,
  });

  factory JobRecommendation.fromJson(Map<String, dynamic> j) => JobRecommendation(
        jobId: (j['jobId'] ?? '').toString(),
        matchScore: (j['matchScore'] as num?)?.round() ?? 0,
        skillGap: (j['skillGap'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        jobTitle: j['jobTitle']?.toString(),
        company: j['company']?.toString(),
      );

  JobRecommendation copyWith({String? jobTitle, String? company}) =>
      JobRecommendation(
        jobId: jobId,
        matchScore: matchScore,
        skillGap: skillGap,
        jobTitle: jobTitle ?? this.jobTitle,
        company: company ?? this.company,
      );

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'matchScore': matchScore,
        'skillGap': skillGap,
        if (jobTitle != null) 'jobTitle': jobTitle,
        if (company != null) 'company': company,
      };
}
