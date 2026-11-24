import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/cached.dart';
import '../domain/saved.dart';

class SavedRepository {
  SavedRepository(this.api);
  final ApiClient api;

  Future<ApiResult<List<SavedItem>>> list() => api.get<List<SavedItem>>('/saved', parse: _parse, cached: true);

  /// The phone's copy of [list], or null.
  Cached<List<SavedItem>>? cachedList() => api.peek<List<SavedItem>>('/saved', parse: _parse);

  static List<SavedItem> _parse(dynamic d) => [
        for (final i in ((d as Map<String, dynamic>)['items'] as List)) SavedItem.fromJson(i as Map<String, dynamic>),
      ];

  /// Applies an accepted change to the phone's copy of [list], so the next
  /// launch opens with it rather than with the list from before.
  void _patchItems(Iterable<Object?> Function(List<Object?> items) change) => api.patchCached('/saved', (d) {
        final map = Map<String, dynamic>.of(d as Map<String, dynamic>);
        map['items'] = change(List<Object?>.of(map['items'] as List)).toList();
        return map;
      });

  static String? _savedId(Object? item) =>
      ((item as Map<String, dynamic>)['saved'] as Map<String, dynamic>)['id'] as String?;

  /// `POST /saved` — idempotent: saving twice returns the existing record.
  Future<ApiResult<String>> save(String opportunityId, {SavedStatus status = SavedStatus.interested, String? note}) {
    return api.post<String>(
      '/saved',
      body: {'opportunityId': opportunityId, 'status': status.wire, 'note': ?note},
      parse: (d) => ((d as Map<String, dynamic>)['saved'] as Map<String, dynamic>)['id'] as String,
    );
  }

  Future<ApiResult<void>> setStatus(String savedId, SavedStatus status) async {
    final result =
        await api.patch<void>('/saved/${Uri.encodeComponent(savedId)}', body: {'status': status.wire}, parse: (_) {});
    if (result is Ok<void>) {
      _patchItems((items) => [
            for (final i in items)
              if (_savedId(i) == savedId)
                {
                  ...(i as Map<String, dynamic>),
                  'saved': {...(i['saved'] as Map<String, dynamic>), 'status': status.wire},
                }
              else
                i,
          ]);
    }
    return result;
  }

  Future<ApiResult<void>> remove(String savedId) async {
    final result = await api.delete<void>('/saved/${Uri.encodeComponent(savedId)}', parse: (_) {});
    if (result is Ok<void>) _patchItems((items) => items.where((i) => _savedId(i) != savedId));
    return result;
  }
}
