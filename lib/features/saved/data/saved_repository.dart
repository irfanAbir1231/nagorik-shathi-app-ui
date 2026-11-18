import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../domain/saved.dart';

class SavedRepository {
  SavedRepository(this.api);
  final ApiClient api;

  Future<ApiResult<List<SavedItem>>> list() {
    return api.get<List<SavedItem>>(
      '/saved',
      parse: (d) => [
        for (final i in ((d as Map<String, dynamic>)['items'] as List)) SavedItem.fromJson(i as Map<String, dynamic>),
      ],
    );
  }

  /// `POST /saved` — idempotent: saving twice returns the existing record.
  Future<ApiResult<String>> save(String opportunityId, {SavedStatus status = SavedStatus.interested, String? note}) {
    return api.post<String>(
      '/saved',
      body: {'opportunityId': opportunityId, 'status': status.wire, 'note': ?note},
      parse: (d) => ((d as Map<String, dynamic>)['saved'] as Map<String, dynamic>)['id'] as String,
    );
  }

  Future<ApiResult<void>> setStatus(String savedId, SavedStatus status) {
    return api.patch<void>('/saved/${Uri.encodeComponent(savedId)}', body: {'status': status.wire}, parse: (_) {});
  }

  Future<ApiResult<void>> remove(String savedId) {
    return api.delete<void>('/saved/${Uri.encodeComponent(savedId)}', parse: (_) {});
  }
}
