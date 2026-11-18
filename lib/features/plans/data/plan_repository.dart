import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../domain/plan.dart';

class PlanRepository {
  PlanRepository(this.api);
  final ApiClient api;

  Future<ApiResult<List<ActionPlan>>> list() {
    return api.get<List<ActionPlan>>(
      '/action-plans',
      parse: (d) => [
        for (final p in ((d as Map<String, dynamic>)['plans'] as List))
          ActionPlan.fromJson(
            (p as Map<String, dynamic>)['plan'] as Map<String, dynamic>,
            p['tasks'] as List,
            p['opportunity'] as Map<String, dynamic>?,
          ),
      ],
    );
  }

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

  Future<ApiResult<void>> setTaskStatus(String taskId, TaskStatus status) {
    return api.patch<void>(
      '/action-plans/tasks/${Uri.encodeComponent(taskId)}',
      body: {'status': status.wire},
      parse: (_) {},
    );
  }
}
