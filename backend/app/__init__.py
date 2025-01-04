__version__ = "1.0.0"

# Import these after version to avoid circular imports
from .config import settings
from .database import engine, Base, get_db, cleanup_db

# Create tables
Base.metadata.create_all(bind=engine)
