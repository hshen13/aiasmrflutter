from fastapi import APIRouter, HTTPException, Depends, Request, Response
from fastapi.security import OAuth2PasswordBearer
from fastapi.responses import JSONResponse
from datetime import datetime, timedelta
import jwt
from passlib.context import CryptContext
from typing import Dict, Optional
import logging
import json
import urllib.parse
import re
from sqlalchemy.orm import Session
from ..database import get_db
from ..models.database import User
from ..config import settings

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

router = APIRouter()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# Validation patterns
USERNAME_PATTERN = re.compile(r'^[a-zA-Z0-9_-]{3,20}$')
PASSWORD_MIN_LENGTH = 8

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: Dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: Dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def validate_username(username: str) -> bool:
    return bool(USERNAME_PATTERN.match(username))

def validate_password(password: str) -> bool:
    return len(password) >= PASSWORD_MIN_LENGTH

# Create default admin user
def create_default_admin(db: Session):
    admin = db.query(User).filter(User.username == "fffft").first()
    if not admin:
        hashed_password = get_password_hash("adminadmin")
        admin = User(
            username="fffft",
            hashed_password=hashed_password,
            avatar_url="https://ui-avatars.com/api/?name=Kafka&background=random&size=200",
        )
        db.add(admin)
        db.commit()
        logger.info("Created Kafka user")

from ..schemas.auth import LoginRequest, LoginResponse, UserResponse, UserCreate

@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    try:
        logger.info(f"Received login request for user: {request.username}")
        
        if not request.username or not request.password:
            logger.warning("Login attempt with empty username or password")
            raise HTTPException(status_code=400, detail="用户名和密码不能为空")

        user = db.query(User).filter(User.username == request.username).first()
        if not user:
            logger.warning(f"Login attempt for non-existent user: {request.username}")
            raise HTTPException(status_code=400, detail="用户名或密码错误")
            
        if not verify_password(request.password, user.hashed_password):
            logger.warning(f"Failed login attempt for user: {request.username} (invalid password)")
            raise HTTPException(status_code=400, detail="用户名或密码错误")
        
        access_token = create_access_token({"sub": user.username})
        refresh_token = create_refresh_token({"sub": user.username})
        logger.info(f"Login successful for user: {request.username}")
        
        # Create UserResponse
        user_response = UserResponse(
            id=user.id,
            username=user.username,
            is_active=user.is_active,
            avatar_url=user.avatar_url,
            created_at=user.created_at,
            updated_at=user.updated_at
        )
        
        # Create LoginResponse
        response = LoginResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            user=user_response
        )
        logger.info(f"Created login response for user: {request.username}")
        return response

    except HTTPException as he:
        logger.error(f"HTTP error during login: {str(he)}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error during login: {str(e)}", exc_info=True)
        logger.error(f"Error type: {type(e)}")
        logger.error(f"Error args: {e.args}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/signup", response_model=LoginResponse)
async def register(request: UserCreate, db: Session = Depends(get_db)):
    try:
        logger.info(f"Received register request for username: {request.username}")
        
        if not request.username or not request.password:
            logger.warning("Registration attempt with empty username or password")
            raise HTTPException(status_code=400, detail="用户名和密码不能为空")

        if not validate_username(request.username):
            logger.warning(f"Invalid username format: {request.username}")
            raise HTTPException(
                status_code=400,
                detail="用户名只能包含字母、数字、下划线和连字符，长度在3-20个字符之间"
            )

        if not validate_password(request.password):
            logger.warning("Password too short")
            raise HTTPException(
                status_code=400,
                detail=f"密码长度不能少于{PASSWORD_MIN_LENGTH}个字符"
            )
        
        if db.query(User).filter(User.username == request.username).first():
            logger.warning(f"Username already exists: {request.username}")
            raise HTTPException(status_code=400, detail="用户名已存在")
        
        hashed_password = get_password_hash(request.password)
        user = User(
            username=request.username,
            hashed_password=hashed_password,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        
        access_token = create_access_token({"sub": user.username})
        refresh_token = create_refresh_token({"sub": user.username})
        logger.info(f"Registration successful for user: {request.username}")
        
        # Create UserResponse
        user_response = UserResponse(
            id=user.id,
            username=user.username,
            is_active=user.is_active,
            avatar_url=user.avatar_url,
            created_at=user.created_at,
            updated_at=user.updated_at
        )
        
        # Create LoginResponse
        return LoginResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            user=user_response
        )

    except HTTPException as he:
        logger.error(f"HTTP error during registration: {str(he)}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error during registration: {str(e)}", exc_info=True)
        logger.error(f"Error type: {type(e)}")
        logger.error(f"Error args: {e.args}")
        try:
            # Try to get more details about the database state
            logger.error(f"Current database session state: {db.is_active}")
            existing_user = db.query(User).filter(User.username == request.username).first()
            logger.error(f"Existing user check result: {existing_user is not None}")
        except Exception as inner_e:
            logger.error(f"Error while checking database state: {str(inner_e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/profile")
