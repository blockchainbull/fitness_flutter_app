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
        email VARCHAR(255) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        gender VARCHAR(20),
        age INTEGER,
        height DECIMAL,
        weight DECIMAL,
        activity_level VARCHAR(100),
        bmi DECIMAL,
        bmr DECIMAL,
        tdee DECIMAL,
        primary_goal VARCHAR(100),
        weight_goal VARCHAR(50),
        target_weight DECIMAL,
        goal_timeline VARCHAR(50),
        sleep_hours DECIMAL DEFAULT 7.0,
        bedtime VARCHAR(10),
        wakeup_time VARCHAR(10),
        sleep_issues TEXT[],
        dietary_preferences TEXT[],
        water_intake DECIMAL DEFAULT 2.0,
        medical_conditions TEXT[],
        other_medical_condition TEXT,
        preferred_workouts TEXT[],
        workout_frequency INTEGER DEFAULT 3,
        workout_duration INTEGER DEFAULT 30,
        workout_location VARCHAR(100),
        available_equipment TEXT[],
        fitness_level VARCHAR(50) DEFAULT 'Beginner',
        has_trainer BOOLEAN DEFAULT FALSE,
        has_periods BOOLEAN DEFAULT NULL,
        last_period_date TIMESTAMP DEFAULT NULL,
        cycle_length INTEGER DEFAULT NULL,
        cycle_length_regular BOOLEAN DEFAULT NULL,
        pregnancy_status VARCHAR(50) DEFAULT NULL,
        period_tracking_preference VARCHAR(50) DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
      ''');
       await _connection!.execute('''
        CREATE TABLE IF NOT EXISTS weight_entries (
          id UUID PRIMARY KEY,
          user_id UUID NOT NULL,
          date TIMESTAMP NOT NULL,
          weight DECIMAL NOT NULL,
          notes TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
        await _connection!.execute('''
          CREATE INDEX IF NOT EXISTS idx_weight_entries_user_date 
          ON weight_entries(user_id, date DESC)
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