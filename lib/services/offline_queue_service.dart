import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class QueueEntry {
  final int? id;
  final String operationType; // 'create', 'update', 'delete'
  final String entityType; // 'product', 'sale', 'expense', 'shop'
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;
  final String? errorMessage;

  QueueEntry({
    this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.errorMessage,
  });

  factory QueueEntry.fromMap(Map<String, dynamic> map) => QueueEntry(
    id: map['id'],
    operationType: map['operation_type'],
    entityType: map['entity_type'],
    entityId: map['entity_id'],
    payload: jsonDecode(map['payload'] ?? '{}'),
    createdAt: DateTime.parse(map['created_at']),
    retryCount: map['retry_count'] ?? 0,
    errorMessage: map['error_message'],
  );
}

class OfflineQueueService {
  static const String _dbName = 'gouanzouh_queue.db';
  static const String _tableName = 'sync_queue';
  
  Database? _database;

  Future<Database> _getDb() async {
    _database ??= await openDatabase(
      join(await getDatabasesPath(), _dbName),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation_type TEXT NOT NULL,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0,
            error_message TEXT,
            status TEXT DEFAULT 'pending'
          )
        ''');
        
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_status ON $_tableName(status)'
        );
      },
      version: 1,
    );
    return _database!;
  }

  Future<void> addToQueue(
    String operationType,
    String entityType,
    String entityId,
    Map<String, dynamic> payload,
  ) async {
    final db = await _getDb();
    await db.insert(_tableName, {
      'operation_type': operationType,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
  }

  Future<List<QueueEntry>> getPendingOperations() async {
    final db = await _getDb();
    final results = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return results.map((m) => QueueEntry.fromMap(m)).toList();
  }

  Future<void> markAsSynced(int queueId) async {
    final db = await _getDb();
    await db.update(_tableName, {'status': 'synced'},
        where: 'id = ?', whereArgs: [queueId]);
  }

  Future<void> incrementRetry(int queueId, String? errorMsg) async {
    final db = await _getDb();
    await db.rawUpdate(
      'UPDATE $_tableName SET retry_count = retry_count + 1, error_message = ? WHERE id = ?',
      [errorMsg, queueId],
    );
  }

  Future<void> markAsFailed(int queueId, String errorMsg) async {
    final db = await _getDb();
    await db.update(_tableName, {'status': 'failed', 'error_message': errorMsg},
        where: 'id = ?', whereArgs: [queueId]);
  }

  Future<List<QueueEntry>> getFailedOperations() async {
    final db = await _getDb();
    final results = await db.query(_tableName,
        where: 'status = ?', whereArgs: ['failed'], orderBy: 'created_at DESC');
    return results.map((m) => QueueEntry.fromMap(m)).toList();
  }

  Future<Map<String, int>> getQueueStats() async {
    final db = await _getDb();
    final pending = Sqflite.firstIntValue(
          await db.rawQuery(
              'SELECT COUNT(*) FROM $_tableName WHERE status = ?', ['pending']),
        ) ??
        0;
    final failed = Sqflite.firstIntValue(
          await db.rawQuery(
              'SELECT COUNT(*) FROM $_tableName WHERE status = ?', ['failed']),
        ) ??
        0;
    return {'pending': pending, 'failed': failed};
  }

  Future<void> clearSynced() async {
    final db = await _getDb();
    await db.delete(_tableName, where: 'status = ?', whereArgs: ['synced']);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
