enum InvoiceStatus {
  unpaid,
  paid,
  deleted,
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String branchId;
  final String customerId;
  final InvoiceStatus status;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String? notes;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String deviceId;
  final DateTime? syncedAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.branchId,
    required this.customerId,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    this.notes,
    this.dueDate,
    this.paidAt,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.syncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'branch_id': branchId,
      'customer_id': customerId,
      'status': status.name,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'notes': notes,
      'due_date': dueDate?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'device_id': deviceId,
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      branchId: map['branch_id'] as String,
      customerId: map['customer_id'] as String,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.unpaid,
      ),
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      notes: map['notes'] as String?,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at']) : null,
      paymentMethod: map['payment_method'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deviceId: map['device_id'] as String,
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at']) : null,
    );
  }

  Invoice copyWith({
    InvoiceStatus? status,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    String? notes,
    DateTime? dueDate,
    DateTime? paidAt,
    String? paymentMethod,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber,
      branchId: branchId,
      customerId: customerId,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      deviceId: deviceId,
      syncedAt: syncedAt,
    );
  }
}