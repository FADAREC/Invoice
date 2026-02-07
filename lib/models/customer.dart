class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at']) : null,
    );
  }
}