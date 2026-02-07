import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';

class Branch {
  final String id;
  final String code;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Branch({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class BranchRepository {
  final Database _db;

  BranchRepository(this._db);

  static Future<BranchRepository> create() async {
    final db = await AppDatabase.instance.database;
    return BranchRepository(db);
  }

  Future<Branch> createBranch({
    required String code,
    required String name,
  }) async {
    final branchId = const Uuid().v4();
    final now = DateTime.now();

    final branch = Branch(
      id: branchId,
      code: code,
      name: name,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insert('branches', branch.toMap());
    return branch;
  }

  Future<List<Branch>> getAllBranches() async {
    final result = await _db.query(
      'branches',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return result.map((map) => Branch.fromMap(map)).toList();
  }

  Future<Branch?> getActiveBranch() async {
    final result = await _db.query(
      'branches',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Branch.fromMap(result.first);
  }

  // Create default branch if none exists
  Future<void> ensureDefaultBranch() async {
    final branches = await getAllBranches();
    
    if (branches.isEmpty) {
      await createBranch(code: 'HQ', name: 'Headquarters');
    }
  }
}