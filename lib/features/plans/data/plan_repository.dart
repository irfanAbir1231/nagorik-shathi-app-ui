import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/cached.dart';
import '../domain/plan.dart';

class PlanRepository {
  PlanRepository(this.api);
  final ApiClient api;

  Future<ApiResult<List<ActionPlan>>> list() =>
      api.get<List<ActionPlan>>('/action-plans', parse: _parse, cached: true);

  /// The phone's copy of [list], or null.
  Cached<List<ActionPlan>>? cachedList() => api.peek<List<ActionPlan>>('/action-plans', parse: _parse);

  static List<ActionPlan> _parse(dynamic d) => [
        for (final p in ((d as Map<String, dynamic>)['plans'] as List))
          ActionPlan.fromJson(
            (p as Map<String, dynamic>)['plan'] as Map<String, dynamic>,
            p['tasks'] as List,
            p['opportunity'] as Map<String, dynamic>?,
          ),
      ];

  /// `POST /action-plans` — builds a checklist from the programme's own
  /// application steps and documents. Returns the existing plan if there is one.
  Future<ApiResult<ActionPlan>> create(String opportunityId) {
    return api.post<ActionPlan>(
      '/action-plans',
      body: {'opportunityId': opportunityId},
      parse: (d) {
        final map = d as Map<String, dynamic>;
        return ActionPlan.fromJson(map['plan'] as Map<String, dynamic>, map['tasks'] as List);
      },
    );
  }

  Future<ApiResult<void>> setTaskStatus(String taskId, TaskStatus status) async {
    final result = await api.patch<void>(
      '/action-plans/tasks/${Uri.encodeComponent(taskId)}',
      body: {'status': status.wire},
      parse: (_) {},
    );
    // Keep the phone's copy in step, so the next launch shows the tick.
    if (result is Ok<void>) {
      api.patchCached('/action-plans', (d) {
        final map = Map<String, dynamic>.of(d as Map<String, dynamic>);
        map['plans'] = [
          for (final p in (map['plans'] as List))
            {
              ...(p as Map<String, dynamic>),
              'tasks': [
                for (final t in (p['tasks'] as List))
                  (t as Map<String, dynamic>)['id'] == taskId ? {...t, 'status': status.wire} : t,
              ],
            },
        ];
        return map;
      });
    }
    return result;
  }
}
