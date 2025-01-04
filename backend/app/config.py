import os
from typing import Optional, List
from pydantic import BaseSettings, PostgresDsn, validator
import logging
from functools import lru_cache

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    # Server Settings
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    WORKERS: int = int(os.getenv("WORKERS", "1"))
    KEEP_ALIVE: int = int(os.getenv("KEEP_ALIVE", "5"))
    GRACEFUL_TIMEOUT: int = int(os.getenv("GRACEFUL_TIMEOUT", "30"))

    # API Settings
    API_V1_STR: str = ""
    PROJECT_NAME: str = "AIASMR API"
    VERSION: str = "1.0.0"
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"

    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-for-development")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
    REFRESH_TOKEN_EXPIRE_DAYS: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "7"))
    ALGORITHM: str = "HS256"

    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql://aiasmr:aiasmr@db:5432/aiasmr")
    DB_POOL_SIZE: int = int(os.getenv("DB_POOL_SIZE", "5"))
    DB_MAX_OVERFLOW: int = int(os.getenv("DB_MAX_OVERFLOW", "10"))
    DB_POOL_TIMEOUT: int = int(os.getenv("DB_POOL_TIMEOUT", "30"))
    DB_POOL_RECYCLE: int = int(os.getenv("DB_POOL_RECYCLE", "1800"))

    # CORS Settings
    ALLOWED_ORIGINS: str = os.getenv("ALLOWED_ORIGINS", "*")
    CORS_ORIGINS: str = os.getenv("ALLOWED_ORIGINS", "*")  # Fallback to ALLOWED_ORIGINS
    CORS_CREDENTIALS: bool = os.getenv("CORS_CREDENTIALS", "true").lower() == "true"
    CORS_METHODS: str = os.getenv("CORS_METHODS", "GET,POST,PUT,DELETE,OPTIONS,PATCH")
    CORS_HEADERS: str = os.getenv("CORS_HEADERS", "accept,accept-language,content-type,content-language,authorization,x-requested-with,x-csrf-token")

    @property
    def cors_origins_list(self) -> List[str]:
        origins = self.ALLOWED_ORIGINS or self.CORS_ORIGINS
        if origins == "*":
            logger.info("CORS configured to allow all origins (*)")
            return ["*"]
        origins_list = [origin.strip() for origin in origins.split(",")]
        logger.info(f"CORS configured with specific origins: {origins_list}")
        return origins_list

    @property
    def cors_methods_list(self) -> List[str]:
        methods = [method.strip() for method in self.CORS_METHODS.split(",")]
        logger.info(f"CORS configured with methods: {methods}")
        return methods

    @property
    def cors_headers_list(self) -> List[str]:
        if self.CORS_HEADERS == "*":
            logger.info("CORS configured to allow all headers (*)")
            return ["*"]
        headers = [header.strip() for header in self.CORS_HEADERS.split(",")]
        logger.info(f"CORS configured with headers: {headers}")
        return headers

    # OpenAI Settings
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-3.5-turbo")
    OPENAI_MAX_TOKENS: int = int(os.getenv("OPENAI_MAX_TOKENS", "150"))
    OPENAI_TEMPERATURE: float = float(os.getenv("OPENAI_TEMPERATURE", "0.7"))
    OPENAI_PRESENCE_PENALTY: float = float(os.getenv("OPENAI_PRESENCE_PENALTY", "0.0"))
    OPENAI_FREQUENCY_PENALTY: float = float(os.getenv("OPENAI_FREQUENCY_PENALTY", "0.0"))

    # ElevenLabs Settings
    ELEVENLABS_API_KEY: str = os.getenv("ELEVENLABS_API_KEY", "")
    ELEVENLABS_VOICE_ID: str = os.getenv("ELEVENLABS_VOICE_ID", "")
    ELEVENLABS_MODEL_ID: str = os.getenv("ELEVENLABS_MODEL_ID", "eleven_monolingual_v1")
    ELEVENLABS_OPTIMIZE_STREAMING: bool = os.getenv("ELEVENLABS_OPTIMIZE_STREAMING", "true").lower() == "true"
    ELEVENLABS_STABILITY: float = float(os.getenv("ELEVENLABS_STABILITY", "0.75"))
    ELEVENLABS_SIMILARITY_BOOST: float = float(os.getenv("ELEVENLABS_SIMILARITY_BOOST", "0.75"))

    # Cache Settings
    CACHE_DIR: str = os.getenv("CACHE_DIR", "./cache")
    CACHE_TTL: int = int(os.getenv("CACHE_TTL", "604800"))  # 7 days in seconds

    # Rate Limiting
    RATE_LIMIT_REQUESTS: int = int(os.getenv("RATE_LIMIT_REQUESTS", "100"))
    RATE_LIMIT_WINDOW: int = int(os.getenv("RATE_LIMIT_WINDOW", "3600"))  # 1 hour in seconds

    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    # Documentation
    ENABLE_DOCS: bool = os.getenv("ENABLE_DOCS", "true").lower() == "true"
    ENABLE_REDOC: bool = os.getenv("ENABLE_REDOC", "true").lower() == "true"

    class Config:
        case_sensitive = True
        env_file = ".env"

    @validator("DATABASE_URL")
    def validate_database_url(cls, v: str, values: dict) -> str:
        is_prod = not values.get("DEBUG", False)
        
        if not v:
            if is_prod:
                raise ValueError("Database URL must be provided in production")
            return "postgresql://aiasmr:aiasmr@db:5432/aiasmr"

        if is_prod and v.startswith("sqlite"):
            raise ValueError(
                "SQLite database is not supported in production. "
                "Please use PostgreSQL with a connection string like: "
                "postgresql://user:password@localhost:5432/dbname"
            )

        if v.startswith("postgresql://"):
            try:
                # Extract host from URL
                host = v.split("@")[1].split(":")[0]
                
                # If running in Docker, ensure we use the service name
                if host == "localhost" or host == "127.0.0.1":
                    v = v.replace(host, "db")
                    logger.info(f"Adjusted PostgreSQL URL for Docker: {v}")
                
                return v
            except Exception as e:
                raise ValueError(f"Invalid PostgreSQL URL: {str(e)}")
        
        if is_prod:
            raise ValueError("Only PostgreSQL is supported in production")
        
        return v

    @validator("OPENAI_API_KEY")
    def validate_openai_api_key(cls, v: str, values: dict) -> str:
        is_prod = not values.get("DEBUG", False)
        if not v and is_prod:
            raise ValueError("OpenAI API key must be provided in production")
        elif not v:
            logger.warning("OpenAI API key not set")
        elif not v.startswith(("sk-", "org-")):
            raise ValueError("Invalid OpenAI API key format")
        return v

    @validator("ELEVENLABS_API_KEY")
    def validate_elevenlabs_api_key(cls, v: str, values: dict) -> str:
        is_prod = not values.get("DEBUG", False)
        if not v and is_prod:
            raise ValueError("ElevenLabs API key must be provided in production")
        elif not v:
            logger.warning("ElevenLabs API key not set")
        return v

    @validator("ELEVENLABS_VOICE_ID")
    def validate_elevenlabs_voice_id(cls, v: str, values: dict) -> str:
        is_prod = not values.get("DEBUG", False)
        if not v and is_prod:
            raise ValueError("ElevenLabs voice ID must be provided in production")
        elif not v:
            logger.warning("ElevenLabs voice ID not set")
        return v

    @validator("ALLOWED_ORIGINS")
    def validate_allowed_origins(cls, v: str, values: dict) -> str:
        is_prod = not values.get("DEBUG", False)
        if v == "*" and is_prod:
            raise ValueError("Wildcard CORS origin (*) is not allowed in production")
        return v

    @validator("SECRET_KEY")
    def validate_secret_key(cls, v: str, values: dict) -> str:
        is_prod = not values.get("DEBUG", False)
        if v == "your-secret-key-here" or v == "your-secret-key-for-development":
            if is_prod:
                raise ValueError(
                    "Production environment detected but using default secret key. "
                    "Generate a secure key using: python -c 'import secrets; print(secrets.token_hex(32))'"
                )
            logger.warning("Using default secret key in development mode")
        elif len(v) < 32:
            raise ValueError("Secret key must be at least 32 characters long")
        return v

    @validator("CORS_METHODS")
    def validate_cors_methods(cls, v: str, values: dict) -> str:
        is_prod = not values.get("DEBUG", False)
        allowed_methods = {"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH", "HEAD"}
        methods = {m.strip().upper() for m in v.split(",")}
        
        if not methods.issubset(allowed_methods):
            invalid_methods = methods - allowed_methods
            raise ValueError(f"Invalid CORS methods: {invalid_methods}")
        
        if is_prod and "*" in methods:
            raise ValueError("Wildcard CORS method (*) is not allowed in production")
            
        return v

    @validator("CORS_HEADERS")
    def validate_cors_headers(cls, v: str, values: dict) -> str:
        is_prod = not values.get("DEBUG", False)
        if v == "*" and is_prod:
            raise ValueError("Wildcard CORS headers (*) is not allowed in production")
        
        # Standard secure headers that should be allowed
        secure_headers = {
            "accept", "accept-language", "content-type", "content-language",
            "authorization", "x-requested-with", "x-csrf-token"
        }
        
        headers = {h.strip().lower() for h in v.split(",")} if v != "*" else set()
        
        # In production, ensure all required secure headers are included
        if is_prod and not secure_headers.issubset(headers):
            missing_headers = secure_headers - headers
            raise ValueError(f"Required secure headers missing in production: {missing_headers}")
            
        return v

    @validator("DEBUG")
    def validate_debug_mode(cls, v: bool) -> bool:
        if v:
            logger.warning("Running in DEBUG mode - not recommended for production!")
        return v

    @validator("LOG_LEVEL")
    def validate_log_level(cls, v: str) -> str:
        valid_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
        if v.upper() not in valid_levels:
            raise ValueError(f"Invalid log level. Must be one of {valid_levels}")
        return v.upper()

