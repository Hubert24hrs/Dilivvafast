import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_delivery/features/auth/domain/entities/user_model.dart';

part 'promo_model.freezed.dart';
part 'promo_model.g.dart';

enum DiscountType {
  @JsonValue('flat')
  flat,
  @JsonValue('percent')
  percent,
}

@freezed
abstract class PromoModel with _$PromoModel {
  const PromoModel._();
  const factory PromoModel({
    required String id,
    required String code,
    @Default(DiscountType.flat) DiscountType discountType,
    required double amount,
    @Default(0.0) double minOrderAmount,
    @TimestampConverter() required DateTime expiresAt,
    @Default(0) int maxUses,
    @Default(0) int usedCount,
    @Default(true) bool isActive,
    @TimestampConverter() required DateTime createdAt,
  }) = _PromoModel;

  factory PromoModel.fromJson(Map<String, dynamic> json) =>
      _$PromoModelFromJson(json);

  factory PromoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return PromoModel.fromJson(data);
  }
}

extension PromoModelX on PromoModel {
  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'discountType': discountType.name,
      'amount': amount,
      'minOrderAmount': minOrderAmount,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'maxUses': maxUses,
      'usedCount': usedCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get hasUsesRemaining => maxUses == 0 || usedCount < maxUses;
  bool get isValid => isActive && !isExpired && hasUsesRemaining;

  double calculateDiscount(double orderAmount) {
    if (!isValid) return 0.0;
    if (orderAmount < minOrderAmount) return 0.0;
    switch (discountType) {
      case DiscountType.flat:
        return amount > orderAmount ? orderAmount : amount;
      case DiscountType.percent:
        return orderAmount * (amount / 100);
    }
  }
}
