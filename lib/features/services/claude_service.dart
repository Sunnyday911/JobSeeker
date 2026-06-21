import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jobseeker/core/api_keys.dart';
import 'package:jobseeker/features/models/cv_profile.dart';
import 'package:jobseeker/features/models/job.dart';
import 'package:jobseeker/features/models/job_recommendation.dart';

/// Claude (Anthropic) integration for CV analysis (US08) and AI job
/// recommendations (US09). Uses raw HTTP — Flutter has no official SDK.
///
/// NOTE: calling Anthropic directly from a client exposes the key in the app
/// binary; for production, proxy via a Cloud Function. Web builds will also hit
/// CORS — this path targets the mobile (Android/iOS) build.
class ClaudeService {
  ClaudeService._();
  static final ClaudeService instance = ClaudeService._();

  static const String _endpoint = 'https://api.anthropic.com/v1/messages';

  // Default per Anthropic guidance. Cheaper options if cost matters:
  // 'claude-haiku-4-5' ($1/$5 per MTok) or 'claude-sonnet-4-6' ($3/$15),
  // vs Opus 4.8 ($5/$25).
  static const String _model = 'claude-opus-4-8';

  Map<String, String> get _headers => {
        'x-api-key': ApiKeys.anthropic,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      };

  /// Sends a request that uses output_config.format, then returns the JSON the
  /// model produced (the first text block holds valid JSON).
  Future<Map<String, dynamic>> _sendJson(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(_endpoint),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('Claude error ${res.statusCode}: ${res.body}');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (decoded['stop_reason'] == 'refusal') {
      throw Exception('Claude declined the request.');
    }
    final content = decoded['content'] as List<dynamic>;
    final text =
        content.firstWhere((b) => b['type'] == 'text')['text'] as String;
    return jsonDecode(text) as Map<String, dynamic>;
  }

  /// Extracts skills, experience level, and a profile summary from CV text (US08).
  Future<CvProfile> analyzeCv(String cvText) async {
    final json = await _sendJson({
      'model': _model,
      'max_tokens': 1024,
      'output_config': {
        'format': {
          'type': 'json_schema',
          'schema': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['skills', 'experienceLevel', 'summary'],
            'properties': {
              'skills': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'experienceLevel': {'type': 'string'},
              'summary': {'type': 'string'},
            },
          },
        },
      },
      'messages': [
        {
          'role': 'user',
          'content':
              'Extract the candidate skill list, overall experience level '
                  '(one of: Fresh Graduate, Junior, Mid-level, Senior), and a '
                  'short profile summary from this CV.\n\n$cvText',
        },
      ],
    });
    return CvProfile.fromJson(json);
  }

  /// Ranks jobs against a CV profile, returning match scores + skill gaps (US09).
  Future<List<JobRecommendation>> rankJobs(
    CvProfile profile,
    List<Job> jobs,
  ) async {
    final jobList = jobs.take(10).map((j) {
      final desc = j.description.length > 600
          ? j.description.substring(0, 600)
          : j.description;
      return {
        'id': j.id,
        'title': j.title,
        'company': j.company,
        'description': desc,
      };
    }).toList();

    final json = await _sendJson({
      'model': _model,
      'max_tokens': 2048,
      'output_config': {
        'format': {
          'type': 'json_schema',
          'schema': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['recommendations'],
            'properties': {
              'recommendations': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'additionalProperties': false,
                  'required': ['jobId', 'matchScore', 'skillGap'],
                  'properties': {
                    'jobId': {'type': 'string'},
                    'matchScore': {'type': 'integer'},
                    'skillGap': {
                      'type': 'array',
                      'items': {'type': 'string'},
                    },
                  },
                },
              },
            },
          },
        },
      },
      'messages': [
        {
          'role': 'user',
          'content': 'Candidate profile:\n'
              'Skills: ${profile.skills.join(', ')}\n'
              'Experience: ${profile.experienceLevel}\n'
              'Summary: ${profile.summary}\n\n'
              'For each job below, return a matchScore (0-100) for how well the '
              'candidate fits and the skillGap (skills the job needs that the '
              'candidate lacks). Jobs:\n${jsonEncode(jobList)}',
        },
      ],
    });

    return (json['recommendations'] as List<dynamic>? ?? [])
        .map((r) => JobRecommendation.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
