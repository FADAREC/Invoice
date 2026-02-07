import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invoice_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable WAL mode for better concurrency
    // await db.execute('PRAGMA journal_mode=WAL');
    await db.execute('PRAGMA foreign_keys=ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // Invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        invoice_number TEXT UNIQUE NOT NULL,
        branch_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        status TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        discount REAL NOT NULL,
        total REAL NOT NULL,
        notes TEXT,
        due_date TEXT,
        paid_at TEXT,
        payment_method TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        device_id TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_invoice_status ON invoices(status)');
    await db.execute('CREATE INDEX idx_invoice_branch ON invoices(branch_id)');
    await db.execute('CREATE INDEX idx_invoice_updated ON invoices(updated_at)');

    // Line items table
    await db.execute('''
      CREATE TABLE line_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY(invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_line_items_invoice ON line_items(invoice_id)');

    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    // Receipts table (immutable)
    await db.execute('''
      CREATE TABLE receipts (
        id TEXT PRIMARY KEY,
        invoice_id TEXT UNIQUE NOT NULL,
        receipt_number TEXT UNIQUE NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced_at TEXT,
        FOREIGN KEY(invoice_id) REFERENCES invoices(id)
      )
    ''');

    // Sync log (append-only)
    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_sync_status ON sync_log(sync_status)');

    // Branches table
    await db.execute('''
      CREATE TABLE branches (
        id TEXT PRIMARY KEY,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Business info table (single row)
    await db.execute('''
      CREATE TABLE business_info (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        logo_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Settings table (key-value)
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Insert default settings
    await db.insert('settings', {'key': 'currency', 'value': 'USD'});
    await db.insert('settings', {'key': 'default_tax_rate', 'value': '0.0'});
    await db.insert('settings', {'key': 'invoice_number_format', 'value': '{branch}-{year}-{sequence}'});
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}