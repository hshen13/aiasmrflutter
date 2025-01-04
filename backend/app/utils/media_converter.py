import os
import shutil
import math
import logging
from PIL import Image, ImageDraw
import numpy as np
import wave
import struct

logger = logging.getLogger(__name__)

def create_default_waveform(dest_path):
    """Create a default waveform image"""
    img = Image.new('RGB', (800, 200), color='black')
    draw = ImageDraw.Draw(img)
    # Draw a simple waveform pattern
    for x in range(0, 800, 4):
        height = 100 + (x % 40)
        draw.line([(x, 100-height//2), (x, 100+height//2)], fill='white', width=2)
    img.save(dest_path)
    print(f"Created default waveform image at: {dest_path}")

def get_audio_duration(audio_path):
    """Get duration of audio file in seconds"""
    try:
        import subprocess
        result = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', audio_path], capture_output=True, text=True)
        return float(result.stdout.strip())
    except:
        # If ffprobe fails, try using wave module for WAV files
        try:
            with wave.open(audio_path, 'rb') as wav_file:
                frames = wav_file.getnframes()
                rate = wav_file.getframerate()
                return frames / float(rate)
        except:
            return 60.0  # Default to 1 minute if duration cannot be determined

def create_default_audio(dest_path, duration=60.0):
    """Create a default audio file"""
    # Create a simple WAV file with a sine wave
    sampleRate = 44100
    frequency = 440.0  # Hz
    
    # Create WAV file
    wav_file = wave.open(dest_path.replace('.mp3', '.wav'), 'w')
    wav_file.setnchannels(2)  # Stereo
    wav_file.setsampwidth(2)
    wav_file.setframerate(sampleRate)
    
    # Write sine wave data
    for i in range(int(duration * sampleRate)):
        value = int(32767.0 * np.sin(frequency * np.pi * float(i) / float(sampleRate)))
        # Write the same value to both channels
        data = struct.pack('<hh', value, value)
        wav_file.writeframes(data)
    
    wav_file.close()
    
    # Convert WAV to MP3 using ffmpeg if available
    try:
        import subprocess
        subprocess.run(['ffmpeg', '-i', dest_path.replace('.mp3', '.wav'), dest_path])
        os.remove(dest_path.replace('.mp3', '.wav'))
    except:
        # If ffmpeg is not available, just keep the WAV file
        os.rename(dest_path.replace('.mp3', '.wav'), dest_path)
    
    print(f"Created default audio file at: {dest_path}")

def create_default_gif(dest_path, size=(800, 800)):
    """Create a default animated GIF"""
    try:
        frames = []
        # Create 30 frames with different colors for smoother animation
        for i in range(30):
            img = Image.new('RGB', size, color='black')
            draw = ImageDraw.Draw(img)
            # Draw a gradient background with pulsing effect
            phase = i / 30 * 3.14159 * 2  # Full cycle over 30 frames
            intensity = (math.sin(phase) + 1) / 2  # Normalize to 0-1
            
            for y in range(size[1]):
                color = (
                    int(40 * (1 - y/size[1]) + 20 * intensity),  # R
                    int(40 * (1 - y/size[1]) + 10 * intensity),  # G
                    int(60 * (1 - y/size[1]) + 15 * intensity)   # B
                )
                draw.line([(0, y), (size[0], y)], fill=color)
            frames.append(img)
        
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        
        # Save as animated GIF with optimizations for smooth playback
        frames[0].save(
            dest_path,
            save_all=True,
            append_images=frames[1:],
            duration=33,  # ~30fps for smooth animation
            loop=0,      # Loop forever
            optimize=False,  # Disable optimization to preserve quality
            disposal=2,  # Clear previous frame
            transparency=0  # No transparency
        )
        
        # Ensure the GIF file has proper permissions
        os.chmod(dest_path, 0o644)
        logger.info(f"Created default GIF at: {dest_path}")
        
        # Verify the file was created
        if not os.path.exists(dest_path):
            raise Exception("GIF file was not created successfully")
            
        # Verify the file size
        file_size = os.path.getsize(dest_path)
        if file_size == 0:
            raise Exception("Created GIF file is empty")
            
        logger.info(f"GIF file size: {file_size} bytes")
        
    except Exception as e:
        logger.error(f"Error creating default GIF: {str(e)}")
        raise

def setup_default_audio():
    """Setup default audio files"""
    try:
        # Get the base directory
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        print(f"Base directory: {base_dir}")
        
        # Create directories with proper permissions
        static_dir = os.path.join(base_dir, "static")
        static_audio_dir = os.path.join(static_dir, "audio")
        static_images_dir = os.path.join(static_dir, "images")
        static_gif_dir = os.path.join(static_dir, "gif")
        
        # Create directories with proper permissions
        os.makedirs(static_dir, exist_ok=True)
        os.chmod(static_dir, 0o755)
        
        for directory in [static_audio_dir, static_images_dir, static_gif_dir]:
            os.makedirs(directory, exist_ok=True)
            os.chmod(directory, 0o755)
            print(f"Created directory with permissions: {directory}")

        # Create default images and GIFs
        images = {
            "kafka_profile.jpg": (800, 800),
            "kafka_night.jpg": (800, 800),
            "luna_profile.jpg": (800, 800),
            "echo_profile.jpg": (800, 800),
            "waveform.png": (800, 200)
        }

        gifs = {
            "kafka_night.gif": (800, 800)
        }
        
        # Create default images
        for image_name, size in images.items():
            image_path = os.path.join(static_images_dir, image_name)
            if not os.path.exists(image_path):
                if image_name == "waveform.png":
                    create_default_waveform(image_path)
                else:
                    img = Image.new('RGB', size, color='black')
                    draw = ImageDraw.Draw(img)
                    text = image_name.replace('.jpg', '').replace('_', ' ').title()
                    # Draw a gradient background
                    for y in range(size[1]):
                        color = (
                            int(40 * (1 - y/size[1])),  # R
                            int(40 * (1 - y/size[1])),  # G
                            int(60 * (1 - y/size[1]))   # B
                        )
                        draw.line([(0, y), (size[0], y)], fill=color)
                    
                    # Draw text without anchor (for better compatibility)
                    text_bbox = draw.textbbox((0, 0), text)
                    text_width = text_bbox[2] - text_bbox[0]
                    text_height = text_bbox[3] - text_bbox[1]
                    x = (size[0] - text_width) // 2
                    y = (size[1] - text_height) // 2
                    draw.text((x, y), text, fill='white')
                    img.save(image_path)
                    os.chmod(image_path, 0o644)
                print(f"Created default image at: {image_path}")

        # Create default GIFs
        for gif_name, size in gifs.items():
            gif_path = os.path.join(static_gif_dir, gif_name)
            if not os.path.exists(gif_path):
                create_default_gif(gif_path, size)
                print(f"Created default GIF at: {gif_path}")

        # Create default audio files
        for i in range(1, 5):
            audio_filename = f"asmr_{i:03d}.mp3"
            audio_path = os.path.join(static_audio_dir, audio_filename)
            if not os.path.exists(audio_path):
                create_default_audio(audio_path)
                os.chmod(audio_path, 0o644)
            
    except Exception as e:
        print(f"Error in setup_default_audio: {str(e)}")
        raise
