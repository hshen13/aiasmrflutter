import openai
import logging
import os
import asyncio
import aiohttp
import json
from typing import List, Dict, Any, Optional
import time
from datetime import datetime, timedelta
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class RateLimiter:
    def __init__(self, max_requests: int, time_window: int):
        self.max_requests = max_requests
        self.time_window = time_window  # in seconds
        self.requests = []
        self.lock = asyncio.Lock()

    async def acquire(self):
        async with self.lock:
            now = datetime.now()
            # Remove old requests
            self.requests = [req_time for req_time in self.requests 
                           if now - req_time < timedelta(seconds=self.time_window)]
            
            if len(self.requests) >= self.max_requests:
                oldest_request = self.requests[0]
                wait_time = (oldest_request + timedelta(seconds=self.time_window) - now).total_seconds()
                if wait_time > 0:
                    logger.warning(f"Rate limit exceeded. Waiting {wait_time:.2f} seconds")
                    await asyncio.sleep(wait_time)
                    # Recursive call after waiting
                    return await self.acquire()
            
            self.requests.append(now)
            return True

class AIService:
    def __init__(self):
        # OpenAI Configuration
        self.openai_api_key = os.getenv("OPENAI_API_KEY")
        self.openai_model = os.getenv("OPENAI_MODEL", "gpt-3.5-turbo")
        self.openai_max_tokens = int(os.getenv("OPENAI_MAX_TOKENS", "150"))
        self.openai_temperature = float(os.getenv("OPENAI_TEMPERATURE", "0.7"))

        # ElevenLabs Configuration (Optional)
        self.elevenlabs_api_key = os.getenv("ELEVENLABS_API_KEY")
        self.elevenlabs_voice_id = os.getenv("ELEVENLABS_VOICE_ID")
        self.elevenlabs_model_id = os.getenv("ELEVENLABS_MODEL_ID", "eleven_monolingual_v1")
        self.elevenlabs_optimize_streaming = os.getenv("ELEVENLABS_OPTIMIZE_STREAMING", "true").lower() == "true"
        self.elevenlabs_stability = float(os.getenv("ELEVENLABS_STABILITY", "0.75"))
        self.elevenlabs_similarity_boost = float(os.getenv("ELEVENLABS_SIMILARITY_BOOST", "0.75"))

        if not self.openai_api_key:
            raise ValueError("OPENAI_API_KEY environment variable not set")

        openai.api_key = self.openai_api_key

        # Initialize rate limiters
        self.openai_rate_limiter = RateLimiter(max_requests=3, time_window=60)
        self.elevenlabs_rate_limiter = RateLimiter(max_requests=5, time_window=60)

        # Initialize retry settings
        self.max_retries = 3
        self.retry_delay = 1
        self.retry_multiplier = 2

        # Ensure audio cache directory exists if ElevenLabs is configured
        if self.elevenlabs_api_key and self.elevenlabs_voice_id:
            self.cache_dir = Path("cache/audio")
            self.cache_dir.mkdir(parents=True, exist_ok=True)
            logger.info("ElevenLabs voice synthesis enabled")
        else:
            logger.warning("ElevenLabs voice synthesis disabled - API key or voice ID not set")

    async def _make_request_with_retry(self, func, *args, **kwargs) -> Dict[str, Any]:
        """Helper method to make API requests with retry logic"""
        for attempt in range(self.max_retries):
            try:
                return await func(*args, **kwargs)
            except (openai.error.RateLimitError, aiohttp.ClientError) as e:
                if attempt == self.max_retries - 1:
                    raise
                wait_time = self.retry_delay * (self.retry_multiplier ** attempt)
                logger.warning(f"Rate limit hit, waiting {wait_time} seconds before retry")
                await asyncio.sleep(wait_time)
            except Exception as e:
                logger.error(f"Request error: {str(e)}")
                if attempt == self.max_retries - 1:
                    raise
                await asyncio.sleep(self.retry_delay)

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
    ) -> Dict[str, Any]:
        """Generate a chat completion using OpenAI's API"""
        try:
            if not messages:
                raise ValueError("Messages list cannot be empty")

            # Validate messages format
            for msg in messages:
                if not isinstance(msg, dict) or 'role' not in msg or 'content' not in msg:
                    raise ValueError("Invalid message format")
                if msg['role'] not in ['system', 'user', 'assistant']:
                    raise ValueError(f"Invalid role: {msg['role']}")

            # Apply rate limiting
            await self.openai_rate_limiter.acquire()

            # Make API request with retry logic
            response = await self._make_request_with_retry(
                openai.ChatCompletion.acreate,
                model=self.openai_model,
                messages=messages,
                temperature=temperature or self.openai_temperature,
                max_tokens=max_tokens or self.openai_max_tokens,
                presence_penalty=0.0,
                frequency_penalty=0.0,
                timeout=30,
            )

            # Log response metrics
            logger.info(f"Tokens used: {response['usage']['total_tokens']}")

            return {
                "content": response['choices'][0]['message']['content'],
                "role": "assistant",
                "usage": response['usage'],
                "created": response['created']
            }

        except Exception as e:
            logger.error(f"Chat completion error: {str(e)}")
            raise

    async def text_to_speech(self, text: str, cache_key: Optional[str] = None) -> Optional[bytes]:
        """Convert text to speech using ElevenLabs API"""
        try:
            if not self.elevenlabs_api_key or not self.elevenlabs_voice_id:
                logger.warning("Skipping text-to-speech - ElevenLabs not configured")
                return None

            # Check cache if cache_key provided
            if cache_key:
                cache_file = self.cache_dir / f"{cache_key}.mp3"
                if cache_file.exists():
                    return cache_file.read_bytes()

            # Apply rate limiting
            await self.elevenlabs_rate_limiter.acquire()

            # Prepare request
            url = f"https://api.elevenlabs.io/v1/text-to-speech/{self.elevenlabs_voice_id}"
            headers = {
                "Accept": "audio/mpeg",
                "Content-Type": "application/json",
                "xi-api-key": self.elevenlabs_api_key
            }
            data = {
                "text": text,
                "model_id": self.elevenlabs_model_id,
                "optimize_streaming_latency": self.elevenlabs_optimize_streaming
            }

            try:
                logger.info("=== ElevenLabs API Request ===")
                logger.info(f"URL: {url}")
                logger.info(f"Headers: {headers}")
                logger.info(f"Data: {data}")
                logger.info(f"API Key: {self.elevenlabs_api_key}")  # Log full API key for debugging
                logger.info(f"Voice ID: {self.elevenlabs_voice_id}")
                logger.info(f"Model ID: {self.elevenlabs_model_id}")
                logger.info("============================")
                
                async with aiohttp.ClientSession() as session:
                    async with session.post(url, headers=headers, json=data) as response:
                        logger.info(f"Response status: {response.status}")
                        logger.info(f"Response headers: {dict(response.headers)}")
                        
                        if response.status != 200:
                            error_text = await response.text()
                            logger.error("=== ElevenLabs API Error ===")
                            logger.error(f"Status Code: {response.status}")
                            logger.error(f"Error Text: {error_text}")
                            logger.error(f"Response Headers: {dict(response.headers)}")
                            logger.error("==========================")
                            raise ValueError(f"ElevenLabs API error: {error_text}")
                        
                        audio_content = await response.read()
                        content_type = response.headers.get('Content-Type', '')
                        logger.info(f"Response Content-Type: {content_type}")
                        logger.info(f"Successfully received audio content from ElevenLabs: {len(audio_content)} bytes")
                        
                        if not content_type.startswith('audio/'):
                            logger.error(f"Unexpected content type: {content_type}")
                            return None

                        # Cache the audio if cache_key provided
                        if cache_key:
                            cache_file = self.cache_dir / f"{cache_key}.mp3"
                            cache_file.write_bytes(audio_content)
                            logger.info(f"Cached audio to {cache_file}")

                        return audio_content
            except Exception as e:
                logger.error(f"Error in text_to_speech: {str(e)}")
                return None

        except Exception as e:
            logger.error(f"Text-to-speech error: {str(e)}")
            return None

    async def process_message(
        self,
        user_message: str,
        character_name: str,
        character_personality: str,
        previous_messages: Optional[List[Dict[str, str]]] = None,
    ) -> Dict[str, Any]:
        """Process a user message and return both text and audio responses"""
        try:
            # Build conversation context
            messages = [
                {
                    "role": "system",
                    "content": (
                        f"You are {character_name}. {character_personality} "
                        "Keep responses concise (2-3 sentences) and suitable for ASMR. "
                        "Maintain a consistent personality and remember previous interactions. "
                        "Use soft-spoken language and create a peaceful atmosphere."
                    )
                }
            ]

            # Add previous messages for context
            if previous_messages:
                # Only include the last 5 messages to maintain context without exceeding token limits
                context_messages = previous_messages[-5:]
                logger.info(f"Adding {len(context_messages)} previous messages for context")
                messages.extend(context_messages)

            # Add user message
            messages.append({"role": "user", "content": user_message})
            logger.info("Final message context:")
            for msg in messages:
                logger.info(f"- {msg['role']}: {msg['content'][:50]}...")

            # Get AI response
            response = await self.chat_completion(messages)
            response_text = response["content"]

            # Generate audio response if ElevenLabs is configured
            audio_content = await self.text_to_speech(
                response_text,
                cache_key=f"{character_name}_{hash(response_text)}"
            ) if self.elevenlabs_api_key and self.elevenlabs_voice_id else None

            return {
                "text": response_text,
                "audio": audio_content,
                "usage": response["usage"]
            }

        except Exception as e:
            logger.error(f"Message processing error: {str(e)}")
            raise

    async def moderate_content(self, text: str) -> bool:
        """Check if content is appropriate using OpenAI's moderation API"""
        try:
            response = await self._make_request_with_retry(
                openai.Moderation.acreate,
                input=text
            )
            return not response['results'][0]['flagged']
        except Exception as e:
            logger.error(f"Moderation error: {str(e)}")
            return True  # Default to allowing content if moderation fails
