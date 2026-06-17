"""
Transcription service using AssemblyAI
"""
import asyncio
import time
from concurrent.futures import ThreadPoolExecutor
from typing import Tuple
import assemblyai as aai
from app.core.logging import get_logger
from app.config import settings
from app.exceptions import TranscriptionError, ValidationError
from app.utils.cache import cache, get_content_hash
from app.utils.content_filter import content_filter

logger = get_logger("transcription_service")


class TranscriptionService:
    """AssemblyAI transcription service with async support"""

    def __init__(self):
        aai.settings.api_key = settings.assemblyai_api_key
        self.executor = ThreadPoolExecutor(max_workers=2)

        # Prefer accuracy for Arabic expense dictation. The nano model is fast
        # but loses too much context for short Arabic phrases.
        self.config = aai.TranscriptionConfig(
            language_code="ar",
            speech_model=aai.SpeechModel.best,
            punctuate=True,
            format_text=True,
            dual_channel=False,
            speaker_labels=False,
            auto_highlights=False,
            redact_pii=False,
            filter_profanity=False,
            language_detection=False,
        )

        self.auto_config = aai.TranscriptionConfig(
            language_code=None,
            speech_model=aai.SpeechModel.best,
            punctuate=True,
            format_text=True,
            dual_channel=False,
            speaker_labels=False,
            auto_highlights=False,
            redact_pii=False,
            filter_profanity=False,
            language_detection=True,
        )

        logger.info("AssemblyAI transcription service initialized (Arabic best model)")

    async def transcribe_audio(self, audio_path: str, content_hash: str = None) -> Tuple[str, float]:
        """Transcribe audio file and return text with confidence score"""
        try:
            start_time = time.time()

            if content_hash:
                cache_key = f"transcription:{content_hash}"
                cached_result = cache.get(cache_key)
                if cached_result:
                    logger.info("Returning cached transcription")
                    return cached_result['text'], cached_result['confidence']

            logger.info(f"Starting transcription for: {audio_path}")

            loop = asyncio.get_event_loop()
            transcript_obj = await loop.run_in_executor(
                self.executor, self._transcribe_sync, audio_path
            )

            if transcript_obj.status == aai.TranscriptStatus.error:
                raise TranscriptionError(f"Transcription failed: {transcript_obj.error}")

            text = transcript_obj.text or ""
            confidence = transcript_obj.confidence or 0.0

            if not text or len(text.strip()) == 0:
                raise TranscriptionError(
                    "Could not transcribe audio. Please speak clearly and try again."
                )

            text = self._clean_transcription(text)

            try:
                content_filter.filter_text(text)
            except ValidationError:
                logger.warning(f"Transcription contains prohibited content: {text[:50]}...")
                raise TranscriptionError(
                    "Audio content contains prohibited material and cannot be processed. "
                    "This service is designed for legitimate financial transactions only."
                )

            processing_time = time.time() - start_time
            logger.info(f"Transcription completed in {processing_time:.2f}s, confidence: {confidence:.2f}")

            if content_hash:
                cache.set(cache_key, {
                    'text': text,
                    'confidence': confidence
                }, ttl=86400)

            return text, confidence

        except TranscriptionError:
            raise
        except Exception as e:
            logger.error(f"Transcription service error: {e}", exc_info=True)
            raise TranscriptionError(f"Transcription service failed: {str(e)}")

    def _transcribe_sync(self, audio_path: str) -> aai.Transcript:
        """Try Arabic first, then auto-detect if Arabic returns weak text."""
        arabic_transcriber = aai.Transcriber(config=self.config)
        result = arabic_transcriber.transcribe(audio_path)
        if result and result.text and len(result.text.strip()) >= 3:
            return result

        auto_transcriber = aai.Transcriber(config=self.auto_config)
        return auto_transcriber.transcribe(audio_path)

    def _clean_transcription(self, text: str) -> str:
        """Clean and normalize transcription text"""
        if not text:
            return ""

        text = text.strip()

        import re
        text = re.sub(r'\s+', ' ', text)

        artifacts = ['[inaudible]', '[music]', '[noise]', '[silence]']
        for artifact in artifacts:
            text = text.replace(artifact, '')

        return text.strip()

    def validate_transcription(self, text: str, confidence: float) -> bool:
        """Validate transcription quality"""
        if not text or len(text.strip()) < 3:
            logger.warning("Transcription too short")
            return False

        if confidence < 0.3:
            logger.warning(f"Low transcription confidence: {confidence}")
            return False

        meaningful_chars = sum(1 for c in text if c.isalnum())
        if meaningful_chars < 3:
            logger.warning("Transcription lacks meaningful content")
            return False

        return True

    async def cleanup(self):
        """Cleanup resources"""
        self.executor.shutdown(wait=True)


# Global transcription service instance
transcription_service = TranscriptionService()
