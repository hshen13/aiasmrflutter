# AI ASMR Flutter App

A modern Flutter application with FastAPI backend for AI-powered ASMR content creation and chat interactions.

## Features

- 🎵 ASMR Content Feed (Twitter-style)
- 💬 AI Chat with Voice Support
- 🔄 Offline Support & Local Caching
- 🎙️ Voice Recording & Playback
- 🤖 AI-powered Responses
- 🌐 WebSocket Real-time Communication

## Architecture

### Frontend (Flutter)
- Modern UI with Material Design
- Provider for state management
- Hive for local storage
- WebSocket for real-time chat
- Offline-first architecture

### Backend (FastAPI)
- RESTful API with FastAPI
- PostgreSQL database
- OpenAI GPT integration
- WebSocket support
- JWT authentication

### Infrastructure
- Docker containerization
- NGINX reverse proxy
- PostgreSQL database
- Scalable microservices architecture

## Prerequisites

- Docker & Docker Compose
- Flutter SDK (for development)
- Python 3.9+ (for development)
- OpenAI API key

## Quick Start

### Using Docker (Recommended)

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/aiasmrflutter.git
   cd aiasmrflutter
   ```

2. Run the setup script:
   - Windows:
     ```bash
     setup.bat
     ```
   - Linux/macOS:
     ```bash
     chmod +x setup.sh
     ./setup.sh
     ```

3. Update the `.env` file with your configuration.

4. Start the application:
   ```bash
   docker-compose up
   ```

5. Access the application:
   - Frontend: http://localhost:80
   - Backend API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs

### Manual Development Setup

1. Frontend Setup:
   ```bash
   cd frontend
   flutter pub get
   flutter run -d chrome
   ```

2. Backend Setup:
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   python run.py
   ```

## Project Structure

```
.
├── frontend/                 # Flutter application
│   ├── lib/                 # Application code
│   ├── assets/             # Static assets
│   └── test/               # Test files
├── backend/                 # FastAPI backend
│   ├── app/                # Application code
│   ├── tests/              # Test files
│   └── requirements.txt    # Python dependencies
├── nginx/                  # NGINX configuration
├── docker-compose.yml      # Docker compose configuration
└── README.md              # Project documentation
```

## Configuration

The application uses environment variables for configuration. Copy `.env.example` to `.env` and update the values:

- `OPENAI_API_KEY`: Your OpenAI API key
- `DATABASE_URL`: PostgreSQL connection string
- `SECRET_KEY`: JWT secret key
- Other configuration variables...

## Development

### Code Style

- Frontend: Follow Flutter/Dart style guide
- Backend: Follow PEP 8 style guide

### Testing

- Frontend:
  ```bash
  cd frontend
  flutter test
  ```

- Backend:
  ```bash
  cd backend
  pytest
  ```

## Deployment

1. Update environment variables in `.env`
2. Build and start containers:
   ```bash
   docker-compose up -d
   ```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
