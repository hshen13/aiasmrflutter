from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from .routers.auth import router as auth_router
from .routers.characters import router as characters_router
from .routers.chat import router as chat_router
from .routers.ai import router as ai_router
from .routers.tts import router as tts_router
from .routers.audio import router as audio_router
import logging
from .database import engine, Base, cleanup_db, check_db_connection
from .config import settings
import uvicorn
from contextlib import asynccontextmanager
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def startup():
    """Application startup tasks"""
    logger.info("Starting up application...")
    # Drop all tables and recreate them
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables dropped and recreated successfully")
    
    # Create default admin user and initialize tracks
    from .database import SessionLocal
    from .routers.auth import create_default_admin
    from .init_data import init_default_data
    db = SessionLocal()
    try:
        create_default_admin(db)
        init_default_data(db)
        logger.info("Default tracks initialized successfully")
    finally:
        db.close()

def shutdown():
    """Application shutdown tasks"""
    logger.info("Shutting down application...")
    cleanup_db()
    logger.info("Cleanup completed")

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifecycle manager for the FastAPI application.
    Handles startup and shutdown events.
    """
    startup()
    yield
    shutdown()

# Create FastAPI application
app = FastAPI(
    title=settings.PROJECT_NAME,
    description="AI-powered ASMR chat application API",
    version=settings.VERSION,
    lifespan=lifespan,
    docs_url="/docs" if settings.ENABLE_DOCS else None,
    redoc_url="/redoc" if settings.ENABLE_REDOC else None,
)

# Mount static files directory
import os
base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
static_dir = os.path.join(base_dir, "static")
app.mount("/static", StaticFiles(directory=static_dir), name="static")

# Parse allowed origins from environment variable
allowed_origins = settings.ALLOWED_ORIGINS.split(',') if settings.ALLOWED_ORIGINS else ["*"]
logger.info(f"Configured CORS allowed origins: {allowed_origins}")

# Configure CORS with more detailed settings
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=[
        "Content-Type",
        "Accept",
        "Accept-Language",
        "Authorization",
        "X-Requested-With",
        "Access-Control-Allow-Origin",
        "Access-Control-Allow-Headers",
        "Access-Control-Allow-Methods",
        "Access-Control-Allow-Credentials",
        "Access-Control-Max-Age",
        "Origin",
    ],
    expose_headers=[
        "Content-Length",
        "Content-Type",
        "Authorization",
    ],
    max_age=3600,
)

# Register routers with prefix
api_prefix = "/api/v1"
app.include_router(auth_router, prefix=f"{api_prefix}/auth", tags=["Authentication"])
app.include_router(characters_router, prefix=f"{api_prefix}/characters", tags=["Characters"])
app.include_router(chat_router, prefix=f"{api_prefix}/chats", tags=["Chats"])
app.include_router(ai_router, prefix=f"{api_prefix}/ai", tags=["AI"])
app.include_router(tts_router, prefix=f"{api_prefix}/tts", tags=["Text-to-Speech"])
app.include_router(audio_router, prefix=f"{api_prefix}/audio", tags=["Audio"])

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all incoming requests and their processing time"""
    import time
    
    start_time = time.time()
    
    # Log request details
    logger.info(f"Request started: {request.method} {request.url}")
    logger.info(f"Client IP: {request.client.host}")
    logger.info(f"Headers: {dict(request.headers)}")
    logger.info(f"Origin: {request.headers.get('origin', 'Not provided')}")

    try:
        # Process request
        response = await call_next(request)
        
        # Log response details
        process_time = (time.time() - start_time) * 1000
        logger.info(f"Request completed: {response.status_code} ({process_time:.2f}ms)")
        
        # Add CORS headers for error responses
        if response.status_code >= 400:
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Credentials"] = "true"
        
        return response
    except Exception as e:
        # Log any unhandled exceptions
        logger.error(f"Request failed: {str(e)}", exc_info=True)
        raise

@app.get("/")
async def root():
    """Root endpoint for API health check"""
    return {
        "status": "healthy",
        "version": settings.VERSION,
        "docs_url": "/docs" if settings.ENABLE_DOCS else None
    }

@app.get("/ping")
async def ping():
    """Simple ping endpoint for connection testing"""
    return {
        "status": "ok",
        "message": "pong",
        "timestamp": str(datetime.utcnow())
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Try to connect to the database
        db_status = "healthy" if check_db_connection() else "unhealthy"
        
        # Return 200 only if database is healthy
        if db_status == "healthy":
            return {
                "status": "healthy",
                "database": db_status,
                "version": settings.VERSION,
                "timestamp": str(datetime.utcnow())
            }
        else:
            return Response(
                content=f"Database connection failed: {db_status}",
                status_code=503,
                headers={
                    "Content-Type": "text/plain",
                    "Access-Control-Allow-Origin": "*",
                }
            )
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}", exc_info=True)
        return Response(
            content=f"Health check failed: {str(e)}",
            status_code=503,
            headers={
                "Content-Type": "text/plain",
                "Access-Control-Allow-Origin": "*",
            }
        )

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler for unhandled exceptions"""
    logger.exception("Unhandled exception:")
    return Response(
        content=f"Internal server error: {str(exc)}",
        status_code=500,
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Credentials": "true",
            "Content-Type": "text/plain"
        }
    )

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        workers=settings.WORKERS if not settings.DEBUG else 1,
        log_level=settings.LOG_LEVEL.lower(),
        access_log=True,
        timeout_keep_alive=settings.KEEP_ALIVE,
        timeout_graceful_shutdown=settings.GRACEFUL_TIMEOUT,
    )
