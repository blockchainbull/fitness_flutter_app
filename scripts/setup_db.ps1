# PostgreSQL setup script for Health AI app in PowerShell
# Usage: .\setup_db.ps1 [hostname] [port] [username] [password]

param (
    [string]$Hostname = "localhost",
    [string]$Port = "5432",
    [string]$Username = "postgres",
    [string]$Password = $null
)

$PSQL = 'C:\Program Files\PostgreSQL\17\bin\psql.exe'
$DB_NAME = "health_ai_db"
$APP_USER = "health_ai_user"
$APP_PASSWORD = "health_ai_password"

Write-Host "PostgreSQL Server Setup for Health AI App"
Write-Host "-----------------------------------------"
Write-Host "Host: $Hostname"
Write-Host "Port: $Port"
Write-Host "Admin Username: $Username"
Write-Host "Creating database '$DB_NAME'..."

# Set PGPASSWORD environment variable
$env:PGPASSWORD = $Password

# Create database
& $PSQL -h $Hostname -p $Port -U $Username -c "DROP DATABASE IF EXISTS $DB_NAME;"
& $PSQL -h $Hostname -p $Port -U $Username -c "CREATE DATABASE $DB_NAME;"

Write-Host "Creating user '$APP_USER'..."
# Create user
& $PSQL -h $Hostname -p $Port -U $Username -c "DROP USER IF EXISTS $APP_USER;"
& $PSQL -h $Hostname -p $Port -U $Username -c "CREATE USER $APP_USER WITH ENCRYPTED PASSWORD '$APP_PASSWORD';"

Write-Host "Granting privileges..."
# Grant privileges
& $PSQL -h $Hostname -p $Port -U $Username -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $APP_USER;"

Write-Host "Creating tables..."
# Connect to the new database and create tables
& $PSQL -h $Hostname -p $Port -U $Username -d $DB_NAME -c @"
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
);

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
);

CREATE TABLE IF NOT EXISTS sleep_info (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  sleep_hours DECIMAL,
  bedtime VARCHAR(10),
  wakeup_time VARCHAR(10),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sleep_issues (
  id UUID PRIMARY KEY,
  sleep_id UUID NOT NULL,
  issue VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (sleep_id) REFERENCES sleep_info(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS dietary_preferences (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  preference VARCHAR(100),
  water_intake DECIMAL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS medical_conditions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  condition VARCHAR(100),
  other_condition TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS workout_preferences (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  workout_type VARCHAR(100),
  workout_frequency INTEGER,
  workout_duration INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS exercise_setup (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  workout_location VARCHAR(100),
  fitness_level VARCHAR(50),
  has_trainer BOOLEAN,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS equipment (
  id UUID PRIMARY KEY,
  exercise_id UUID NOT NULL,
  equipment_name VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (exercise_id) REFERENCES exercise_setup(id) ON DELETE CASCADE
);
"@

Write-Host "Granting table privileges..."
# Grant table privileges to the app user
& $PSQL -h $Hostname -p $Port -U $Username -d $DB_NAME -c @"
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $APP_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $APP_USER;
"@

# Clear PGPASSWORD for security
$env:PGPASSWORD = ""

Write-Host "Database setup completed successfully!"
Write-Host ""
Write-Host "Database: $DB_NAME"
Write-Host "User: $APP_USER"
Write-Host "Password: $APP_PASSWORD"
Write-Host ""
Write-Host "Update your .env file with these credentials."