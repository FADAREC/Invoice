// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'line_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LineItem _$LineItemFromJson(Map<String, dynamic> json) => LineItem(
      id: json['id'] as String,
      invoiceId: json['invoiceId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );

Map<String, dynamic> _$LineItemToJson(LineItem instance) => <String, dynamic>{
      'id': instance.id,
      'invoiceId': instance.invoiceId,
      'name': instance.name,
      'description': instance.description,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'total': instance.total,
    };
