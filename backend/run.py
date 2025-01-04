import os
import sys
import uvicorn
from dotenv import load_dotenv

# Add the backend directory to the Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

# Load environment variables
env_path = os.path.join(current_dir, '.env')
load_dotenv(dotenv_path=env_path)

if __name__ == "__main__":
    # Run the FastAPI application
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",  # Listen on all available interfaces
        port=8000,
        reload=True,  # Enable auto-reload for development
        workers=1,  # Use single worker in development
        log_level="info",
        access_log=True,
        proxy_headers=True,  # Trust proxy headers
        forwarded_allow_ips="*",  # Trust forwarded IP headers
        reload_dirs=[os.path.join(current_dir, "app")]  # Watch app directory for changes
    )
