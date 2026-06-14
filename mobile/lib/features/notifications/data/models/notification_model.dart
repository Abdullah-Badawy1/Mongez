import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? createdAt;
  final int? orderId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'in_app',
    this.isRead = false,
    this.createdAt,
    this.orderId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'in_app',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      orderId: json['order'] as int?,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      orderId: orderId,
    );
  }

  @override
  List<Object?> get props => [id, title, message, type, isRead, createdAt, orderId];
}
