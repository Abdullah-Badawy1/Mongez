class OrderModel {
  final int id;
  final int clientId;
  final String clientName;
  final int? workerId;
  final String? workerName;
  final int serviceCategoryId;
  final String serviceCategoryName;
  final String status;
  final String commission;
  final String createdAt;

  const OrderModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.workerId,
    this.workerName,
    required this.serviceCategoryId,
    required this.serviceCategoryName,
    required this.status,
    required this.commission,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>? ?? {};
    final worker = json['worker'] as Map<String, dynamic>?;
    final category = json['service_category'] as Map<String, dynamic>? ?? {};

    return OrderModel(
      id: json['id'] as int,
      clientId: client['id'] as int? ?? 0,
      clientName: client['username'] as String? ?? '',
      workerId: worker?['id'] as int?,
      workerName: worker?['username'] as String?,
      serviceCategoryId: category['id'] as int? ?? 0,
      serviceCategoryName: category['name'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      commission: json['commission'] as String? ?? '0',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isRejected => status == 'REJECTED';
}
