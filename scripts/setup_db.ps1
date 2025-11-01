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
-- Main users table with all profile information including password
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  gender VARCHAR(10),
  age INTEGER,
  height DECIMAL,
  weight DECIMAL,
  activity_level VARCHAR(100),
  bmi DECIMAL,
  bmr DECIMAL,
  tdee DECIMAL,
  
  -- Goal information
  primary_goal VARCHAR(100),
  weight_goal VARCHAR(100),
  target_weight DECIMAL,
  
  -- Sleep information
  sleep_hours DECIMAL,
  bedtime VARCHAR(10),
  wakeup_time VARCHAR(10),
  sleep_issues TEXT[],
  
  -- Dietary information
  dietary_preferences TEXT[],
  water_intake DECIMAL,
  
  -- Medical information
  medical_conditions TEXT[],
  other_medical_condition TEXT,
  
  -- Exercise information
  preferred_workouts TEXT[],
  workout_frequency INTEGER,
  workout_duration INTEGER,
  workout_location VARCHAR(100),
  available_equipment TEXT[],
  fitness_level VARCHAR(50),
  has_trainer BOOLEAN,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Daily tracking tables
CREATE TABLE IF NOT EXISTS daily_water_intake (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  date DATE NOT NULL,
  glasses_consumed INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(user_id, date)
);

CREATE TABLE IF NOT EXISTS daily_meals (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  date DATE NOT NULL,
  meal_name VARCHAR(100),
  description TEXT,
  calories INTEGER,
  meal_time VARCHAR(10),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS daily_exercises (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  date DATE NOT NULL,
  exercise_name VARCHAR(100),
  duration_minutes INTEGER,
  calories_burned INTEGER,
  exercise_time VARCHAR(10),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_password_hash ON users(password_hash);
CREATE INDEX IF NOT EXISTS idx_daily_water_user_date ON daily_water_intake(user_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_meals_user_date ON daily_meals(user_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_exercises_user_date ON daily_exercises(user_id, date);
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