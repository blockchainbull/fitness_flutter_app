import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static PostgreSQLConnection? _connection;
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Initialize database connection
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        debugPrint('PostgreSQL connection not available for web');
        _isInitialized = false;
        return;
      }
      
      // Load environment variables
      var env = DotEnv()..load();
      
      final host = env['DB_HOST'] ?? 'localhost';
      final port = int.parse(env['DB_PORT'] ?? '5432');
      final databaseName = env['DB_NAME'] ?? 'health_ai_db';
      final username = env['DB_USERNAME'] ?? 'postgres';
      final password = env['DB_PASSWORD'] ?? 'postgres';

      
      _connection = PostgreSQLConnection(
        host,
        port,
        databaseName,
        username: username,
        password: password,
        useSSL: false,
      );

      // Open connection
      await _connection!.open();
      
      await _createTables();
      
      _isInitialized = true;
      debugPrint('PostgreSQL connection initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize PostgreSQL connection: $e');
      _isInitialized = false; 
      _connection = null; 
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
        await _connection!.execute('''
          CREATE TABLE IF NOT EXISTS supplement_tracking (
            id VARCHAR(50) PRIMARY KEY,
            user_id VARCHAR(50) NOT NULL,
            date DATE NOT NULL,
            supplement_name VARCHAR(100) NOT NULL,
            dosage VARCHAR(50),
            taken BOOLEAN DEFAULT FALSE,
            time_taken TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, date, supplement_name)
          )
        ''');

        await _connection!.execute('''
          CREATE TABLE IF NOT EXISTS user_supplement_preferences (
            id VARCHAR(50) PRIMARY KEY,
            user_id VARCHAR(50) NOT NULL,
            supplement_name VARCHAR(100) NOT NULL,
            dosage VARCHAR(50),
            frequency VARCHAR(50) DEFAULT 'Daily',
            preferred_time VARCHAR(10) DEFAULT '9:00 AM',
            notes TEXT,
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Add indices
        await _connection!.execute('''
          CREATE INDEX IF NOT EXISTS idx_supplement_tracking_user_date 
          ON supplement_tracking(user_id, date DESC)
        ''');
        
        await _connection!.execute('''
          CREATE INDEX IF NOT EXISTS idx_supplement_preferences_user 
          ON user_supplement_preferences(user_id, is_active)
        ''');
  }

  // Close database connection
  static Future<void> close() async {
    await _connection?.close();
    _isInitialized = false;
  }

  // Execute a query and return the results
  static Future<List<Map<String, dynamic>>> query(String query, [Map<String, dynamic>? parameters]) async {
    // Check if connection is available and initialized
    if (!_isInitialized || _connection == null) {
      throw Exception('Database connection not initialized');
    }

    try {
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
    } catch (e) {
      debugPrint('Database query error: $e');
      // Mark connection as failed for future operations
      _isInitialized = false;
      _connection = null;
      throw Exception('Database connection not initialized');
    }
  }

  // Execute a query without returning results
 static Future<int> execute(String query, [Map<String, dynamic>? parameters]) async {
    // Check if connection is available and initialized
    if (!_isInitialized || _connection == null) {
      throw Exception('Database connection not initialized');
    }

    try {
      return await _connection!.execute(
        query,
        substitutionValues: parameters,
      );
    } catch (e) {
      debugPrint('Database execute error: $e');
      // Mark connection as failed for future operations
      _isInitialized = false;
      _connection = null;
      throw Exception('Database connection not initialized');
    }
  }

  // Check database connection
  static Future<bool> checkConnection() async {
    try {
      if (_connection == null || _connection!.isClosed) {
        print('❌ Database connection is null or closed');
        return false;
      }
      
      // Try a simple query to test the connection
      await _connection!.query('SELECT 1');
      print('✅ Database connection is healthy');
      return true;
    } catch (e) {
      print('❌ Database connection error: $e');
      return false;
    }
  }

  static bool get isAvailable => _isInitialized && _connection != null;
  
  // Add a method to attempt reconnection
  static Future<void> reconnect() async {
    _isInitialized = false;
    _connection = null;
    await initialize();
  }

  static Future<String> getConnectionStatus() async {
    if (!_isInitialized) {
      return 'Not initialized';
    }
    if (_connection == null) {
      return 'Connection is null';
    }
    if (_connection!.isClosed) {
      return 'Connection is closed';
    }
    
    try {
      await _connection!.query('SELECT 1');
      return 'Connected';
    } catch (e) {
      return 'Connection failed: $e';
    }
  }

  // water logging functions
  static Future<List<Map<String, dynamic>>> queryWater(String sql, [List<dynamic>? arguments]) async {
    if (_connection == null) {
      throw Exception('Database connection not initialized');
    }

    try {
      // Handle parameter substitution for PostgreSQL
      Map<String, dynamic> substitutionValues = {};
      String modifiedSql = sql;
      
      if (arguments != null) {
        for (int i = 0; i < arguments.length; i++) {
          substitutionValues['param$i'] = arguments[i];
          modifiedSql = modifiedSql.replaceAll('\$${i + 1}', '@param$i');
        }
      }

      final results = await _connection!.query(modifiedSql, substitutionValues: substitutionValues);
      
      // Convert PostgreSQLResultRow to Map<String, dynamic>
      return results.map((row) {
        final Map<String, dynamic> map = {};
        for (int i = 0; i < row.length; i++) {
          map[row.columnDescriptions[i].columnName] = row[i];
        }
        return map;
      }).toList();
    } catch (e) {
      debugPrint('Water tracking query error: $e');
      rethrow;
    }
  }

  // New method specifically for water tracking execute operations
  static Future<void> executeWater(String sql, [List<dynamic>? arguments]) async {
    if (_connection == null) {
      throw Exception('Database connection not initialized');
    }

    try {
      // Handle parameter substitution for PostgreSQL
      Map<String, dynamic> substitutionValues = {};
      String modifiedSql = sql;
      
      if (arguments != null) {
        for (int i = 0; i < arguments.length; i++) {
          substitutionValues['param$i'] = arguments[i];
          modifiedSql = modifiedSql.replaceAll('\$${i + 1}', '@param$i');
        }
      }

      await _connection!.execute(modifiedSql, substitutionValues: substitutionValues);
    } catch (e) {
      debugPrint('Water tracking execute error: $e');
      rethrow;
    }
  }

  static Future<void> createWaterTrackingTable() async {
    try {
      await executeWater(r'''
        CREATE TABLE IF NOT EXISTS daily_water (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL,
          date TIMESTAMP WITH TIME ZONE NOT NULL,
          glasses_consumed INTEGER DEFAULT 0,
          total_ml DECIMAL DEFAULT 0.0,
          target_ml DECIMAL DEFAULT 2000.0,
          notes TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE INDEX IF NOT EXISTS idx_daily_water_user_date 
        ON daily_water(user_id, date);
        
        CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_water_user_date_unique 
        ON daily_water(user_id, (date::date));
      ''');
      debugPrint('✅ Water tracking table created successfully');
    } catch (e) {
      debugPrint('❌ Error creating water tracking table: $e');
      // Try without unique constraint
      try {
        await executeWater(r'''
          CREATE TABLE IF NOT EXISTS daily_water (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL,
            date TIMESTAMP WITH TIME ZONE NOT NULL,
            glasses_consumed INTEGER DEFAULT 0,
            total_ml DECIMAL DEFAULT 0.0,
            target_ml DECIMAL DEFAULT 2000.0,
            notes TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
          );
          
          CREATE INDEX IF NOT EXISTS idx_daily_water_user_date 
          ON daily_water(user_id, date);
        ''');
        debugPrint('✅ Water tracking table created without unique constraint');
      } catch (e2) {
        debugPrint('❌ Failed to create water tracking table: $e2');
      }
    }
  }

  // Period Logging Functions
  static Future<void> insertPeriod(String query, List<dynamic> values) async {
    if (!_isInitialized || _connection == null) {
      throw Exception('Database not initialized');
    }
    
    try {
      await _connection!.query(query, substitutionValues: {
        for (int i = 0; i < values.length; i++) 
          '${i + 1}': values[i]
      });
    } catch (e) {
      print('Error inserting period: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> queryPeriods(
    String query, 
    List<dynamic> values
  ) async {
    if (!_isInitialized || _connection == null) {
      throw Exception('Database not initialized');
    }
    
    try {
      final results = await _connection!.query(
        query,
        substitutionValues: {
          for (int i = 0; i < values.length; i++) 
            '${i + 1}': values[i]
        },
      );
      
      return results.map((row) {
        final map = <String, dynamic>{};
        for (int i = 0; i < row.length; i++) {
          if (results.columnDescriptions != null && 
              i < results.columnDescriptions!.length) {
            map[results.columnDescriptions![i].columnName] = row[i];
          }
        }
        return map;
      }).toList();
    } catch (e) {
      print('Error querying periods: $e');
      return [];
    }
  }


}