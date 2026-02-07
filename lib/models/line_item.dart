class LineItem {
  final String id;
  final String invoiceId;
  final String name;
  final String? description;
  final double quantity;
  final double unitPrice;
  final double total;

  LineItem({
    required this.id,
    required this.invoiceId,
    required this.name,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
    };
  }

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['id'] as String,
      invoiceId: map['invoice_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}