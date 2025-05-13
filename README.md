# HealthAI Flutter App with PostgreSQL Integration

A Flutter-based health and fitness app with user onboarding that stores data in both PostgreSQL and local storage for offline support.

## Features

- User onboarding process with comprehensive health data collection
- PostgreSQL database integration for remote data storage
- Local storage with SharedPreferences for offline support
- Automatic data synchronization when online
- Connectivity status monitoring
- Multi-page onboarding flow
- Customizable user profiles
- Various health and fitness tracking widgets

## Prerequisites

- Flutter SDK (^3.7.2)
- PostgreSQL Server (v13 or higher recommended)
- Dart SDK

## PostgreSQL Setup

1. Install PostgreSQL on your server or use a PostgreSQL service provider
2. Create a database and user for the app using the provided setup script:

```bash
# Make the script executable
chmod +x scripts/setup_db.sh

# Run the script (default: localhost, 5432, postgres, postgres)
./scripts/setup_db.sh [hostname] [port] [username] [password]
```

3. Update the `.env` file with your database credentials:

```
DB_HOST=your_postgres_host
DB_PORT=5432
DB_NAME=health_ai_db
DB_USERNAME=health_ai_user
DB_PASSWORD=health_ai_password
```

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/yourusername/health_ai_app.git
cd health_ai_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create the `.env` file with your database configuration (see above)

4. Run the app:
```bash
flutter run
```

## Project Structure

- `lib/data/models/` - Data models
- `lib/data/repositories/` - Repository classes for database operations
- `lib/data/services/` - Services for database, connectivity, etc.
- `lib/features/` - App features organized by domain
  - `onboarding/` - User onboarding screens
  - `home/` - Home screen and widgets
  - `profile/` - User profile screens and widgets
  - `chat/` - AI coach chat feature

## Key Files

- `lib/data/services/database_service.dart` - PostgreSQL database connection service
- `lib/data/services/data_manager.dart` - Data storage and synchronization manager
- `lib/data/repositories/user_repository.dart` - Repository for user data operations
- `lib/data/services/connectivity_service.dart` - Network connectivity monitoring service
- `lib/features/onboarding/screens/onboarding_flow.dart` - Main onboarding flow with database integration

## Database Schema

The app uses the following database tables:

1. `users` - Basic user information (name, email, age, etc.)
2. `user_goals` - User's health and fitness goals
3. `sleep_info` - Sleep pattern information
4. `sleep_issues` - Sleep-related problems
5. `dietary_preferences` - User's dietary preferences and restrictions
6. `medical_conditions` - User's medical conditions
7. `workout_preferences` - Workout types, frequency, and duration
8. `exercise_setup` - Exercise-related settings
9. `equipment` - Available workout equipment

## Offline Support

The app supports offline usage through the following mechanisms:

1. All data is stored locally using SharedPreferences
2. When online, data is synchronized with the PostgreSQL database
3. The app monitors connectivity status and adjusts behavior accordingly
4. Visual indicators show the current connectivity status
5. Manual synchronization is available from the profile screen

## How Database Synchronization Works

1. During onboarding, user data is saved locally
2. If online, data is immediately sent to the PostgreSQL database
3. A user ID is stored locally for future synchronization
4. When the app starts, it checks if there's data to synchronize
5. The profile screen shows the current synchronization status
6. Users can manually trigger synchronization when online

## Customizing the Database Connection

If you need to modify the database connection settings:

1. Update the `.env` file with your database credentials
2. The `DatabaseService` class will automatically use these settings
3. For advanced configuration, modify `lib/data/services/database_service.dart`

## Security Considerations

- Database credentials are stored in the `.env` file, which is not committed to version control
- The app uses SSL for database connections
- User IDs are UUIDs for enhanced security

## Troubleshooting

- If you encounter database connection issues, check your PostgreSQL server and credentials
- Make sure the PostgreSQL server allows remote connections if not running locally
- Check firewall settings to ensure the app can access the PostgreSQL port
- If running on an emulator, use `10.0.2.2` as the host to connect to your local machine

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.