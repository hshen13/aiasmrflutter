from fastapi import APIRouter, HTTPException, Depends, Request, Response
from fastapi.responses import JSONResponse
from typing import List, Optional
import logging
from ..auth.auth import get_current_user, get_current_user_optional
from ..models.database import Character, User
from ..schemas.character import CharacterCreate, CharacterUpdate, CharacterResponse
from sqlalchemy.orm import Session
from ..database import get_db

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

router = APIRouter()

# CORS headers
CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With",
    "Access-Control-Allow-Credentials": "true",
    "Access-Control-Max-Age": "3600",
    "Content-Type": "application/json",
}

@router.get("")
async def get_characters(
    search: Optional[str] = None,
    tags: Optional[str] = None,
    page: int = 1,
    limit: int = 10,
    current_user: Optional[User] = Depends(get_current_user_optional),
    db: Session = Depends(get_db)
):
    try:
        logger.info("Getting characters")
        logger.info(f"Search: {search}, Tags: {tags}, Page: {page}, Limit: {limit}")

        if page < 1:
            return JSONResponse(
                status_code=400,
                content={"detail": "页码必须大于0"},
                headers=CORS_HEADERS
            )
        
        if limit < 1 or limit > 100:
            return JSONResponse(
                status_code=400,
                content={"detail": "每页数量必须在1-100之间"},
                headers=CORS_HEADERS
            )

        # Get all characters
        query = db.query(Character)

        if search:
            query = query.filter(Character.name.ilike(f"%{search}%"))

        # Get system user
        system_user = db.query(User).filter(User.username == "system").first()
        if not system_user:
            logger.error("System user not found")
            return JSONResponse(
                status_code=500,
                content={"detail": "系统错误"},
                headers=CORS_HEADERS
            )

        # Always return at least the system characters for anonymous users
        if not current_user:
            query = query.filter(Character.user_id == system_user.id)
        
        total = query.count()
        characters = query.order_by(Character.created_at.desc()).offset((page - 1) * limit).limit(limit).all()

        if not characters:
            logger.warning("No characters found in database")

        try:
            # Convert characters to list of dictionaries with string IDs
            character_list = []
            for char in characters:
                try:
                    char_dict = char.to_dict()
                    char_dict["id"] = str(char_dict["id"])
                    char_dict["user_id"] = str(char_dict["user_id"])
                    logger.info(f"Character data: {char_dict}")
                    character_list.append(char_dict)
                except Exception as e:
                    logger.error(f"Error converting character to dict: {str(e)}", exc_info=True)
                    continue

            # Ensure character_list is not empty
            if not character_list:
                logger.warning("No characters found or all conversions failed")
                character_list = []

            response_data = {
                "characters": character_list,
                "total": total,
                "page": page,
                "limit": limit,
                "pages": (total + limit - 1) // limit
            }

            logger.info(f"Returning {len(character_list)} characters")
            logger.info(f"Response data: {response_data}")
            
            return JSONResponse(
                status_code=200,
                content=response_data,
                headers=CORS_HEADERS
            )
        except Exception as e:
            error_msg = f"Error preparing response: {str(e)}"
            logger.error(error_msg, exc_info=True)
            return JSONResponse(
                status_code=500,
                content={"detail": error_msg},
                headers=CORS_HEADERS
            )

    except Exception as e:
        error_msg = f"Error getting characters: {str(e)}"
        logger.error(error_msg, exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"detail": error_msg},
            headers=CORS_HEADERS
        )

