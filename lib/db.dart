import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Represents a user in the system.
class User {
  final int? id;
  final String username;
  final String password; // Consider hashing instead of storing plaintext
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
  final int userId; // FK reference to 'users(id)'
  final String itemName;
  final DateTime
      expiryDate; // Consider using a standardized date format or storing as an integer timestamp
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
  /// The single instance of [Db].
  static final Db instance = Db._internal();
  Db._internal();

  // SQLite database reference
  static Database? _database;

  /// Provides a single database instance throughout the app.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initializes (and creates if necessary) the SQLite database.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fridgemate.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // Optionally handle schema upgrades here
    );
  }

  /// Creates the necessary tables the first time the DB is accessed.
  Future<void> _onCreate(Database db, int version) async {
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
        userId INTEGER,
        itemName TEXT NOT NULL,
        expiryDate TEXT,
        category TEXT,
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  // Uncomment or modify for future DB version upgrades.
  // Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //   // Example: If you change schema in new versions, handle it here.
  // }

  // ---------------------------------------------------------------------------
  // USER METHODS
  // ---------------------------------------------------------------------------

  /// Inserts a [User] into the [users] table.
  ///
  /// Returns the id of the newly inserted row.
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  /// Retrieves all users from the [users] table.
  Future<List<User>> getUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return List.generate(maps.length, (i) {
      return User(
        id: maps[i]['id'] as int?,
        username: maps[i]['username'] as String,
        password: maps[i]['password'] as String,
        email: maps[i]['email'] as String,
        dateOfBirth: DateTime.parse(maps[i]['dateOfBirth'] as String),
      );
    });
  }

  /// Retrieves a single [User] by their [username].
  ///
  /// Returns `null` if no user is found.
  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

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

  /// Deletes a user by [userId]. Due to the `ON DELETE CASCADE` constraint,
  /// their items will also be removed.
  ///
  /// Returns the number of rows deleted.
  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ---------------------------------------------------------------------------
  // ITEM METHODS
  // ---------------------------------------------------------------------------

  /// Inserts an [Item] into the [items] table.
  ///
  /// Returns the id of the newly inserted row.
  Future<int> insertItem(Item item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  /// Updates an [Item] in the [items] table.
  ///
  /// Returns the number of rows updated.
  Future<int> updateItem(Item item) async {
    final db = await database;
    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Retrieves all items belonging to a specific [userId].
  Future<List<Item>> getUserItems(int userId) async {
    final db = await database;
    final maps = await db.query(
      'items',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return Item(
        id: maps[i]['id'] as int?,
        userId: maps[i]['userId'] as int,
        itemName: maps[i]['itemName'] as String,
        expiryDate: DateTime.parse(maps[i]['expiryDate'] as String),
        category: maps[i]['category'] as String,
      );
    });
  }

  /// Deletes an item by [itemId].
  ///
  /// Returns the number of rows deleted.
  Future<int> deleteItem(int itemId) async {
    final db = await database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // ---------------------------------------------------------------------------
  // OPTIONAL: Close the DB
  // ---------------------------------------------------------------------------

  /// Closes the database, freeing up resources. Call this when your app
  /// is disposed or no longer needs DB access (e.g., on logout).
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
