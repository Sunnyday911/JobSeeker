/// A Claude-generated job match for the current CV profile (US09).
class JobRecommendation {
  final String jobId;
  final int matchScore; // 0-100 (US09.3)
  final List<String> skillGap; // skills the job needs that the user lacks (US09.5)

  const JobRecommendation({
    required this.jobId,
    required this.matchScore,
    required this.skillGap,
  });

  factory JobRecommendation.fromJson(Map<String, dynamic> j) => JobRecommendation(
        jobId: (j['jobId'] ?? '').toString(),
        matchScore: (j['matchScore'] as num?)?.round() ?? 0,
        skillGap: (j['skillGap'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'matchScore': matchScore,
        'skillGap': skillGap,
      };
}
