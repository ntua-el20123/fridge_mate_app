import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Represents a user in the system.
class User {
  final int? id;
  final String username;
  final String password; // Consider hashing instead of storing plaintext
  final String email;
  final DateTime dateOfBirth;
  final int recipeCount;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.dateOfBirth,
    this.recipeCount = 6,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'recipeCount': recipeCount,
    };
  }
}

/// Represents an item belonging to a user.
class Item {
  final int? id;
  final int userId; // FK reference to 'users(id)'
  final String itemName;
  final DateTime expiryDate;
  final String category;
  final String? image; // Optional image column

  Item({
    this.id,
    required this.userId,
    required this.itemName,
    required this.expiryDate,
    required this.category,
    this.image,
  });

  factory Item.fromMap(Map<String, Object?> json) => Item(
        id: json['id'] as int?,
        userId: json['userId'] as int,
        itemName: json['itemName'] as String,
        expiryDate: DateTime.parse(json['expiryDate'] as String),
        category: json['category'] as String,
        image: json['image'] as String?,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'itemName': itemName,
      'expiryDate': expiryDate.toIso8601String(),
      'category': category,
      'image': image,
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
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    final result = await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    print("Updating user: ${user.toMap()}");
    return result;
  }

  /// Adds a 'favorites' table to store user's favorite recipes
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      password TEXT NOT NULL,
      email TEXT NOT NULL,
      dateOfBirth TEXT NOT NULL,
      recipeCount INTEGER NOT NULL DEFAULT 6
    )
  ''');

    await db.execute('''
    CREATE TABLE items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER,
      itemName TEXT NOT NULL,
      expiryDate TEXT,
      category TEXT,
      image TEXT,
      FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
    )
  ''');

    await db.execute('''
    CREATE TABLE favorites (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER NOT NULL,
      recipeName TEXT NOT NULL,
      ingredients TEXT NOT NULL,
      instructions TEXT NOT NULL,
      FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
    )
  ''');
  }

  /// Retrieves all favorite recipes for a specific user.
  Future<List<Map<String, dynamic>>> getFavoriteRecipes(int userId) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    // Parse the database records into a structured list
    return List.generate(maps.length, (i) {
      final ingredientsRaw = maps[i]['ingredients'];
      final ingredients = ingredientsRaw != null && ingredientsRaw is String
          ? List<String>.from(jsonDecode(ingredientsRaw))
          : [];

      return {
        'id': maps[i]['id'],
        'name': maps[i]['recipeName'] ?? 'Unknown Recipe',
        'ingredients': ingredients,
        'instructions': maps[i]['instructions'] ?? 'No instructions provided.',
      };
    });
  }

  /// Deletes a favorite recipe by its ID.
  Future<int> deleteFavoriteRecipe(int recipeId) async {
    final db = await database;
    return await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [recipeId],
    );
  }

  /// Handles schema upgrades for new versions of the database.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // Assuming version 4 includes recipeCount
      await db.execute(
          'ALTER TABLE users ADD COLUMN recipeCount INTEGER DEFAULT 6');
    }
    if (oldVersion < 3) {
      // Increment the version if needed
      await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        recipeName TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        instructions TEXT NOT NULL,
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE, 
      )
    ''');
    }
  }

  // ---------------------------------------------------------------------------
  // USER METHODS
  // ---------------------------------------------------------------------------

  Future<int> insertUser(User user) async {
    final db = await database;

    // Check if the username already exists
    final existingUsers = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [user.username],
    );

    if (existingUsers.isNotEmpty) {
      throw Exception('Username already exists');
    }

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
        recipeCount: (maps[i]['recipeCount'] as int?) ?? 6,
      );
    });
  }

  /// Retrieves a single [User] by their [id].
  Future<User?> getUserById(int id) async {
    final db = await database;

    // Query the database for the user with the given ID
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    // If the result is not empty, parse the user data
    if (results.isNotEmpty) {
      final row = results.first;
      return User(
        id: row['id'] as int?,
        username: row['username'] as String,
        password: row['password'] as String,
        email: row['email'] as String,
        dateOfBirth: DateTime.parse(row['dateOfBirth'] as String),
        recipeCount: (row['recipeCount'] as int?) ?? 6,
      );
    }

    // Return null if no user was found
    return null;
  }

  /// Retrieves a single [User] by their [username].
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

  /// Deletes a user by [userId].
  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ---------------------------------------------------------------------------
  // FAVOURITE RECIPE METHODS
  // ---------------------------------------------------------------------------

  /// Inserts a recipe into the `favorites` table.
  Future<void> insertFavoriteRecipe(
    int userId,
    String name,
    List<String> ingredients,
    String instructions,
  ) async {
    final db = await database;

    // Check for duplicate entries
    final existing = await db.query(
      'favorites',
      where: 'userId = ? AND recipeName = ?',
      whereArgs: [userId, name],
    );

    if (existing.isNotEmpty) {
      // If the recipe already exists, return without inserting
      return;
    }

    // Insert the recipe into the database
    await db.insert('favorites', {
      'userId': userId,
      'recipeName': name,
      'ingredients': jsonEncode(ingredients),
      'instructions': instructions,
    });
  }

  Future<void> deleteFavoriteRecipeByName(int userId, String recipeName) async {
    final db = await database;

    // Delete the specific recipe
    await db.delete(
      'favorites',
      where: 'userId = ? AND recipeName = ?',
      whereArgs: [userId, recipeName],
    );
  }

  /// Checks if a recipe is in the user's favorites.
  Future<bool> isRecipeFavorite(int userId, String recipeName) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'userId = ? AND recipeName = ?',
      whereArgs: [userId, recipeName],
    );
    return maps.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // ITEM METHODS
  // ---------------------------------------------------------------------------

  /// Inserts an [Item] into the [items] table.
  Future<int> insertItem(Item item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  /// Updates an [Item] in the [items] table.
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
        image: maps[i]['image'] as String?, // Include the image field
      );
    });
  }

  /// Deletes an item by [itemId].
  Future<int> deleteItem(int itemId) async {
    final db = await database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// Closes the database.
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
