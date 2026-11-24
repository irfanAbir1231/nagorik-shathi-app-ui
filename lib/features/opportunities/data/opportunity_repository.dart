import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/cached.dart';
import '../domain/opportunity.dart';

class OpportunityRepository {
  OpportunityRepository(this.api);
  final ApiClient api;

  /// `GET /opportunities`. Personalised when signed in: each item carries the
  /// citizen's own eligibility verdict. The answer is kept on the phone.
  Future<ApiResult<OpportunityPage>> list({
    String? query,
    String? category,
    String? outcome,
    int limit = 20,
    int offset = 0,
  }) =>
      api.get<OpportunityPage>(
        '/opportunities',
        query: _listQuery(query, category, outcome, limit, offset),
        parse: _parsePage,
        cached: true,
      );

  /// The phone's copy of the same [list] request, or null.
  Cached<OpportunityPage>? cachedList({
    String? query,
    String? category,
    String? outcome,
    int limit = 20,
    int offset = 0,
  }) =>
      api.peek<OpportunityPage>(
        '/opportunities',
        query: _listQuery(query, category, outcome, limit, offset),
        parse: _parsePage,
      );

  static Map<String, dynamic> _listQuery(String? query, String? category, String? outcome, int limit, int offset) => {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        'category': ?category,
        'outcome': ?outcome,
        'limit': limit,
        'offset': offset,
      };

  static OpportunityPage _parsePage(dynamic data) {
    final map = data as Map<String, dynamic>;
    final counts = map['categoryCounts'];
    return OpportunityPage(
      [for (final i in (map['items'] as List)) OpportunitySummary.fromJson(i as Map<String, dynamic>)],
      categoryCounts: {
        if (counts is Map<String, dynamic>)
          for (final e in counts.entries)
            if (e.value is num) e.key: (e.value as num).toInt(),
      },
    );
  }

  /// `GET /opportunities/:slug` — programme, eligibility trace, documents,
  /// confidence and offices in one request (one round trip on a weak network).
  Future<ApiResult<OpportunityDetail>> detail(String slug) => api.get<OpportunityDetail>(
        '/opportunities/${Uri.encodeComponent(slug)}',
        parse: _parseDetail,
        cached: true,
      );

  /// The phone's copy of [detail], or null.
  Cached<OpportunityDetail>? cachedDetail(String slug) =>
      api.peek<OpportunityDetail>('/opportunities/${Uri.encodeComponent(slug)}', parse: _parseDetail);

  static OpportunityDetail _parseDetail(dynamic data) => OpportunityDetail.fromJson(data as Map<String, dynamic>);
}
