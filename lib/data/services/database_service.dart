import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static PostgreSQLConnection? _connection;
  static bool _isInitialized = false;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Initialize database connection
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Skip for web platform
      if (kIsWeb) {
        debugPrint('PostgreSQL connection not available for web');
        return;
      }
      
      // Load environment variables
      var env = DotEnv()..load();
      
      final host = env['DB_HOST'] ?? 'localhost';
      final port = int.parse(env['DB_PORT'] ?? '5432');
      final databaseName = env['DB_NAME'] ?? 'health_ai_db';
      final username = env['DB_USERNAME'] ?? 'postgres';
      final password = env['DB_PASSWORD'] ?? 'postgres';

      // Create connection
      _connection = PostgreSQLConnection(
        host,
        port,
        databaseName,
        username: username,
        password: password,
        useSSL: true,
      );

      // Open connection
      await _connection!.open();
      
      // Create tables if they don't exist
      await _createTables();
      
      _isInitialized = true;
      debugPrint('PostgreSQL connection initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize PostgreSQL connection: $e');
      rethrow;
    }
  }

  // Create necessary tables
  static Future<void> _createTables() async {
    if (_connection == null) {
      throw Exception('Database connection not initialized');
    }

    await _connection!.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id UUID PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      gender VARCHAR(10),
      age INTEGER,
      height DECIMAL,
      weight DECIMAL,
      activity_level VARCHAR(100),
      bmi DECIMAL,
      bmr DECIMAL,
      tdee DECIMAL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''');

    await _connection!.execute('''
    CREATE TABLE IF NOT EXISTS user_goals (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL,
      primary_goal VARCHAR(100),
      weight_goal VARCHAR(100),
      target_weight DECIMAL,
      goal_timeline VARCHAR(50),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
    ''');

    await _connection!.execute('''
    CREATE TABLE IF NOT EXISTS sleep_info (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL,
      sleep_hours DECIMAL,
      bedtime VARCHAR(10),
      wakeup_time VARCHAR(10),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
    ''');

    await _connection!.execute('''
    CREATE TABLE IF NOT EXISTS sleep_issues (
      id UUID PRIMARY KEY,
      sleep_id UUID NOT NULL,
      issue VARCHAR(100),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (sleep_id) REFERENCES sleep_info(id) ON DELETE CASCADE
    )
    ''');

    await _connection!.execute('''
    CREATE TABLE IF NOT EXISTS dietary_preferences (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL,
      preference VARCHAR(100),
      water_intake DECIMAL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
    ''');

    await _connection!.execute('''
    CREATE TABLE IF NOT EXISTS medical_conditions (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL,
      condition VARCHAR(100),
      other_condition TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
    ''');

    await _connection!.execute('''
    CREATE TABLE IF NOT EXISTS workout_preferences (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL,
      workout_type VARCHAR(100),
      workout_frequency INTEGER,
      workout_duration INTEGER,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
    ''');

    await _connection!.execute('''
    CREATE TABLE IF NOT EXISTS exercise_setup (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL,
      workout_location VARCHAR(100),
      fitness_level VARCHAR(50),
      has_trainer BOOLEAN,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
    ''');

    await _connection!.execute('''
    CREATE TABLE IF NOT EXISTS equipment (
      id UUID PRIMARY KEY,
      exercise_id UUID NOT NULL,
      equipment_name VARCHAR(100),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (exercise_id) REFERENCES exercise_setup(id) ON DELETE CASCADE
    )
    ''');
  }

  // Close database connection
  static Future<void> close() async {
    await _connection?.close();
    _isInitialized = false;
  }

  // Execute a query and return the results
  static Future<List<Map<String, dynamic>>> query(String query, [Map<String, dynamic>? parameters]) async {
    if (_connection == null) {
      throw Exception('Database connection not initialized');
    }

    final results = await _connection!.mappedResultsQuery(
      query,
      substitutionValues: parameters,
    );

    if (results.isEmpty) {
      return [];
    }

    // Convert PostgreSQL results to a simpler Map structure
    List<Map<String, dynamic>> mappedResults = [];
    for (var row in results) {
      var flattenedRow = <String, dynamic>{};
      row.forEach((tableName, tableRow) {
        flattenedRow.addAll(tableRow);
      });
      mappedResults.add(flattenedRow);
    }

    return mappedResults;
  }

  // Execute a query without returning results
  static Future<int> execute(String query, [Map<String, dynamic>? parameters]) async {
    if (_connection == null) {
      throw Exception('Database connection not initialized');
    }

    return await _connection!.execute(
      query,
      substitutionValues: parameters,
    );
  }

  // Check database connection
  static Future<bool> checkConnection() async {
    try {
      if (_connection == null || _connection!.isClosed) {
        return false;
      }
      
      // Try a simple query to test the connection
      await _connection!.query('SELECT 1');
      return true;
    } catch (e) {
      debugPrint('Database connection error: $e');
      return false;
    }
  }
}