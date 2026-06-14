import 'package:equatable/equatable.dart';
import 'package:mongez/features/workers/data/models/worker_model.dart';

class FavoriteModel extends Equatable {
  final int id;
  final int? workerId;
  final WorkerModel? workerInfo;
  final String? createdAt;

  const FavoriteModel({
    required this.id,
    this.workerId,
    this.workerInfo,
    this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    // The backend may return the worker either as `worker_info` (legacy) or
    // `worker` (current WorkerProfile shape). Accept both.
    final workerJson = (json['worker_info'] ?? json['worker']) as Map<String, dynamic>?;

    // Resolve the worker's User ID for matching against favorite buttons.
    // Prefer the explicit `worker_id` field; fall back to the nested user id.
    int? workerId = json['worker_id'] as int?;
    if (workerId == null && workerJson != null) {
      final user = workerJson['user'] as Map<String, dynamic>?;
      workerId = user?['id'] as int?;
    }

    return FavoriteModel(
      id: json['id'] as int,
      workerId: workerId,
      workerInfo: workerJson != null ? WorkerModel.fromJson(workerJson) : null,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'worker_id': workerId,
  };

  @override
  List<Object?> get props => [id, workerId, workerInfo, createdAt];
}
