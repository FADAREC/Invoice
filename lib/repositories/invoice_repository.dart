import 'package:sqflite/sqflite.dart';
import '../database/database.dart';
import '../models/invoice.dart';
import '../models/line_item.dart';
import '../services/device_service.dart';
import 'package:uuid/uuid.dart';

class InvoiceRepository {
  final Database _db;

  InvoiceRepository(this._db);
  
  Database get db => _db;

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

  //Create INVOICE
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
    final invoiceId = const Uuid().v4();  // Generate invoice ID first
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
      // Insert invoice FIRST
      await txn.insert('invoices', invoice.toMap());

      // Insert line items with correct invoice ID
      final batch = txn.batch();
      for (var item in items) {
        // Create a new line item with the correct invoiceId
        final lineItemWithInvoiceId = LineItem(
          id: item.id,
          invoiceId: invoiceId,  // Use the generated invoice ID
          name: item.name,
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          total: item.total,
        );
        batch.insert('line_items', lineItemWithInvoiceId.toMap());
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
  Future<String> markAsPaid({
    required String invoiceId,
    required DateTime paymentDate,
    required String paymentMethod,
  }) async {
    final now = DateTime.now();

    // Get invoice details first
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

    if (invoice.status == InvoiceStatus.paid) {
      throw Exception('Invoice is already paid');
    }

    // Generate receipt number
    final receiptNumber = await _generateReceiptNumber(invoice.branchId);
    final receiptId = const Uuid().v4();

    await _db.transaction((txn) async {
      // Update invoice
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

      // Create receipt (IMMUTABLE)
      await txn.insert('receipts', {
        'id': receiptId,
        'invoice_id': invoiceId,
        'receipt_number': receiptNumber,
        'amount': invoice.total,
        'payment_date': paymentDate.toIso8601String(),
        'payment_method': paymentMethod,
        'created_at': now.toIso8601String(),
        'synced_at': null,
      });

      // Log sync events
      await txn.insert('sync_log', {
        'entity_type': 'invoice',
        'entity_id': invoiceId,
        'operation': 'update',
        'sync_status': 'pending',
        'created_at': now.toIso8601String(),
      });

      await txn.insert('sync_log', {
        'entity_type': 'receipt',
        'entity_id': receiptId,
        'operation': 'create',
        'sync_status': 'pending',
        'created_at': now.toIso8601String(),
      });
    });

    return receiptNumber;
  }

  // Delete invoice (soft delete)
  Future<void> deleteInvoice(String invoiceId) async {
    final now = DateTime.now();

    // Get invoice to check if it's paid
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

    // CRITICAL: Prevent deleting paid invoices
    if (invoice.status == InvoiceStatus.paid) {
      throw Exception('Cannot delete paid invoices. This is a financial record.');
    }

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

  //Receipt Number Generator
  Future<String> _generateReceiptNumber(String branchId) async {
    // Get branch code
    final branchResult = await _db.query(
      'branches',
      columns: ['code'],
      where: 'id = ?',
      whereArgs: [branchId],
      limit: 1,
    );

    final branchCode = branchResult.first['code'] as String;
    final year = DateTime.now().year;
    final prefix = 'RCT-$branchCode-$year-';

    // Get max sequence for this branch+year
    final lastReceipt = await _db.query(
      'receipts',
      columns: ['receipt_number'],
      where: 'receipt_number LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'receipt_number DESC',
      limit: 1,
    );

    int sequence = 1;
    if (lastReceipt.isNotEmpty) {
      final parts = (lastReceipt.first['receipt_number'] as String).split('-');
      sequence = int.parse(parts.last) + 1;
    }

    return '$prefix${sequence.toString().padLeft(4, '0')}';
  }
}