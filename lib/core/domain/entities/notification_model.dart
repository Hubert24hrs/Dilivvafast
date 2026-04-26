import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

enum NotificationType {
  @JsonValue('order_update')
  orderUpdate,
  @JsonValue('payment')
  payment,
  @JsonValue('promo')
  promo,
  @JsonValue('system')
  system,
  @JsonValue('driver_assigned')
  driverAssigned,
  @JsonValue('delivery_complete')
  deliveryComplete,
}

@freezed
abstract class NotificationModel with _$NotificationModel {
  const NotificationModel._();
  const factory NotificationModel({
    required String id,
    required String userId,
    required String title,
    required String body,
    @Default(NotificationType.system) NotificationType type,
    @Default(false) bool isRead,
    Map<String, dynamic>? payload,
    @TimestampConverter() required DateTime createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return NotificationModel.fromJson(data);
  }
}

extension NotificationModelX on NotificationModel {
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'payload': payload,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