async def read_users_me(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username = payload.get("sub")
        if username is None:
            logger.warning("Invalid token: no username found")
            raise HTTPException(status_code=401, detail="无效的认证凭据")
    except jwt.ExpiredSignatureError:
        logger.warning("Token has expired")
        raise HTTPException(status_code=401, detail="认证凭据已过期")
    except jwt.JWTError as e:
        logger.error(f"JWT decode error: {str(e)}")
        raise HTTPException(status_code=401, detail="无效的认证凭据")
    
    user = db.query(User).filter(User.username == username).first()
    if user is None:
        logger.warning(f"User not found: {username}")
        raise HTTPException(status_code=401, detail="用户不存在")
    
    logger.info(f"User info retrieved: {username}")
    
    # Create UserResponse
    user_response = UserResponse(
        id=user.id,
        username=user.username,
        is_active=user.is_active,
        avatar_url=user.avatar_url,
        created_at=user.created_at,
        updated_at=user.updated_at
    )
    
    return user_response

@router.post("/logout")
async def logout(token: str = Depends(oauth2_scheme)):
    try:
        # Verify the token is valid
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username = payload.get("sub")
        if username is None:
            logger.warning("Invalid token during logout: no username found")
            raise HTTPException(status_code=401, detail="Invalid authentication token")
        
        logger.info(f"User {username} logged out successfully")
        return {"message": "Successfully logged out"}
    except jwt.ExpiredSignatureError:
        logger.warning("Token has expired during logout")
        return {"message": "Successfully logged out"}  # Allow logout even with expired token
    except jwt.JWTError as e:
        logger.error(f"JWT decode error during logout: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid authentication token")
    except Exception as e:
        logger.error(f"Unexpected error during logout: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/verify")
async def verify_token(request: Request, db: Session = Depends(get_db)):
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            logger.warning("No Bearer token in Authorization header")
            raise HTTPException(status_code=401, detail="Missing authentication token")
        
        token = auth_header.split(' ')[1]
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username = payload.get("sub")
        if username is None:
            logger.warning("Invalid token: no username found")
            raise HTTPException(status_code=401, detail="Invalid authentication token")
        
        user = db.query(User).filter(User.username == username).first()
        if user is None:
            logger.warning(f"User not found: {username}")
            raise HTTPException(status_code=401, detail="User not found")
        
        return Response(status_code=200)
        
    except jwt.ExpiredSignatureError:
        logger.warning("Token has expired")
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.JWTError as e:
        logger.error(f"JWT decode error: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid authentication token")
    except Exception as e:
        logger.error(f"Unexpected error during token verification: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/refresh")
async def refresh_token(
    refresh_token: str,
    db: Session = Depends(get_db)
):
    try:
        payload = jwt.decode(refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        if payload.get("type") != "refresh":
            logger.warning("Invalid token type for refresh")
            raise HTTPException(status_code=401, detail="无效的刷新令牌")
        
        username = payload.get("sub")
        if not username:
            logger.warning("No username in refresh token")
            raise HTTPException(status_code=401, detail="无效的刷新令牌")
        
        user = db.query(User).filter(User.username == username).first()
        if not user:
            logger.warning(f"User not found during refresh: {username}")
            raise HTTPException(status_code=401, detail="用户不存在")
        
        new_access_token = create_access_token({"sub": username})
        new_refresh_token = create_refresh_token({"sub": username})
        
        logger.info(f"Tokens refreshed for user: {username}")
        
        return {
            "access_token": new_access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer"
        }
        
    except jwt.ExpiredSignatureError:
        logger.warning("Refresh token has expired")
        raise HTTPException(status_code=401, detail="刷新令牌已过期")
    except jwt.JWTError as e:
        logger.error(f"JWT decode error during refresh: {str(e)}")
        raise HTTPException(status_code=401, detail="无效的刷新令牌")
    except Exception as e:
        logger.error(f"Unexpected error during token refresh: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")