@router.post("")
async def create_character(
    character: CharacterCreate,
    current_user: Optional[User] = Depends(get_current_user_optional),
    db: Session = Depends(get_db)
):
    try:
        logger.info(f"Creating character for user {current_user.username}")
        logger.info(f"Character data: {character.dict()}")

        # Validate character data
        if not character.name or len(character.name) > 50:
            return JSONResponse(
                status_code=400,
                content={"detail": "角色名称不能为空且不能超过50个字符"},
                headers=CORS_HEADERS
            )

        if len(character.description or "") > 500:
            return JSONResponse(
                status_code=400,
                content={"detail": "角色描述不能超过500个字符"},
                headers=CORS_HEADERS
            )

        db_character = Character(
            user_id=current_user.id,
            **character.dict()
        )
        db.add(db_character)
        db.commit()
        db.refresh(db_character)

        # Convert to response format with string IDs
        response_data = db_character.to_dict()
        response_data["id"] = str(response_data["id"])
        response_data["user_id"] = str(response_data["user_id"])

        return JSONResponse(
            content=response_data,
            headers=CORS_HEADERS
        )

    except Exception as e:
        logger.error(f"Error creating character: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"detail": "创建角色失败"},
            headers=CORS_HEADERS
        )

@router.get("/{character_id}")
async def get_character(
    character_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        logger.info(f"Getting character {character_id}")

        character = db.query(Character).filter(Character.id == character_id).first()
        if not character:
            return JSONResponse(
                status_code=404,
                content={"detail": "角色不存在"},
                headers=CORS_HEADERS
            )

        # Convert to response format with string IDs
        response_data = character.to_dict()
        response_data["id"] = str(response_data["id"])
        response_data["user_id"] = str(response_data["user_id"])

        return JSONResponse(
            content=response_data,
            headers=CORS_HEADERS
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting character: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"detail": "获取角色信息失败"},
            headers=CORS_HEADERS
        )

@router.put("/{character_id}")
async def update_character(
    character_id: str,
    character_update: CharacterUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        logger.info(f"Updating character {character_id}")
        logger.info(f"Update data: {character_update.dict()}")

        character = db.query(Character).filter(
            Character.id == character_id,
            Character.user_id == current_user.id
        ).first()
        if not character:
            return JSONResponse(
                status_code=404,
                content={"detail": "角色不存在"},
                headers=CORS_HEADERS
            )

        # Validate update data
        if character_update.name and len(character_update.name) > 50:
            return JSONResponse(
                status_code=400,
                content={"detail": "角色名称不能超过50个字符"},
                headers=CORS_HEADERS
            )

        if character_update.description and len(character_update.description) > 500:
            return JSONResponse(
                status_code=400,
                content={"detail": "角色描述不能超过500个字符"},
                headers=CORS_HEADERS
            )

        update_data = character_update.dict(exclude_unset=True)
        for key, value in update_data.items():
            setattr(character, key, value)

        db.commit()
        db.refresh(character)

        # Convert to response format with string IDs
        response_data = character.to_dict()
        response_data["id"] = str(response_data["id"])
        response_data["user_id"] = str(response_data["user_id"])

        return JSONResponse(
            content=response_data,
            headers=CORS_HEADERS
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating character: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"detail": "更新角色失败"},
            headers=CORS_HEADERS
        )

@router.delete("/{character_id}")
async def delete_character(
    character_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        logger.info(f"Deleting character {character_id}")

        character = db.query(Character).filter(
            Character.id == character_id,
            Character.user_id == current_user.id
        ).first()
        if not character:
            return JSONResponse(
                status_code=404,
                content={"detail": "角色不存在"},
                headers=CORS_HEADERS
            )

        db.delete(character)
        db.commit()

        return JSONResponse(
            content={"detail": "角色已删除"},
            headers=CORS_HEADERS
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting character: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"detail": "删除角色失败"},
            headers=CORS_HEADERS
        )

@router.options("/{path:path}")
async def options_handler(request: Request):
    requested_headers = request.headers.get('access-control-request-headers', '')
    requested_method = request.headers.get('access-control-request-method', '')
    
    headers = {
        **CORS_HEADERS,
        "Access-Control-Allow-Headers": requested_headers or CORS_HEADERS["Access-Control-Allow-Headers"],
        "Access-Control-Allow-Methods": requested_method or CORS_HEADERS["Access-Control-Allow-Methods"],
    }
    
    return Response(
        content="",
        status_code=204,
        headers=headers
    )
