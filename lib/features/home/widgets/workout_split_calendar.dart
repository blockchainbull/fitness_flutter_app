import 'package:flutter/material.dart';

class WorkoutSplitCalendar extends StatelessWidget {
  final List<Map<String, dynamic>> weekSchedule;
  final int currentDayIndex;
  
  const WorkoutSplitCalendar({
    Key? key,
    required this.weekSchedule,
    this.currentDayIndex = 0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final List<String> dayAbbreviations = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.deepPurple,
              ),
              SizedBox(width: 8),
              Text(
                'Weekly Training Split',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Day indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isCurrentDay = index == currentDayIndex;
              return _buildDayCircle(
                dayAbbreviations[index],
                isCurrentDay,
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          // Workout cards for each day
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: PageView.builder(
              controller: PageController(initialPage: currentDayIndex),
              itemCount: 7,
              itemBuilder: (context, index) {
                final dayData = weekSchedule[index];
                return _buildDayWorkout(dayData);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDayCircle(String day, bool isCurrentDay) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrentDay ? Colors.deepPurple : Colors.grey[200],
      ),
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            color: isCurrentDay ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildDayWorkout(Map<String, dynamic> dayData) {
    final String muscleGroup = dayData['muscleGroup'];
    final bool isRestDay = dayData['isRestDay'] ?? false;
    final List<String> exercises = List<String>.from(dayData['exercises'] ?? []);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: isRestDay
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.hotel,
                  color: Colors.blue,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rest Day',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Focus on recovery today',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  muscleGroup,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: exercises.isEmpty
                      ? const Center(
                          child: Text(
                            'No exercises scheduled',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: exercises.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.fitness_center,
                                    size: 14,
                                    color: Colors.deepPurple,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    exercises[index],
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}