#!/bin/bash

echo "Setting up AI ASMR project..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create .env file from example if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "Please update the .env file with your actual configuration values."
fi

# Create necessary directories
mkdir -p backend/data
mkdir -p frontend/data

# Set execute permissions for scripts
chmod +x backend/run.sh
chmod +x frontend/build.sh

# Pull and build Docker images
echo "Building Docker images..."
docker-compose build

echo
echo "Setup completed successfully!"
echo
echo "Next steps:"
echo "1. Update the .env file with your configuration values"
echo "2. Run 'docker-compose up' to start the application"
echo "3. Access the application at http://localhost:80"
echo
echo "For development:"
echo "- Frontend development server: http://localhost:8080"
echo "- Backend API: http://localhost:8000"
echo "- API Documentation: http://localhost:8000/docs"
echo
