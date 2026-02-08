import 'package:sqflite/sqflite.dart';
import '../database/database.dart';
import '../models/invoice.dart';
import '../models/line_item.dart';
import '../services/device_service.dart';
import 'package:uuid/uuid.dart';

class InvoiceRepository {
  final Database _db;

  InvoiceRepository(this._db);

  static Future<InvoiceRepository> create() async {
    final db = await AppDatabase.instance.database;
    return InvoiceRepository(db);
  }

  // Generate invoice number
  Future<String> _generateInvoiceNumber(String branchCode) async {
    final year = DateTime.now().year;
    final prefix = '$branchCode-$year-';

    final result = await _db.query(
      'invoices',
      columns: ['invoice_number'],
      where: 'invoice_number LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'invoice_number DESC',
      limit: 1,
    );

    int sequence = 1;
    if (result.isNotEmpty) {
      final lastNumber = result.first['invoice_number'] as String;
      final parts = lastNumber.split('-');
      sequence = int.parse(parts.last) + 1;
    }

    return '$prefix${sequence.toString().padLeft(4, '0')}';
  }

  // Create invoice with line items (ATOMIC)
  Future<Invoice> createInvoice({
    required String branchId,
    required String customerId,
    required List<LineItem> items,
    double taxRate = 0.0,
    double discount = 0.0,
    String? notes,
    DateTime? dueDate,
  }) async {
    final stopwatch = Stopwatch()..start();

    final deviceId = await DeviceService.instance.getDeviceId();
    final invoiceId = const Uuid().v4();
    final now = DateTime.now();

    // Calculate totals
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final taxAmount = subtotal * taxRate;
    final total = subtotal + taxAmount - discount;

    // Get branch code for invoice number
    final branchResult = await _db.query(
      'branches',
      columns: ['code'],
      where: 'id = ?',
      whereArgs: [branchId],
      limit: 1,
    );

    if (branchResult.isEmpty) {
      throw Exception('Branch not found');
    }

    final branchCode = branchResult.first['code'] as String;
    final invoiceNumber = await _generateInvoiceNumber(branchCode);

    final invoice = Invoice(
      id: invoiceId,
      invoiceNumber: invoiceNumber,
      branchId: branchId,
      customerId: customerId,
      status: InvoiceStatus.unpaid,
      subtotal: subtotal,
      tax: taxAmount,
      discount: discount,
      total: total,
      notes: notes,
      dueDate: dueDate,
      paidAt: null,
      paymentMethod: null,
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
      syncedAt: null,
    );

    await _db.transaction((txn) async {
      // Insert invoice
      await txn.insert('invoices', invoice.toMap());

      // Insert line items
      final batch = txn.batch();
      for (var item in items) {
        batch.insert('line_items', item.toMap());
      }
      await batch.commit(noResult: true);

      // Log sync event
      await txn.insert('sync_log', {
        'entity_type': 'invoice',
        'entity_id': invoiceId,
        'operation': 'create',
        'sync_status': 'pending',
        'created_at': now.toIso8601String(),
      });
    });

    stopwatch.stop();
    
    // Assert performance budget
    if (stopwatch.elapsedMilliseconds > 150) {
      print('⚠️ WARNING: Invoice save took ${stopwatch.elapsedMilliseconds}ms (budget: 150ms)');
    }

    return invoice;
  }

  // Get unpaid invoices
  Future<List<Invoice>> getUnpaidInvoices({String? branchId}) async {
    final where = branchId != null 
        ? 'status = ? AND branch_id = ?'
        : 'status = ?';
    final whereArgs = branchId != null 
        ? ['unpaid', branchId]
        : ['unpaid'];

    final result = await _db.query(
      'invoices',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'due_date ASC, created_at DESC',
    );

    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  // Get paid invoices
  Future<List<Invoice>> getPaidInvoices({String? branchId}) async {
    final where = branchId != null 
        ? 'status = ? AND branch_id = ?'
        : 'status = ?';
    final whereArgs = branchId != null 
        ? ['paid', branchId]
        : ['paid'];

    final result = await _db.query(
      'invoices',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'paid_at DESC, created_at DESC',
    );

    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  // Get invoice by ID with line items
  Future<(Invoice, List<LineItem>)> getInvoiceWithItems(String invoiceId) async {
    final invoiceResult = await _db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );

    if (invoiceResult.isEmpty) {
      throw Exception('Invoice not found');
    }

    final invoice = Invoice.fromMap(invoiceResult.first);

    final itemsResult = await _db.query(
      'line_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );

    final items = itemsResult.map((map) => LineItem.fromMap(map)).toList();

    return (invoice, items);
  }

  // Mark invoice as paid
  Future<void> markAsPaid({
    required String invoiceId,
    required DateTime paymentDate,
    required String paymentMethod,
  }) async {
    final now = DateTime.now();

    await _db.transaction((txn) async {
      await txn.update(
        'invoices',
        {
          'status': 'paid',
          'paid_at': paymentDate.toIso8601String(),
          'payment_method': paymentMethod,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // Log sync event
      await txn.insert('sync_log', {
        'entity_type': 'invoice',
        'entity_id': invoiceId,
        'operation': 'update',
        'sync_status': 'pending',
        'created_at': now.toIso8601String(),
      });
    });
  }

  // Delete invoice (soft delete)
  Future<void> deleteInvoice(String invoiceId) async {
    final now = DateTime.now();

    await _db.transaction((txn) async {
      await txn.update(
        'invoices',
        {
          'status': 'deleted',
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // Log sync event
      await txn.insert('sync_log', {
        'entity_type': 'invoice',
        'entity_id': invoiceId,
        'operation': 'delete',
        'sync_status': 'pending',
        'created_at': now.toIso8601String(),
      });
    });
  }
}