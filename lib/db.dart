import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

/// Represents a user in the system.
class User {
  final int? id;
  final String username;
  final String password;
  final String email;
  final DateTime dateOfBirth;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'dateOfBirth': dateOfBirth.toIso8601String(),
    };
  }
}

/// Represents an item belonging to a user.
class Item {
  final int? id;
  final int userId;
  final String itemName;
  final DateTime expiryDate;
  final String category;

  Item({
    this.id,
    required this.userId,
    required this.itemName,
    required this.expiryDate,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'itemName': itemName,
      'expiryDate': expiryDate.toIso8601String(),
      'category': category,
    };
  }
}

/// Singleton Database helper class.
class Db {
  static final Db instance = Db._internal();
  final log = Logger('DbLogger');
  Db._internal();

  Database? _database;
  final String dbFile = "fridgemate.db";

  Future<Database> get database async {
    if (_database != null) {
      log.config("Database instance already exists.");
      return _database!;
    }
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    log.config("Initializing database.");

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      final databaseFactory = databaseFactoryFfi;
      final appDocumentsDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDocumentsDir.path, "databases", dbFile);

      return await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
        ),
      );
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, dbFile);

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    log.config("Creating tables in the database.");

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        email TEXT NOT NULL,
        dateOfBirth TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        itemName TEXT NOT NULL,
        expiryDate TEXT NOT NULL,
        category TEXT,
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Inserts a [User] into the database.
  Future<int> insertUser(User user) async {
    log.config("Inserting user: ${user.toMap()}");
    final db = await database;
    return await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Retrieves all users from the database.
  Future<List<User>> getUsers() async {
    log.config("Fetching all users.");
    final db = await database;
    final results = await db.query('users');

    return results
        .map((row) => User(
              id: row['id'] as int?,
              username: row['username'] as String,
              password: row['password'] as String,
              email: row['email'] as String,
              dateOfBirth: DateTime.parse(row['dateOfBirth'] as String),
            ))
        .toList();
  }

  /// Retrieves a single user by username.
  Future<User?> getUserByUsername(String username) async {
    log.config("Fetching user with username: $username");
    final db = await database;
    final results = await db.query('users',
        where: 'username = ?', whereArgs: [username], limit: 1);

    if (results.isNotEmpty) {
      final row = results.first;
      return User(
        id: row['id'] as int?,
        username: row['username'] as String,
        password: row['password'] as String,
        email: row['email'] as String,
        dateOfBirth: DateTime.parse(row['dateOfBirth'] as String),
      );
    }
    return null;
  }

  /// Inserts an [Item] into the database.
  Future<int> insertItem(Item item) async {
    log.config("Inserting item: ${item.toMap()}");
    final db = await database;
    return await db.insert('items', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Retrieves all items for a specific user.
  Future<List<Item>> getUserItems(int userId) async {
    log.config("Fetching items for userId: $userId");
    final db = await database;
    final results =
        await db.query('items', where: 'userId = ?', whereArgs: [userId]);

    return results
        .map((row) => Item(
              id: row['id'] as int?,
              userId: row['userId'] as int,
              itemName: row['itemName'] as String,
              expiryDate: DateTime.parse(row['expiryDate'] as String),
              category: row['category'] as String,
            ))
        .toList();
  }

  /// Deletes a user and their associated items.
  Future<int> deleteUser(int userId) async {
    log.config("Deleting user with userId: $userId");
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  /// Deletes an item by its ID.
  Future<int> deleteItem(int itemId) async {
    log.config("Deleting item with itemId: $itemId");
    final db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [itemId]);
  }

  /// Updates an item.
  Future<int> updateItem(Item item) async {
    log.config("Updating item: ${item.toMap()}");
    final db = await database;
    return await db
        .update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  /// Closes the database.
  Future<void> closeDatabase() async {
    if (_database != null) {
      log.config("Closing the database.");
      await _database!.close();
      _database = null;
    }
  }
}
