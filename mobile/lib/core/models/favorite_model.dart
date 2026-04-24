import 'worker_model.dart';

class FavoriteModel {
  final int id;
  final WorkerModel worker;

  const FavoriteModel({required this.id, required this.worker});

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
        id: json['id'] as int,
        worker: WorkerModel.fromJson(json['worker'] as Map<String, dynamic>),
      );
}
