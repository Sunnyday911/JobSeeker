/// Result of Claude CV analysis (US08): the extracted profile, NOT the raw CV.
class CvProfile {
  final List<String> skills;
  final String experienceLevel;
  final String summary;

  const CvProfile({
    required this.skills,
    required this.experienceLevel,
    required this.summary,
  });

  factory CvProfile.fromJson(Map<String, dynamic> j) => CvProfile(
        skills: (j['skills'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        experienceLevel: (j['experienceLevel'] ?? '').toString(),
        summary: (j['summary'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'skills': skills,
        'experienceLevel': experienceLevel,
        'summary': summary,
      };
}
