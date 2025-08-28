import 'package:uuid/uuid.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/database_service.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  static final Uuid _uuid = Uuid();

  // Save user data to PostgreSQL database
  static Future<String> saveUserProfile(UserProfile userProfile) async {
    try {
      final userId = _uuid.v4();
      
      // Begin transaction
      await DatabaseService.execute('BEGIN');
      
      try {
        // Insert user basic info
        await DatabaseService.execute('''
        INSERT INTO users (
          id, name, email, gender, age, height, weight, activity_level, bmi, bmr, tdee
        ) VALUES (
          @id, @name, @email, @gender, @age, @height, @weight, @activityLevel, @bmi, @bmr, @tdee
        )
        ''', {
          'id': userId,
          'name': userProfile.name,
          'email': userProfile.email,
          'gender': userProfile.gender,
          'age': userProfile.age,
          'height': userProfile.height,
          'weight': userProfile.weight,
          'activityLevel': userProfile.activityLevel,
          'bmi': userProfile.formData['bmi'] ?? 0.0,
          'bmr': userProfile.formData['bmr'] ?? 0.0,
          'tdee': userProfile.formData['tdee'] ?? 0.0,
        });

        // Insert user goals
        final goalId = _uuid.v4();
        await DatabaseService.execute('''
        INSERT INTO user_goals (
          id, user_id, primary_goal, weight_goal, target_weight, goal_timeline
        ) VALUES (
          @id, @userId, @primaryGoal, @weightGoal, @targetWeight, @goalTimeline
        )
        ''', {
          'id': goalId,
          'userId': userId,
          'primaryGoal': userProfile.primaryGoal,
          'weightGoal': userProfile.weightGoal,
          'targetWeight': userProfile.targetWeight,
          'goalTimeline': 'Moderate', // Default value, adjust as needed
        });

        // Insert sleep info
        final sleepId = _uuid.v4();
        await DatabaseService.execute('''
        INSERT INTO sleep_info (
          id, user_id, sleep_hours, bedtime, wakeup_time
        ) VALUES (
          @id, @userId, @sleepHours, @bedtime, @wakeupTime
        )
        ''', {
          'id': sleepId,
          'userId': userId,
          'sleepHours': userProfile.sleepHours,
          'bedtime': userProfile.bedtime,
          'wakeupTime': userProfile.wakeupTime,
        });

        // Insert sleep issues
        for (var issue in userProfile.sleepIssues) {
          await DatabaseService.execute('''
          INSERT INTO sleep_issues (
            id, sleep_id, issue
          ) VALUES (
            @id, @sleepId, @issue
          )
          ''', {
            'id': _uuid.v4(),
            'sleepId': sleepId,
            'issue': issue,
          });
        }

        // Insert dietary preferences
        for (var preference in userProfile.dietaryPreferences) {
          await DatabaseService.execute('''
          INSERT INTO dietary_preferences (
            id, user_id, preference, water_intake
          ) VALUES (
            @id, @userId, @preference, @waterIntake
          )
          ''', {
            'id': _uuid.v4(),
            'userId': userId,
            'preference': preference,
            'waterIntake': userProfile.waterIntake,
          });
        }

        // Insert medical conditions
        for (var condition in userProfile.medicalConditions) {
          await DatabaseService.execute('''
          INSERT INTO medical_conditions (
            id, user_id, condition, other_condition
          ) VALUES (
            @id, @userId, @condition, @otherCondition
          )
          ''', {
            'id': _uuid.v4(),
            'userId': userId,
            'condition': condition,
            'otherCondition': userProfile.otherMedicalCondition,
          });
        }

        // Insert workout preferences
        for (var workout in userProfile.preferredWorkouts) {
          await DatabaseService.execute('''
          INSERT INTO workout_preferences (
            id, user_id, workout_type, workout_frequency, workout_duration
          ) VALUES (
            @id, @userId, @workoutType, @workoutFrequency, @workoutDuration
          )
          ''', {
            'id': _uuid.v4(),
            'userId': userId,
            'workoutType': workout,
            'workoutFrequency': userProfile.workoutFrequency,
            'workoutDuration': userProfile.workoutDuration,
          });
        }

        // Insert exercise setup
        final exerciseId = _uuid.v4();
        await DatabaseService.execute('''
        INSERT INTO exercise_setup (
          id, user_id, workout_location, fitness_level, has_trainer
        ) VALUES (
          @id, @userId, @workoutLocation, @fitnessLevel, @hasTrainer
        )
        ''', {
          'id': exerciseId,
          'userId': userId,
          'workoutLocation': userProfile.workoutLocation,
          'fitnessLevel': userProfile.fitnessLevel,
          'hasTrainer': userProfile.hasTrainer,
        });

        // Insert equipment
        for (var equipment in userProfile.availableEquipment) {
          await DatabaseService.execute('''
          INSERT INTO equipment (
            id, exercise_id, equipment_name
          ) VALUES (
            @id, @exerciseId, @equipmentName
          )
          ''', {
            'id': _uuid.v4(),
            'exerciseId': exerciseId,
            'equipmentName': equipment,
          });
        }

        // Commit transaction
        await DatabaseService.execute('COMMIT');
        
        return userId;
      } catch (e) {
        // Rollback transaction on error
        await DatabaseService.execute('ROLLBACK');
        debugPrint('Error saving user profile: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Failed to save user profile: $e');
      rethrow;
    }
  }

  // Get user profile by ID
  static Future<UserProfile?> getUserProfileById(String userId) async {
    try {
      // Get user basic info
      final userResults = await DatabaseService.query('''
      SELECT * FROM users WHERE id = @userId
      ''', {'userId': userId});

      if (userResults.isEmpty) {
        return null;
      }

      final userData = userResults.first;

      // Get user goals
      final goalResults = await DatabaseService.query('''
      SELECT * FROM user_goals WHERE user_id = @userId
      ''', {'userId': userId});

      final goalData = goalResults.isNotEmpty ? goalResults.first : <String, dynamic>{};

      // Get sleep info
      final sleepResults = await DatabaseService.query('''
      SELECT * FROM sleep_info WHERE user_id = @userId
      ''', {'userId': userId});

      final sleepData = sleepResults.isNotEmpty ? sleepResults.first : <String, dynamic>{};

      // Get sleep issues
      final sleepIssuesResults = await DatabaseService.query('''
      SELECT si.issue FROM sleep_issues si
      JOIN sleep_info s ON si.sleep_id = s.id
      WHERE s.user_id = @userId
      ''', {'userId': userId});

      final sleepIssues = sleepIssuesResults.map((result) => result['issue'] as String).toList();

      // Get dietary preferences
      final dietaryResults = await DatabaseService.query('''
      SELECT preference FROM dietary_preferences WHERE user_id = @userId
      ''', {'userId': userId});

      final dietaryPreferences = dietaryResults.map((result) => result['preference'] as String).toList();

      // Get medical conditions
      final medicalResults = await DatabaseService.query('''
      SELECT condition, other_condition FROM medical_conditions WHERE user_id = @userId
      ''', {'userId': userId});

      final medicalConditions = medicalResults.map((result) => result['condition'] as String).toList();
      final otherMedicalCondition = medicalResults.isNotEmpty ? medicalResults.first['other_condition'] as String : '';

      // Get workout preferences
      final workoutResults = await DatabaseService.query('''
      SELECT DISTINCT workout_type, workout_frequency, workout_duration 
      FROM workout_preferences 
      WHERE user_id = @userId
      ''', {'userId': userId});

      final preferredWorkouts = workoutResults.map((result) => result['workout_type'] as String).toList();
      final workoutFrequency = workoutResults.isNotEmpty ? workoutResults.first['workout_frequency'] as int : 3;
      final workoutDuration = workoutResults.isNotEmpty ? workoutResults.first['workout_duration'] as int : 30;

      // Get exercise setup
      final exerciseResults = await DatabaseService.query('''
      SELECT * FROM exercise_setup WHERE user_id = @userId
      ''', {'userId': userId});

      final exerciseData = exerciseResults.isNotEmpty ? exerciseResults.first : <String, dynamic>{};

      // Get equipment
      final equipmentResults = await DatabaseService.query('''
      SELECT e.equipment_name FROM equipment e
      JOIN exercise_setup es ON e.exercise_id = es.id
      WHERE es.user_id = @userId
      ''', {'userId': userId});

      final availableEquipment = equipmentResults.map((result) => result['equipment_name'] as String).toList();

      // Create UserProfile object
      final userProfile = UserProfile(
        id: userData['id'] as String,
        name: userData['name'] as String,
        email: userData['email'] as String,
        gender: userData['gender'] as String,
        age: userData['age'] as int,
        height: (userData['height'] as num).toDouble(),
        weight: (userData['weight'] as num).toDouble(),
        activityLevel: userData['activity_level'] as String,
        primaryGoal: goalData['primary_goal'] as String? ?? '',
        weightGoal: goalData['weight_goal'] as String? ?? '',
        targetWeight: goalData['target_weight'] != null ? (goalData['target_weight'] as num).toDouble() : 0.0,
        sleepHours: sleepData['sleep_hours'] != null ? (sleepData['sleep_hours'] as num).toDouble() : 7.0,
        bedtime: sleepData['bedtime'] as String? ?? '',
        wakeupTime: sleepData['wakeup_time'] as String? ?? '',
        sleepIssues: sleepIssues,
        dietaryPreferences: dietaryPreferences,
        dailyStepGoal: userData['daily_step_goal'] != null ? (userData['daily_step_goal'] as num).toInt() : 10000,
        dailyMealsCount: userData['daily_meals_count'] != null ? (userData['daily_meals_count'] as num).toInt() : 3,
        waterIntake: userData['water_intake'] != null ? (userData['water_intake'] as num).toDouble() : 2.0,
        waterIntakeGlasses: userData['water_intake_glasses'] != null ? (userData['water_intake_glasses'] as num).toInt() : 8,
        medicalConditions: medicalConditions,
        otherMedicalCondition: otherMedicalCondition,
        preferredWorkouts: preferredWorkouts,
        workoutFrequency: workoutFrequency,
        workoutDuration: workoutDuration,
        workoutLocation: exerciseData['workout_location'] as String? ?? '',
        availableEquipment: availableEquipment,
        fitnessLevel: exerciseData['fitness_level'] as String? ?? 'Beginner',
        hasTrainer: exerciseData['has_trainer'] as bool? ?? false,
        formData: {
          'bmi': userData['bmi'] != null ? (userData['bmi'] as num).toDouble() : 0.0,
          'bmr': userData['bmr'] != null ? (userData['bmr'] as num).toDouble() : 0.0,
          'tdee': userData['tdee'] != null ? (userData['tdee'] as num).toDouble() : 0.0,
        },
      );
      
      return userProfile;
    } catch (e) {
      debugPrint('Failed to get user profile: $e');
      rethrow;
    }
  }
  
  // Get user profile by email
  static Future<UserProfile?> getUserProfileByEmail(String email) async {
    try {
      // Get user ID by email
      final userResults = await DatabaseService.query('''
      SELECT id FROM users WHERE email = @email
      ''', {'email': email});

      if (userResults.isEmpty) {
        return null;
      }

      final userId = userResults.first['id'] as String;
      return await getUserProfileById(userId);
    } catch (e) {
      debugPrint('Failed to get user profile by email: $e');
      rethrow;
    }
  }
  
  // Update user profile
  static Future<void> updateUserProfile(String userId, UserProfile userProfile) async {
    try {
      // Begin transaction
      await DatabaseService.execute('BEGIN');
      
      try {
        // Update user basic info
        await DatabaseService.execute('''
        UPDATE users 
        SET 
          name = @name, 
          email = @email, 
          gender = @gender, 
          age = @age, 
          height = @height, 
          weight = @weight, 
          activity_level = @activityLevel,
          bmi = @bmi,
          bmr = @bmr,
          tdee = @tdee,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        ''', {
          'id': userId,
          'name': userProfile.name,
          'email': userProfile.email,
          'gender': userProfile.gender,
          'age': userProfile.age,
          'height': userProfile.height,
          'weight': userProfile.weight,
          'activityLevel': userProfile.activityLevel,
          'bmi': userProfile.formData['bmi'] ?? 0.0,
          'bmr': userProfile.formData['bmr'] ?? 0.0,
          'tdee': userProfile.formData['tdee'] ?? 0.0,
        });

        // Update goals
        await DatabaseService.execute('''
        UPDATE user_goals 
        SET 
          primary_goal = @primaryGoal, 
          weight_goal = @weightGoal, 
          target_weight = @targetWeight,
          updated_at = CURRENT_TIMESTAMP
        WHERE user_id = @userId
        ''', {
          'userId': userId,
          'primaryGoal': userProfile.primaryGoal,
          'weightGoal': userProfile.weightGoal,
          'targetWeight': userProfile.targetWeight,
        });

        // Update sleep info
        await DatabaseService.execute('''
        UPDATE sleep_info 
        SET 
          sleep_hours = @sleepHours, 
          bedtime = @bedtime, 
          wakeup_time = @wakeupTime,
          updated_at = CURRENT_TIMESTAMP
        WHERE user_id = @userId
        ''', {
          'userId': userId,
          'sleepHours': userProfile.sleepHours,
          'bedtime': userProfile.bedtime,
          'wakeupTime': userProfile.wakeupTime,
        });

        // Get sleep info ID
        final sleepInfoResult = await DatabaseService.query('''
        SELECT id FROM sleep_info WHERE user_id = @userId
        ''', {'userId': userId});

        if (sleepInfoResult.isNotEmpty) {
          final sleepId = sleepInfoResult.first['id'] as String;
          
          // Delete existing sleep issues
          await DatabaseService.execute('''
          DELETE FROM sleep_issues WHERE sleep_id = @sleepId
          ''', {'sleepId': sleepId});
          
          // Insert new sleep issues
          for (var issue in userProfile.sleepIssues) {
            await DatabaseService.execute('''
            INSERT INTO sleep_issues (
              id, sleep_id, issue
            ) VALUES (
              @id, @sleepId, @issue
            )
            ''', {
              'id': _uuid.v4(),
              'sleepId': sleepId,
              'issue': issue,
            });
          }
        }

        // Delete existing dietary preferences
        await DatabaseService.execute('''
        DELETE FROM dietary_preferences WHERE user_id = @userId
        ''', {'userId': userId});
        
        // Insert new dietary preferences
        for (var preference in userProfile.dietaryPreferences) {
          await DatabaseService.execute('''
          INSERT INTO dietary_preferences (
            id, user_id, preference, water_intake
          ) VALUES (
            @id, @userId, @preference, @waterIntake
          )
          ''', {
            'id': _uuid.v4(),
            'userId': userId,
            'preference': preference,
            'waterIntake': userProfile.waterIntake,
          });
        }

        // Delete existing medical conditions
        await DatabaseService.execute('''
        DELETE FROM medical_conditions WHERE user_id = @userId
        ''', {'userId': userId});
        
        // Insert new medical conditions
        for (var condition in userProfile.medicalConditions) {
          await DatabaseService.execute('''
          INSERT INTO medical_conditions (
            id, user_id, condition, other_condition
          ) VALUES (
            @id, @userId, @condition, @otherCondition
          )
          ''', {
            'id': _uuid.v4(),
            'userId': userId,
            'condition': condition,
            'otherCondition': userProfile.otherMedicalCondition,
          });
        }

        // Delete existing workout preferences
        await DatabaseService.execute('''
        DELETE FROM workout_preferences WHERE user_id = @userId
        ''', {'userId': userId});
        
        // Insert new workout preferences
        for (var workout in userProfile.preferredWorkouts) {
          await DatabaseService.execute('''
          INSERT INTO workout_preferences (
            id, user_id, workout_type, workout_frequency, workout_duration
          ) VALUES (
            @id, @userId, @workoutType, @workoutFrequency, @workoutDuration
          )
          ''', {
            'id': _uuid.v4(),
            'userId': userId,
            'workoutType': workout,
            'workoutFrequency': userProfile.workoutFrequency,
            'workoutDuration': userProfile.workoutDuration,
          });
        }

        // Update exercise setup
        await DatabaseService.execute('''
        UPDATE exercise_setup 
        SET 
          workout_location = @workoutLocation, 
          fitness_level = @fitnessLevel, 
          has_trainer = @hasTrainer
        WHERE user_id = @userId
        ''', {
          'userId': userId,
          'workoutLocation': userProfile.workoutLocation,
          'fitnessLevel': userProfile.fitnessLevel,
          'hasTrainer': userProfile.hasTrainer,
        });

        // Get exercise setup ID
        final exerciseSetupResult = await DatabaseService.query('''
        SELECT id FROM exercise_setup WHERE user_id = @userId
        ''', {'userId': userId});

        if (exerciseSetupResult.isNotEmpty) {
          final exerciseId = exerciseSetupResult.first['id'] as String;
          
          // Delete existing equipment
          await DatabaseService.execute('''
          DELETE FROM equipment WHERE exercise_id = @exerciseId
          ''', {'exerciseId': exerciseId});
          
          // Insert new equipment
          for (var equipment in userProfile.availableEquipment) {
            await DatabaseService.execute('''
            INSERT INTO equipment (
              id, exercise_id, equipment_name
            ) VALUES (
              @id, @exerciseId, @equipmentName
            )
            ''', {
              'id': _uuid.v4(),
              'exerciseId': exerciseId,
              'equipmentName': equipment,
            });
          }
        }

        // Commit transaction
        await DatabaseService.execute('COMMIT');
      } catch (e) {
        // Rollback transaction on error
        await DatabaseService.execute('ROLLBACK');
        debugPrint('Error updating user profile: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Failed to update user profile: $e');
      rethrow;
    }
  }
  
  // Delete user profile
  static Future<void> deleteUserProfile(String userId) async {
    try {
      await DatabaseService.execute('''
      DELETE FROM users WHERE id = @userId
      ''', {'userId': userId});
    } catch (e) {
      debugPrint('Failed to delete user profile: $e');
      rethrow;
    }
  }
  
  // Check if email exists
  static Future<bool> emailExists(String email) async {
    try {
      final results = await DatabaseService.query('''
      SELECT COUNT(*) as count FROM users WHERE email = @email
      ''', {'email': email});

      return results.first['count'] > 0;
    } catch (e) {
      debugPrint('Failed to check if email exists: $e');
      return false;
    }
  }
}