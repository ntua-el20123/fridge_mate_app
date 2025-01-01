import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Example user data model
class User {
  final int? id;
  final String username;
  final String password;

  User({this.id, required this.username, required this.password});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
    };
  }
}

class Db {
  static final Db instance = Db._internal();
  Db._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Opens/creates the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fridgemate.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create tables for users and items
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        itemName TEXT NOT NULL,
        expiryDate TEXT,
        category TEXT,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');
  }

  // CRUD Methods
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) {
      return User(
        id: maps[i]['id'],
        username: maps[i]['username'],
        password: maps[i]['password'],
      );
    });
  }

  // Check if a user exists (for login)
  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (results.isNotEmpty) {
      return User(
        id: results.first['id'],
        username: results.first['username'],
        password: results.first['password'],
      );
    }
    return null;
  }

  // Example item insert
  Future<int> insertItem(Map<String, dynamic> itemData) async {
    final db = await database;
    return await db.insert('items', itemData);
  }

  // ... additional item queries ...
}
