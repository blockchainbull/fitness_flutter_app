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
  final String activityLevel;
  
  final bool? hasPeriods;
  final String? lastPeriodDate;
  final int? cycleLength;
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
    required this.id,
    required this.name,
    required this.email,
    this.password, 
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevel,
    
    this.hasPeriods,
    this.lastPeriodDate,
    this.cycleLength,
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
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'],
      gender: map['gender'] ?? '',
      age: map['age'] ?? 0,
      height: map['height']?.toDouble() ?? 0.0,
      weight: map['weight']?.toDouble() ?? 0.0,
      activityLevel: map['activityLevel'] ?? '',
      
      hasPeriods: map['hasPeriods'],
      lastPeriodDate: map['lastPeriodDate'],
      cycleLength: map['cycleLength'],
      cycleLengthRegular: map['cycleLengthRegular'],
      pregnancyStatus: map['pregnancyStatus'],
      periodTrackingPreference: map['periodTrackingPreference'],
      
      primaryGoal: map['primaryGoal'] ?? '',
      weightGoal: map['weightGoal'] ?? '',
      targetWeight: map['targetWeight']?.toDouble() ?? 0.0,
      goalTimeline: map['goalTimeline'],
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

  static UserProfile fromApiResponse(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      password: data['password'],
      gender: data['gender'] ?? '',
      age: data['age'] ?? 0,
      height: (data['height'] ?? 0.0).toDouble(),
      weight: (data['weight'] ?? 0.0).toDouble(),
      activityLevel: data['activityLevel'] ?? '',
      
      hasPeriods: data['hasPeriods'] ?? data['has_periods'],
      lastPeriodDate: data['lastPeriodDate'] ?? data['last_period_date'],
      cycleLength: data['cycleLength'] ?? data['cycle_length'],
      cycleLengthRegular: data['cycleLengthRegular'] ?? data['cycle_length_regular'],
      pregnancyStatus: data['pregnancyStatus'] ?? data['pregnancy_status'],
      periodTrackingPreference: data['periodTrackingPreference'] ?? data['period_tracking_preference'],
      
      primaryGoal: data['primaryGoal'] ?? '',
      weightGoal: data['weightGoal'] ?? '',
      targetWeight: (data['targetWeight'] ?? 0.0).toDouble(),
      goalTimeline: data['goalTimeline'],
      sleepHours: (data['sleepHours'] ?? 7.0).toDouble(),
      bedtime: data['bedtime'] ?? '22:00',
      wakeupTime: data['wakeupTime'] ?? '06:00',
      sleepIssues: List<String>.from(data['sleepIssues'] ?? []),
      dietaryPreferences: List<String>.from(data['dietaryPreferences'] ?? []),
      waterIntake: (data['waterIntake'] ?? 2.0).toDouble(),
      medicalConditions: List<String>.from(data['medicalConditions'] ?? []),
      otherMedicalCondition: data['otherMedicalCondition'] ?? '',
      preferredWorkouts: List<String>.from(data['preferredWorkouts'] ?? []),
      workoutFrequency: data['workoutFrequency'] ?? 3,
      workoutDuration: data['workoutDuration'] ?? 30,
      workoutLocation: data['workoutLocation'] ?? '',
      availableEquipment: List<String>.from(data['availableEquipment'] ?? []),
      fitnessLevel: data['fitnessLevel'] ?? 'Beginner',
      hasTrainer: data['hasTrainer'] ?? false,
      formData: {
        'bmi': data['bmi'] ?? 0.0,
        'bmr': data['bmr'] ?? 0.0,
        'tdee': data['tdee'] ?? 0.0,
      },
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
      'activityLevel': activityLevel,
      
      'hasPeriods': hasPeriods,
      'lastPeriodDate': lastPeriodDate,
      'cycleLength': cycleLength,
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
      if (gender.toLowerCase() == 'female' && hasPeriods != null)
        'periodCycle': {
          'hasPeriods': hasPeriods,
          'lastPeriodDate': lastPeriodDate,
          'cycleLength': cycleLength,
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
    String? activityLevel,
    
    bool? hasPeriods,
    String? lastPeriodDate,
    int? cycleLength,
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
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      
      hasPeriods: hasPeriods ?? this.hasPeriods,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      cycleLength: cycleLength ?? this.cycleLength,
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