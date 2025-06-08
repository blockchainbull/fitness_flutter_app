// lib/data/models/user_profile.dart
import 'dart:convert';

class UserProfile {
  final String name;
  final String email;
  final String? password; // Add password field (optional for security)
  final String gender;
  final int age;
  final double height;
  final double weight;
  final String activityLevel;
  final String primaryGoal;
  final String weightGoal;
  final double targetWeight;
  final String? goalTimeline; // Add goalTimeline field
  final double sleepHours;
  final String bedtime;
  final String wakeupTime;
  final List<String> sleepIssues;
  final List<String> dietaryPreferences;
  final double waterIntake;
  final List<String> medicalConditions;
  final String otherMedicalCondition;
  final List<String> preferredWorkouts;
  final int workoutFrequency;
  final int workoutDuration;
  final String workoutLocation;
  final List<String> availableEquipment;
  final String fitnessLevel;
  final bool hasTrainer;
  final Map<String, dynamic> formData;

  UserProfile({
    required this.name,
    required this.email,
    this.password, // Optional password field
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.primaryGoal,
    required this.weightGoal,
    this.targetWeight = 0.0,
    this.goalTimeline, // Add goalTimeline parameter
    required this.sleepHours,
    required this.bedtime,
    required this.wakeupTime,
    required this.sleepIssues,
    required this.dietaryPreferences,
    required this.waterIntake,
    required this.medicalConditions,
    this.otherMedicalCondition = '',
    required this.preferredWorkouts,
    required this.workoutFrequency,
    required this.workoutDuration,
    required this.workoutLocation,
    required this.availableEquipment,
    required this.fitnessLevel,
    required this.hasTrainer,
    this.formData = const {},
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // Create a formData map or use an existing one
    Map<String, dynamic> formDataMap = Map<String, dynamic>.from(map['formData'] ?? {});
    
    // If bmi, bmr, tdee are directly in the map, add them to formData
    if (map.containsKey('bmi')) formDataMap['bmi'] = map['bmi'];
    if (map.containsKey('bmr')) formDataMap['bmr'] = map['bmr'];
    if (map.containsKey('tdee')) formDataMap['tdee'] = map['tdee'];

    return UserProfile(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'], // Add password field
      gender: map['gender'] ?? '',
      age: map['age'] ?? 0,
      height: map['height']?.toDouble() ?? 0.0,
      weight: map['weight']?.toDouble() ?? 0.0,
      activityLevel: map['activityLevel'] ?? '',
      primaryGoal: map['primaryGoal'] ?? '',
      weightGoal: map['weightGoal'] ?? '',
      targetWeight: map['targetWeight']?.toDouble() ?? 0.0,
      goalTimeline: map['goalTimeline'], // Add goalTimeline field
      sleepHours: map['sleepHours']?.toDouble() ?? 7.0,
      bedtime: map['bedtime'] ?? '22:00',
      wakeupTime: map['wakeupTime'] ?? '06:00',
      sleepIssues: List<String>.from(map['sleepIssues'] ?? []),
      dietaryPreferences: List<String>.from(map['dietaryPreferences'] ?? []),
      waterIntake: map['waterIntake']?.toDouble() ?? 2.0,
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      otherMedicalCondition: map['otherMedicalCondition'] ?? '',
      preferredWorkouts: List<String>.from(map['preferredWorkouts'] ?? []),
      workoutFrequency: map['workoutFrequency'] ?? 3,
      workoutDuration: map['workoutDuration'] ?? 30,
      workoutLocation: map['workoutLocation'] ?? '',
      availableEquipment: List<String>.from(map['availableEquipment'] ?? []),
      fitnessLevel: map['fitnessLevel'] ?? 'Beginner',
      hasTrainer: map['hasTrainer'] ?? false,
      formData: formDataMap,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'name': name,
      'email': email,
      'password': password,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'primaryGoal': primaryGoal,
      'weightGoal': weightGoal,
      'targetWeight': targetWeight,
      'goalTimeline': goalTimeline,
      'sleepHours': sleepHours,
      'bedtime': bedtime,
      'wakeupTime': wakeupTime,
      'sleepIssues': sleepIssues,
      'dietaryPreferences': dietaryPreferences,
      'waterIntake': waterIntake,
      'medicalConditions': medicalConditions,
      'otherMedicalCondition': otherMedicalCondition,
      'preferredWorkouts': preferredWorkouts,
      'workoutFrequency': workoutFrequency,
      'workoutDuration': workoutDuration,
      'workoutLocation': workoutLocation,
      'availableEquipment': availableEquipment,
      'fitnessLevel': fitnessLevel,
      'hasTrainer': hasTrainer,
      'bmi': formData.containsKey('bmi') ? (formData['bmi'] is num ? formData['bmi'] : double.tryParse(formData['bmi'].toString()) ?? 0.0) : 0.0,
      'bmr': formData.containsKey('bmr') ? (formData['bmr'] is num ? formData['bmr'] : double.tryParse(formData['bmr'].toString()) ?? 0.0) : 0.0,
      'tdee': formData.containsKey('tdee') ? (formData['tdee'] is num ? formData['tdee'] : double.tryParse(formData['tdee'].toString()) ?? 0.0) : 0.0,
    };
    
    return map;
  }

  // Add method to convert to unified backend onboarding format
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
        'activityLevel': activityLevel,
        'bmi': formData['bmi'] ?? 0.0,
        'bmr': formData['bmr'] ?? 0.0,
        'tdee': formData['tdee'] ?? 0.0,
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

  // Update copyWith to include new fields
  UserProfile copyWith({
    String? name,
    String? email,
    String? password,
    String? gender,
    int? age,
    double? height,
    double? weight,
    String? activityLevel,
    String? primaryGoal,
    String? weightGoal,
    double? targetWeight,
    String? goalTimeline,
    double? sleepHours,
    String? bedtime,
    String? wakeupTime,
    List<String>? sleepIssues,
    List<String>? dietaryPreferences,
    double? waterIntake,
    List<String>? medicalConditions,
    String? otherMedicalCondition,
    List<String>? preferredWorkouts,
    int? workoutFrequency,
    int? workoutDuration,
    String? workoutLocation,
    List<String>? availableEquipment,
    String? fitnessLevel,
    bool? hasTrainer,
    Map<String, dynamic>? formData,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      weightGoal: weightGoal ?? this.weightGoal,
      targetWeight: targetWeight ?? this.targetWeight,
      goalTimeline: goalTimeline ?? this.goalTimeline,
      sleepHours: sleepHours ?? this.sleepHours,
      bedtime: bedtime ?? this.bedtime,
      wakeupTime: wakeupTime ?? this.wakeupTime,
      sleepIssues: sleepIssues ?? this.sleepIssues,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      waterIntake: waterIntake ?? this.waterIntake,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      otherMedicalCondition: otherMedicalCondition ?? this.otherMedicalCondition,
      preferredWorkouts: preferredWorkouts ?? this.preferredWorkouts,
      workoutFrequency: workoutFrequency ?? this.workoutFrequency,
      workoutDuration: workoutDuration ?? this.workoutDuration,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      hasTrainer: hasTrainer ?? this.hasTrainer,
      formData: formData ?? this.formData,
    );
  }
  
  @override
  String toString() {
    return 'UserProfile(name: $name, email: $email, age: $age, primaryGoal: $primaryGoal)';
  }
}