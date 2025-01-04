import logging
import os
import asyncio
import aiohttp
import hashlib
import json
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import tempfile
import aiofiles
import aiofiles.os

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class TTSCache:
    def __init__(self, cache_dir: str = None):
        self.cache_dir = cache_dir or os.path.join(tempfile.gettempdir(), 'tts_cache')
        self.max_age = timedelta(days=7)  # Cache files for 7 days
        self.ensure_cache_dir()

    def ensure_cache_dir(self):
        """Ensure cache directory exists"""
        os.makedirs(self.cache_dir, exist_ok=True)

    def get_cache_path(self, text: str, voice_id: str, speed: float, pitch: float) -> str:
        """Generate cache file path based on parameters"""
        params = f"{text}_{voice_id}_{speed}_{pitch}"
        hash_key = hashlib.md5(params.encode()).hexdigest()
        return os.path.join(self.cache_dir, f"{hash_key}.mp3")

    async def get(self, text: str, voice_id: str, speed: float, pitch: float) -> Optional[bytes]:
        """Get audio data from cache if available and not expired"""
        try:
            cache_path = self.get_cache_path(text, voice_id, speed, pitch)
            if not await aiofiles.os.path.exists(cache_path):
                return None

            # Check file age
            stats = await aiofiles.os.stat(cache_path)
            file_age = datetime.now() - datetime.fromtimestamp(stats.st_mtime)
            if file_age > self.max_age:
                await aiofiles.os.remove(cache_path)
                return None

            async with aiofiles.open(cache_path, 'rb') as f:
                return await f.read()

        except Exception as e:
            logger.error(f"Cache read error: {str(e)}")
            return None

    async def put(self, text: str, voice_id: str, speed: float, pitch: float, audio_data: bytes):
        """Store audio data in cache"""
        try:
            cache_path = self.get_cache_path(text, voice_id, speed, pitch)
            async with aiofiles.open(cache_path, 'wb') as f:
                await f.write(audio_data)
        except Exception as e:
            logger.error(f"Cache write error: {str(e)}")

    async def cleanup(self):
        """Remove expired cache files"""
        try:
            for filename in os.listdir(self.cache_dir):
                file_path = os.path.join(self.cache_dir, filename)
                stats = await aiofiles.os.stat(file_path)
                file_age = datetime.now() - datetime.fromtimestamp(stats.st_mtime)
                if file_age > self.max_age:
                    await aiofiles.os.remove(file_path)
        except Exception as e:
            logger.error(f"Cache cleanup error: {str(e)}")

class TTSService:
    def __init__(self):
        # Get API key from environment variable
        self.api_key = os.getenv("ELEVENLABS_API_KEY")
        if not self.api_key:
            logger.warning("ELEVENLABS_API_KEY environment variable not set, using dummy service")
            self.dummy_mode = True
        else:
            self.dummy_mode = False
            
        self.base_url = "https://api.elevenlabs.io/v1"
        self.cache = TTSCache()

        # Initialize rate limiter (10 requests per minute)
        self.rate_limiter = asyncio.Semaphore(10)
        self.last_request_time = datetime.now()
        self.min_request_interval = 0.1  # seconds

        # Initialize retry settings
        self.max_retries = 3
        self.retry_delay = 1  # seconds
        self.retry_multiplier = 2  # exponential backoff multiplier

    async def _make_request(self, method: str, endpoint: str, **kwargs) -> Any:
        """Make HTTP request with rate limiting and retry logic"""
        async with self.rate_limiter:
            # Ensure minimum interval between requests
            now = datetime.now()
            time_since_last = (now - self.last_request_time).total_seconds()
            if time_since_last < self.min_request_interval:
                await asyncio.sleep(self.min_request_interval - time_since_last)

            headers = {
                "xi-api-key": self.api_key,
                "Accept": "application/json",
            }

            if "headers" in kwargs:
                headers.update(kwargs["headers"])
            kwargs["headers"] = headers

            url = f"{self.base_url}/{endpoint}"

            for attempt in range(self.max_retries):
                try:
                    async with aiohttp.ClientSession() as session:
                        async with session.request(method, url, **kwargs) as response:
                            self.last_request_time = datetime.now()

                            if response.status == 429:  # Rate limit exceeded
                                retry_after = int(response.headers.get("Retry-After", self.retry_delay))
                                logger.warning(f"Rate limit exceeded. Waiting {retry_after} seconds")
                                await asyncio.sleep(retry_after)
                                continue

                            response.raise_for_status()
                            
                            if response.content_type == "application/json":
                                return await response.json()
                            return await response.read()

                except aiohttp.ClientError as e:
                    if attempt == self.max_retries - 1:
                        raise ValueError(f"Request failed: {str(e)}")
                    wait_time = self.retry_delay * (self.retry_multiplier ** attempt)
                    logger.warning(f"Request failed, retrying in {wait_time} seconds")
                    await asyncio.sleep(wait_time)

    async def get_voices(self) -> List[Dict[str, Any]]:
        """Get available voices"""
        if self.dummy_mode:
            return [{"voice_id": "dummy", "name": "Dummy Voice"}]
            
        try:
            response = await self._make_request("GET", "voices")
            return response["voices"]
        except Exception as e:
            logger.error(f"Error getting voices: {str(e)}")
            raise ValueError("Failed to get available voices")

    async def generate_speech(
        self,
        text: str,
        voice_id: str,
        speed: float = 1.0,
        pitch: float = 1.0
    ) -> bytes:
        """Generate speech from text"""
        try:
            # Check cache first
            cached_audio = await self.cache.get(text, voice_id, speed, pitch)
            if cached_audio:
                logger.info("Using cached audio")
                return cached_audio

            # Validate input
            if not text:
                raise ValueError("Text cannot be empty")

            if len(text) > 5000:
                raise ValueError("Text too long (max 5000 characters)")

            if not voice_id:
                raise ValueError("Voice ID cannot be empty")

            if not 0.5 <= speed <= 2.0:
                raise ValueError("Speed must be between 0.5 and 2.0")

            if not 0.5 <= pitch <= 2.0:
                raise ValueError("Pitch must be between 0.5 and 2.0")

            if self.dummy_mode:
                # Return empty audio data in dummy mode
                logger.info("Using dummy TTS service")
                return b""

            # Prepare request data
            data = {
                "text": text,
                "model_id": "eleven_monolingual_v1",
                "voice_settings": {
                    "stability": 0.75,
                    "similarity_boost": 0.75,
                    "speed": speed,
                    "pitch": pitch
                }
            }

            # Make request
            audio_data = await self._make_request(
                "POST",
                f"text-to-speech/{voice_id}",
                json=data,
                headers={"Content-Type": "application/json"}
            )

            # Cache the result
            await self.cache.put(text, voice_id, speed, pitch, audio_data)

            return audio_data

        except ValueError as e:
            logger.error(f"Validation error: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Error generating speech: {str(e)}")
            raise ValueError("Failed to generate speech")

    async def cleanup(self):
        """Cleanup resources"""
        try:
            await self.cache.cleanup()
        except Exception as e:
            logger.error(f"Cleanup error: {str(e)}")