@lru_cache()
def get_settings() -> Settings:
    """
    Get cached settings instance.
    The @lru_cache decorator ensures that the settings are only loaded once.
    """
    try:
        settings = Settings()
        logger.info("Loaded configuration settings")
        return settings
    except Exception as e:
        logger.error(f"Error loading configuration: {str(e)}")
        raise

# Initialize settings
settings = get_settings()

# Configure logging based on settings
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format=settings.LOG_FORMAT
)

# Log important configuration values (excluding sensitive data)
logger.info("=== Server Configuration ===")
logger.info(f"Host: {settings.HOST}")
logger.info(f"Port: {settings.PORT}")
logger.info(f"Debug Mode: {settings.DEBUG}")
logger.info(f"Workers: {settings.WORKERS}")

logger.info("\n=== API Configuration ===")
logger.info(f"Project Name: {settings.PROJECT_NAME}")
logger.info(f"Version: {settings.VERSION}")
logger.info(f"API Version: {settings.API_V1_STR}")

logger.info("\n=== CORS Configuration ===")
logger.info(f"Allowed Origins: {settings.cors_origins_list}")
logger.info(f"Allow Credentials: {settings.CORS_CREDENTIALS}")
logger.info(f"Allowed Methods: {settings.cors_methods_list}")
logger.info(f"Allowed Headers: {settings.cors_headers_list}")

logger.info("\n=== Database Configuration ===")
logger.info(f"Database Type: {'SQLite' if settings.DATABASE_URL.startswith('sqlite') else 'PostgreSQL'}")
logger.info(f"Pool Size: {settings.DB_POOL_SIZE}")
logger.info(f"Max Overflow: {settings.DB_MAX_OVERFLOW}")

logger.info("\n=== Performance Configuration ===")
logger.info(f"Rate Limit: {settings.RATE_LIMIT_REQUESTS} requests per {settings.RATE_LIMIT_WINDOW} seconds")
logger.info(f"Cache TTL: {settings.CACHE_TTL} seconds")
logger.info(f"Keep Alive: {settings.KEEP_ALIVE} seconds")
logger.info(f"Graceful Timeout: {settings.GRACEFUL_TIMEOUT} seconds")

logger.info("\n=== Logging Configuration ===")
logger.info(f"Log Level: {settings.LOG_LEVEL}")
