import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jobseeker/core/api_keys.dart';
import 'package:jobseeker/features/models/job.dart';

/// Adzuna job-search integration (US04 feed, US05 search/filter, US06 detail,
/// US09 recommendation candidates).
///
/// Adzuna has no Indonesia endpoint, so [_country] selects the closest
/// supported market. Each query is cached in-memory for 30 minutes to respect
/// the free-tier quota (US05.6).
class AdzunaService {
  AdzunaService._();
  static final AdzunaService instance = AdzunaService._();

  // Supported: gb, us, au, in, sg, ... (NOT 'id'/Indonesia).
  // 'gb' has the richest data for demos; 'sg'/'in' are regionally closer.
  static const String _country = 'gb';
  static const String _base = 'https://api.adzuna.com/v1/api/jobs';

  static const Duration _ttl = Duration(minutes: 30);
  final Map<String, List<Job>> _cache = {};
  final Map<String, DateTime> _cachedAt = {};

  /// Search jobs. [contractType] is one of: full_time, part_time, contract,
  /// permanent (mapped to Adzuna's boolean flags, US05.4).
  Future<List<Job>> searchJobs({
    String? what,
    String? where,
    String? category,
    String? contractType,
    int page = 1,
    int resultsPerPage = 20,
    String sortBy = 'date',
  }) async {
    final params = <String, String>{
      'app_id': ApiKeys.adzunaAppId,
      'app_key': ApiKeys.adzunaAppKey,
      'results_per_page': '$resultsPerPage',
      'sort_by': sortBy,
      if (what != null && what.isNotEmpty) 'what': what,
      if (where != null && where.isNotEmpty) 'where': where,
      if (category != null && category.isNotEmpty) 'category': category,
    };
    if (contractType != null && contractType.isNotEmpty) {
      params[contractType] = '1';
    }

    final uri = Uri.parse('$_base/$_country/search/$page')
        .replace(queryParameters: params);
    final key = uri.toString();

    final cached = _cache[key];
    final at = _cachedAt[key];
    if (cached != null && at != null && DateTime.now().difference(at) < _ttl) {
      return cached;
    }

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      if (cached != null) return cached; // serve stale on error
      throw Exception('Adzuna error ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>? ?? [])
        .map((j) => Job.fromAdzuna(j as Map<String, dynamic>))
        .toList();

    _cache[key] = results;
    _cachedAt[key] = DateTime.now();
    return results;
  }

  /// Valid Adzuna category tags + labels for the filter UI (US05.3). Optional —
  /// the categories can also be hardcoded.
  Future<List<({String tag, String label})>> fetchCategories() async {
    final uri = Uri.parse('$_base/$_country/categories').replace(
      queryParameters: {
        'app_id': ApiKeys.adzunaAppId,
        'app_key': ApiKeys.adzunaAppKey,
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Adzuna categories error ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['results'] as List<dynamic>? ?? [])
        .map((c) => (
              tag: (c['tag'] ?? '').toString(),
              label: (c['label'] ?? '').toString(),
            ))
        .toList();
  }
}
