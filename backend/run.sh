#!/bin/bash

echo "Starting AIASMR Backend Server..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python3 is not installed"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install or upgrade pip
python3 -m pip install --upgrade pip

# Install requirements
echo "Installing dependencies..."
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cp .env.example .env
fi

# Make sure the script is executable
chmod +x run.py

# Run the server
echo "Starting server..."
python3 run.py

# Deactivate virtual environment on exit
deactivate
