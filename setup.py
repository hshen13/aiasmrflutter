import os
import sys
import json
from pathlib import Path

def create_env_file():
    """Create .env file with OpenAI API key."""
    if os.path.exists('.env'):
        print(".env file already exists. Skipping...")
        return

    api_key = input("Enter your OpenAI API key: ").strip()
    
    with open('.env', 'w') as f:
        f.write(f"OPENAI_API_KEY={api_key}\n")
    
    print("Created .env file with OpenAI API key")

def verify_google_credentials():
    """Verify Google Cloud credentials file."""
    creds_file = Path('service_account.json')
    
    if creds_file.exists():
        print("Google Cloud credentials file already exists. Skipping...")
        return
    
    print("\nGoogle Cloud Text-to-Speech Setup Instructions:")
    print("1. Go to Google Cloud Console (https://console.cloud.google.com)")
    print("2. Create a new project or select existing project")
    print("3. Enable Text-to-Speech API")
    print("4. Create a service account and download JSON key")
    print("5. Save the JSON key as 'service_account.json' in this directory")
    
    input("\nPress Enter once you've saved the service_account.json file...")
    
    if not creds_file.exists():
        print("Error: service_account.json not found!")
        sys.exit(1)
    
    # Validate JSON format
    try:
        with open(creds_file) as f:
            json.load(f)
        print("Google Cloud credentials file verified successfully")
    except json.JSONDecodeError:
        print("Error: Invalid JSON in service_account.json")
        sys.exit(1)

def main():
    print("Setting up AI ASMR Helper App...\n")
    
    create_env_file()
    print()
    verify_google_credentials()
    
    print("\nSetup completed successfully!")
    print("\nNext steps:")
    print("1. Start the backend:")
    print("   docker-compose up -d")
    print("2. Start the Flutter app:")
    print("   cd frontend")
    print("   flutter run")

if __name__ == '__main__':
    main()
