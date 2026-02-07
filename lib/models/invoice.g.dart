// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invoice _$InvoiceFromJson(Map<String, dynamic> json) => Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      branchId: json['branchId'] as String,
      customerId: json['customerId'] as String,
      status: $enumDecode(_$InvoiceStatusEnumMap, json['status']),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      notes: json['notes'] as String?,
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      paymentMethod: json['paymentMethod'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deviceId: json['deviceId'] as String,
      syncedAt: json['syncedAt'] == null
          ? null
          : DateTime.parse(json['syncedAt'] as String),
    );

Map<String, dynamic> _$InvoiceToJson(Invoice instance) => <String, dynamic>{
      'id': instance.id,
      'invoiceNumber': instance.invoiceNumber,
      'branchId': instance.branchId,
      'customerId': instance.customerId,
      'status': _$InvoiceStatusEnumMap[instance.status]!,
      'subtotal': instance.subtotal,
      'tax': instance.tax,
      'discount': instance.discount,
      'total': instance.total,
      'notes': instance.notes,
      'dueDate': instance.dueDate?.toIso8601String(),
      'paidAt': instance.paidAt?.toIso8601String(),
      'paymentMethod': instance.paymentMethod,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deviceId': instance.deviceId,
      'syncedAt': instance.syncedAt?.toIso8601String(),
    };

const _$InvoiceStatusEnumMap = {
  InvoiceStatus.unpaid: 'unpaid',
  InvoiceStatus.paid: 'paid',
  InvoiceStatus.deleted: 'deleted',
};
