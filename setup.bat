@echo off
echo Setting up AI ASMR project...

REM Check if Docker is installed
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo Docker is not installed. Please install Docker Desktop first.
    exit /b 1
)

REM Check if Docker Compose is installed
docker-compose --version >nul 2>nul
if %errorlevel% neq 0 (
    echo Docker Compose is not installed. Please install Docker Desktop first.
    exit /b 1
)

REM Create .env file from example if it doesn't exist
if not exist .env (
    echo Creating .env file from .env.example...
    copy .env.example .env
    echo Please update the .env file with your actual configuration values.
)

REM Create necessary directories
if not exist backend\data mkdir backend\data
if not exist frontend\data mkdir frontend\data

REM Pull and build Docker images
echo Building Docker images...
docker-compose build

echo.
echo Setup completed successfully!
echo.
echo Next steps:
echo 1. Update the .env file with your configuration values
echo 2. Run 'docker-compose up' to start the application
echo 3. Access the application at http://localhost:80
echo.
echo For development:
echo - Frontend development server: http://localhost:8080
echo - Backend API: http://localhost:8000
echo - API Documentation: http://localhost:8000/docs
echo.
