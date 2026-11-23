import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, accepted, completed, cancelled, rejected }

extension OrderStatusExtension on OrderStatus {
  String get value => name;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }
}

OrderStatus orderStatusFromString(String? value) {
  switch (value) {
    case 'accepted':
      return OrderStatus.accepted;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'rejected':
      return OrderStatus.rejected;
    case 'pending':
    default:
      return OrderStatus.pending;
  }
}

class OrderModel {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;
  final String deliveryLocation;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.farmerId,
    required this.farmerName,
    required this.farmerPhone,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.deliveryLocation,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return OrderModel(
      id: docId ?? (map['id'] as String? ?? ''),
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      productImageUrl: map['productImageUrl'] as String? ?? '',
      buyerId: map['buyerId'] as String? ?? '',
      buyerName: map['buyerName'] as String? ?? '',
      buyerPhone: map['buyerPhone'] as String? ?? '',
      farmerId: map['farmerId'] as String? ?? '',
      farmerName: map['farmerName'] as String? ?? '',
      farmerPhone: map['farmerPhone'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? 'kg',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      deliveryLocation: map['deliveryLocation'] as String? ?? '',
      status: orderStatusFromString(map['status'] as String?),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'deliveryLocation': deliveryLocation,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  OrderModel copyWith({
    String? productId,
    String? productName,
    String? productImageUrl,
    String? buyerId,
    String? buyerName,
    String? buyerPhone,
    String? farmerId,
    String? farmerName,
    String? farmerPhone,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? totalPrice,
    String? deliveryLocation,
    OrderStatus? status,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
