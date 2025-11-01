// lib/data/models/user_profile.dart

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? password; 
  final String gender;
  final int age;
  final double height;
  final double weight;
  final double? startingWeight;
  final DateTime? startingWeightDate;
  final String activityLevel;

  final double? bmi;
  final double? bmr;
  final double? tdee;
  
  final bool? hasPeriods;
  final DateTime? lastPeriodDate;
  final int? cycleLength;
  final int? periodLength;
  final bool? cycleLengthRegular;
  final String? pregnancyStatus;
  final String? periodTrackingPreference;
  
  final String primaryGoal;
  final String weightGoal;
  final double targetWeight;
  final String? goalTimeline; 
  final double sleepHours;
  final String bedtime;
  final String wakeupTime;
  final int dailyStepGoal;
  final int dailyMealsCount;
  final List<String> sleepIssues;
  final List<String> dietaryPreferences;
  final double waterIntake;
  final int waterIntakeGlasses;
  final List<String> medicalConditions;
  final String otherMedicalCondition;
  final List<String> preferredWorkouts;
  final int workoutFrequency;
  final int workoutDuration;
  final String workoutLocation;
  final List<String> availableEquipment;
  final String fitnessLevel;
  final bool hasTrainer;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final Map<String, dynamic> formData;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.password, 
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    this.startingWeight,
    this.startingWeightDate,
    required this.activityLevel,

    this.bmi,
    this.bmr,
    this.tdee,
    
    this.hasPeriods,
    this.lastPeriodDate,
    this.cycleLength,
     this.periodLength,
    this.cycleLengthRegular,
    this.pregnancyStatus,
    this.periodTrackingPreference,
    
    required this.primaryGoal,
    required this.weightGoal,
    this.targetWeight = 0.0,
    this.goalTimeline, 
    required this.sleepHours,
    required this.bedtime,
    required this.wakeupTime,
    required this.dailyStepGoal,
    this.dailyMealsCount = 3,
    required this.sleepIssues,
    required this.dietaryPreferences,
    required this.waterIntake,
    required this.waterIntakeGlasses,
    required this.medicalConditions,
    this.otherMedicalCondition = '',
    required this.preferredWorkouts,
    required this.workoutFrequency,
    required this.workoutDuration,
    required this.workoutLocation,
    required this.availableEquipment,
    required this.fitnessLevel,
    required this.hasTrainer,
    
    this.createdAt,
    this.updatedAt,

    this.formData = const {},
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // Create a formData map or use an existing one
    Map<String, dynamic> formDataMap = Map<String, dynamic>.from(map['formData'] ?? {});
    
    // If bmi, bmr, tdee are directly in the map, add them to formData
    if (map.containsKey('bmi')) formDataMap['bmi'] = map['bmi'];
    if (map.containsKey('bmr')) formDataMap['bmr'] = map['bmr'];
    if (map.containsKey('tdee')) formDataMap['tdee'] = map['tdee'];

    // Helper function to normalize weight goal
    String normalizeWeightGoal(String? goal) {
      if (goal == null || goal.isEmpty) return '';
      
      final lowercased = goal.toLowerCase().trim();
      if (lowercased.contains('lose')) return 'lose_weight';
      if (lowercased.contains('gain')) return 'gain_weight';
      if (lowercased.contains('maintain')) return 'maintain_weight';
      
      // Return as-is if already in correct format
      return goal;
    }

    print('🔍 UserProfile.fromMap received:');
    print('  primary_goal: "${map['primary_goal']}" / primaryGoal: "${map['primaryGoal']}"');
    print('  weight_goal: "${map['weight_goal']}" / weightGoal: "${map['weightGoal']}"');
    print('  target_weight: ${map['target_weight']} / targetWeight: ${map['targetWeight']}');

    // Get and normalize weight goal
    final rawWeightGoal = map['weightGoal'] ?? map['weight_goal'] ?? '';
    final normalizedWeightGoal = normalizeWeightGoal(rawWeightGoal);
    
    print('  normalized weight_goal: "$normalizedWeightGoal"');

    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'],
      gender: map['gender'] ?? '',
      age: map['age'] ?? 0,
      height: map['height']?.toDouble() ?? 0.0,
      weight: map['weight']?.toDouble() ?? 0.0,
      startingWeight: map['starting_weight'] != null ? double.tryParse(map['starting_weight'].toString()) : null,
      startingWeightDate: map['starting_weight_date'] != null ? DateTime.tryParse(map['starting_weight_date'].toString()) : null,  

      activityLevel: map['activity_level'] ?? map['activityLevel'] ?? '',

      bmi: map['bmi']?.toDouble(),
      bmr: map['bmr']?.toDouble(),
      tdee: map['tdee']?.toDouble(),
      
      hasPeriods: map['hasPeriods'],
      lastPeriodDate: _parseDateTime(map['lastPeriodDate'] ?? map['last_period_date']),
      cycleLength: map['cycleLength'],
      periodLength: map['periodLength'] ?? map['period_length'] ?? 5,
      cycleLengthRegular: map['cycleLengthRegular'],
      pregnancyStatus: map['pregnancyStatus'],
      periodTrackingPreference: map['periodTrackingPreference'],
      
      primaryGoal: map['primaryGoal'] ?? map['primary_goal'] ?? '',
      weightGoal: normalizedWeightGoal, // Use normalized value
      targetWeight: map['targetWeight']?.toDouble() ?? map['target_weight']?.toDouble() ?? 0.0,
      goalTimeline: map['goalTimeline'] ?? map['goal_timeline'],
      sleepHours: map['sleepHours']?.toDouble() ?? map['sleep_hours']?.toDouble() ?? 7.0,
      bedtime: map['bedtime'] ?? '22:00',
      wakeupTime: map['wakeupTime'] ?? map['wakeup_time'] ?? '06:00', 
      dailyStepGoal: map['dailyStepGoal'] ?? map['daily_step_goal'] ?? 10000,
      dailyMealsCount: map['dailyMealsCount'] ?? map['daily_meals_count'] ?? 3,
      sleepIssues: _parseStringList(map['sleepIssues'] ?? map['sleep_issues']),

      dietaryPreferences: List<String>.from(
        map['dietary_preferences'] ?? map['dietaryPreferences'] ?? []
      ),
      
      waterIntake: map['waterIntake']?.toDouble() ?? 2.0,
      waterIntakeGlasses: map['water_intake_glasses'] ?? 8,
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      otherMedicalCondition: map['otherMedicalCondition'] ?? '',
      
      preferredWorkouts: List<String>.from(
        map['preferred_workouts'] ?? map['preferredWorkouts'] ?? []
      ),
      
      workoutFrequency: map['workoutFrequency'] ?? 3,
      workoutDuration: map['workoutDuration'] ?? 30,

      workoutLocation: map['workout_location'] ?? map['workoutLocation'] ?? '',

      availableEquipment: List<String>.from(
        map['available_equipment'] ?? map['availableEquipment'] ?? []
      ),
      
      fitnessLevel: map['fitnessLevel'] ?? 'Beginner',
      hasTrainer: map['hasTrainer'] ?? false,

      createdAt: map['created_at'] != null 
        ? DateTime.tryParse(map['created_at']) 
        : null,
      updatedAt: map['updated_at'] != null 
        ? DateTime.tryParse(map['updated_at']) 
        : null,

      formData: formDataMap,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    if (value is String) return [value];
    return [];
  }


  static UserProfile fromApiResponse(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      age: data['age'] ?? 0,
      height: (data['height'] ?? 0.0).toDouble(),
      weight: (data['weight'] ?? 0.0).toDouble(),
      
      // Map snake_case fields from API
      activityLevel: data['activity_level'] ?? '',
      
      // Goals
      primaryGoal: data['primary_goal'] ?? '',
      weightGoal: data['weight_goal'] ?? '',
      targetWeight: (data['target_weight'] ?? 0.0).toDouble(),
      goalTimeline: data['goal_timeline'] ?? '',
      
      // Sleep
      sleepHours: (data['sleep_hours'] ?? 7.0).toDouble(),
      bedtime: data['bedtime'] ?? '',
      wakeupTime: data['wakeup_time'] ?? '',
      sleepIssues: List<String>.from(data['sleep_issues'] ?? []),
      
      // Nutrition
      dietaryPreferences: List<String>.from(data['dietary_preferences'] ?? []),
      waterIntake: (data['water_intake'] ?? 2.0).toDouble(),
      waterIntakeGlasses: data['water_intake_glasses'] ?? 8,
      dailyMealsCount: data['daily_meals_count'] ?? 3,
      medicalConditions: List<String>.from(data['medical_conditions'] ?? []),
      otherMedicalCondition: data['other_medical_condition'] ?? '',
      
      // Exercise - THESE ARE THE KEY FIELDS
      preferredWorkouts: List<String>.from(data['preferred_workouts'] ?? []),
      workoutFrequency: data['workout_frequency'] ?? 3,
      workoutDuration: data['workout_duration'] ?? 30,
      workoutLocation: data['workout_location'] ?? '',
      availableEquipment: List<String>.from(data['available_equipment'] ?? []),
      fitnessLevel: data['fitness_level'] ?? 'Beginner',
      hasTrainer: data['has_trainer'] ?? false,
      
      // Step goal
      dailyStepGoal: data['daily_step_goal'] ?? 10000,
      
      // BMI/BMR/TDEE
      bmi: (data['bmi'] ?? 0.0).toDouble(),
      bmr: (data['bmr'] ?? 0.0).toDouble(),
      tdee: (data['tdee'] ?? 0.0).toDouble(),
      
      // Women's health
      hasPeriods: data['has_periods'],
      pregnancyStatus: data['pregnancy_status'],
      periodTrackingPreference: data['period_tracking_preference'],
      cycleLength: data['cycle_length'],
      cycleLengthRegular: data['cycle_length_regular'],
      
      // Timestamps
      createdAt: data['created_at'] != null 
        ? DateTime.tryParse(data['created_at']) 
        : null,
      updatedAt: data['updated_at'] != null 
        ? DateTime.tryParse(data['updated_at']) 
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'startingWeight': startingWeight,
      'startingWeightDate': startingWeightDate?.toIso8601String(),
      'activityLevel': activityLevel,
      
      'bmi': bmi,
      'bmr': bmr,
      'tdee': tdee,

      'hasPeriods': hasPeriods,
      'lastPeriodDate': lastPeriodDate?.toIso8601String(),
      'cycleLength': cycleLength,
      'periodLength': periodLength,
      'cycleLengthRegular': cycleLengthRegular,
      'pregnancyStatus': pregnancyStatus,
      'periodTrackingPreference': periodTrackingPreference,
      
      'primaryGoal': primaryGoal,
      'weightGoal': weightGoal,
      'targetWeight': targetWeight,
      'goalTimeline': goalTimeline,
      'sleepHours': sleepHours,
      'bedtime': bedtime,
      'wakeupTime': wakeupTime,
      'dailyStepGoal': dailyStepGoal,
      'dailyMealsCount': dailyMealsCount,
      'sleepIssues': sleepIssues,
      'dietaryPreferences': dietaryPreferences,
      'waterIntake': waterIntake,
      'water_intake_glasses': waterIntakeGlasses,
      'medicalConditions': medicalConditions,
      'otherMedicalCondition': otherMedicalCondition,
      'preferredWorkouts': preferredWorkouts,
      'workoutFrequency': workoutFrequency,
      'workoutDuration': workoutDuration,
      'workoutLocation': workoutLocation,
      'availableEquipment': availableEquipment,
      'fitnessLevel': fitnessLevel,
      'hasTrainer': hasTrainer,
      
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
    
    return map;
  }

  // Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date: $value');
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toOnboardingFormat() {
    return {
      'basicInfo': {
        'name': name,
        'email': email,
        'password': password ?? 'defaultpassword123',
        'gender': gender,
        'age': age,
        'height': height,
        'weight': weight,
        'startingWeight': startingWeight,
        'startingWeightDate': startingWeightDate?.toIso8601String(),
        'activityLevel': activityLevel,
        'bmi': formData['bmi'] ?? 0.0,
        'bmr': formData['bmr'] ?? 0.0,
        'tdee': formData['tdee'] ?? 0.0,
      },
      if (gender.toLowerCase() == 'female' && hasPeriods != null)
        'periodCycle': {
          'hasPeriods': hasPeriods,
          'lastPeriodDate': lastPeriodDate?.toIso8601String(),
          'cycleLength': cycleLength,
          'periodLength': periodLength,
          'cycleLengthRegular': cycleLengthRegular,
          'pregnancyStatus': pregnancyStatus,
          'trackingPreference': periodTrackingPreference,
        },
      'primaryGoal': primaryGoal,
      'weightGoal': {
        'weightGoal': weightGoal,
        'targetWeight': targetWeight,
        'timeline': goalTimeline ?? '',
      },
      'sleepInfo': {
        'sleepHours': sleepHours,
        'bedtime': bedtime,
        'wakeupTime': wakeupTime,
        'sleepIssues': sleepIssues,
      },
      'dietaryPreferences': {
        'dietaryPreferences': dietaryPreferences,
        'waterIntake': waterIntake,
        'waterIntakeGlasses': waterIntakeGlasses,
        'dailyMealsCount': dailyMealsCount,
        'medicalConditions': medicalConditions,
        'otherCondition': otherMedicalCondition,
      },
      'workoutPreferences': {
        'workoutTypes': preferredWorkouts,
        'frequency': workoutFrequency,
        'duration': workoutDuration,
      },
      'exerciseSetup': {
        'workoutLocation': workoutLocation,
        'equipment': availableEquipment,
        'fitnessLevel': fitnessLevel,
        'hasTrainer': hasTrainer,
      },
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? gender,
    int? age,
    double? height,
    double? weight,
    double? startingWeight,
    DateTime? startingWeightDate,
    String? activityLevel,

    double? bmi,
    double? bmr,
    double? tdee,
    
    bool? hasPeriods,
    DateTime? lastPeriodDate,
    int? cycleLength,
    int? periodLength,
    bool? cycleLengthRegular,
    String? pregnancyStatus,
    String? periodTrackingPreference,
    
    String? primaryGoal,
    String? weightGoal,
    double? targetWeight,
    String? goalTimeline,
    double? sleepHours,
    String? bedtime,
    String? wakeupTime,
    int? dailyStepGoal,
    List<String>? sleepIssues,
    List<String>? dietaryPreferences,
    double? waterIntake,
    int? waterIntakeGlasses,
    int? dailyMealsCount,
    List<String>? medicalConditions,
    String? otherMedicalCondition,
    List<String>? preferredWorkouts,
    int? workoutFrequency,
    int? workoutDuration,
    String? workoutLocation,
    List<String>? availableEquipment,
    String? fitnessLevel,
    bool? hasTrainer,

    DateTime? createdAt,
    DateTime? updatedAt,

    Map<String, dynamic>? formData,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      startingWeight: startingWeight ?? this.startingWeight,
      startingWeightDate: startingWeightDate ?? this.startingWeightDate,
      activityLevel: activityLevel ?? this.activityLevel,

      bmi: bmi ?? this.bmi,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      
      hasPeriods: hasPeriods ?? this.hasPeriods,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      cycleLengthRegular: cycleLengthRegular ?? this.cycleLengthRegular,
      pregnancyStatus: pregnancyStatus ?? this.pregnancyStatus,
      periodTrackingPreference: periodTrackingPreference ?? this.periodTrackingPreference,
      
      primaryGoal: primaryGoal ?? this.primaryGoal,
      weightGoal: weightGoal ?? this.weightGoal,
      targetWeight: targetWeight ?? this.targetWeight,
      goalTimeline: goalTimeline ?? this.goalTimeline,
      sleepHours: sleepHours ?? this.sleepHours,
      bedtime: bedtime ?? this.bedtime,
      wakeupTime: wakeupTime ?? this.wakeupTime,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      sleepIssues: sleepIssues ?? this.sleepIssues,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      waterIntake: waterIntake ?? this.waterIntake,
      waterIntakeGlasses: waterIntakeGlasses ?? this.waterIntakeGlasses,
      dailyMealsCount: dailyMealsCount ?? this.dailyMealsCount,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      otherMedicalCondition: otherMedicalCondition ?? this.otherMedicalCondition,
      preferredWorkouts: preferredWorkouts ?? this.preferredWorkouts,
      workoutFrequency: workoutFrequency ?? this.workoutFrequency,
      workoutDuration: workoutDuration ?? this.workoutDuration,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      hasTrainer: hasTrainer ?? this.hasTrainer,

      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      
      formData: formData ?? this.formData,
    );
  }
  
  @override
  String toString() {
    return 'UserProfile(name: $name, email: $email, age: $age, primaryGoal: $primaryGoal)';
  }
}