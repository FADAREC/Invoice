import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../models/customer.dart';

class CustomerRepository {
  final Database _db;

  CustomerRepository(this._db);

  static Future<CustomerRepository> create() async {
    final db = await AppDatabase.instance.database;
    return CustomerRepository(db);
  }

  Future<Customer> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
  }) async {
    final customerId = const Uuid().v4();
    final now = DateTime.now();

    final customer = Customer(
      id: customerId,
      name: name,
      email: email,
      phone: phone,
      address: address,
      createdAt: now,
      updatedAt: now,
    );

    await _db.transaction((txn) async {
      await txn.insert('customers', customer.toMap());

      await txn.insert('sync_log', {
        'entity_type': 'customer',
        'entity_id': customerId,
        'operation': 'create',
        'sync_status': 'pending',
        'created_at': now.toIso8601String(),
      });
    });

    return customer;
  }

  Future<List<Customer>> getAllCustomers() async {
    final result = await _db.query(
      'customers',
      orderBy: 'name ASC',
    );

    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(String customerId) async {
    final result = await _db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Customer.fromMap(result.first);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final result = await _db.query(
      'customers',
      where: 'name LIKE ? OR email LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return result.map((map) => Customer.fromMap(map)).toList();
  }
}