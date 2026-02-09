import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../models/item.dart';

class ItemRepository {
  final Database _db;

  ItemRepository(this._db);

  static Future<ItemRepository> create() async {
    final db = await AppDatabase.instance.database;
    return ItemRepository(db);
  }

  Future<Item> createItem({
    required String name,
    String? description,
    required double defaultPrice,
  }) async {
    final itemId = const Uuid().v4();
    final now = DateTime.now();

    final item = Item(
      id: itemId,
      name: name,
      description: description,
      defaultPrice: defaultPrice,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insert('items', item.toMap());
    return item;
  }

  Future<List<Item>> getAllItems() async {
    final result = await _db.query(
      'items',
      orderBy: 'name ASC',
    );

    return result.map((map) => Item.fromMap(map)).toList();
  }

  Future<List<Item>> searchItems(String query) async {
    final result = await _db.query(
      'items',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return result.map((map) => Item.fromMap(map)).toList();
  }
}