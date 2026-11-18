import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../domain/opportunity.dart';

class OpportunityRepository {
  OpportunityRepository(this.api);
  final ApiClient api;

  /// `GET /opportunities`. Personalised when signed in: each item carries the
  /// citizen's own eligibility verdict.
  Future<ApiResult<OpportunityPage>> list({
    String? query,
    String? category,
    String? outcome,
    int limit = 20,
    int offset = 0,
  }) {
    return api.get<OpportunityPage>(
      '/opportunities',
      query: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        'category': ?category,
        'outcome': ?outcome,
        'limit': limit,
        'offset': offset,
      },
      parse: (data) {
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
      },
    );
  }

  /// `GET /opportunities/:slug` — programme, eligibility trace, documents,
  /// confidence and offices in one request (one round trip on a weak network).
  Future<ApiResult<OpportunityDetail>> detail(String slug) {
    return api.get<OpportunityDetail>(
      '/opportunities/${Uri.encodeComponent(slug)}',
      parse: (data) => OpportunityDetail.fromJson(data as Map<String, dynamic>),
    );
  }
}
