"""
API endpoints for the Finance Analyzer
"""
import time
from fastapi import APIRouter, UploadFile, File, HTTPException, Request, Depends
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from app.models.requests import TextInput
from app.models.responses import (
    TextAnalysisResponse, VoiceAnalysisResponse, HealthResponse,
    SuccessResponse, ErrorResponse, ErrorDetail, TextAnalysisData, VoiceAnalysisData
)
from app.services.nlp_service import NLPService
from app.services.transcription_service import transcription_service
from app.core.security import check_rate_limit, SecurityUtils
from app.core.logging import get_logger, log_request, log_error
from app.utils.file_utils import file_handler, validate_file_extension, get_file_info
from app.utils.cache import get_content_hash
from app.config import settings
from app.exceptions import (
    ValidationError, AudioProcessingError, TranscriptionError, 
    FileValidationError, NLPProcessingError
)

logger = get_logger("api")
router = APIRouter()
templates = Jinja2Templates(directory="templates")

# Initialize services
nlp_service = NLPService()

# Startup time for uptime calculation
startup_time = time.time()


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint for monitoring"""
    uptime = time.time() - startup_time
    
    return HealthResponse(
        status="healthy",
        service="finance-analyzer",
        version=settings.app_version,
        uptime_seconds=uptime
    )


@router.get("/", response_class=HTMLResponse)
async def home(request: Request):
    """Serve the main web interface"""
    return templates.TemplateResponse("index.html", {"request": request})


@router.get("/test", response_class=HTMLResponse)
async def test_page(request: Request):
    """Serve the test page for categorization"""
    return templates.TemplateResponse("test.html", {"request": request})


@router.get("/test-mixed", response_class=HTMLResponse)
async def test_mixed_page(request: Request):
    """Serve the test page for mixed language categorization"""
    return templates.TemplateResponse("test_mixed.html", {"request": request})


@router.get("/test-dynamic", response_class=HTMLResponse)
async def test_dynamic_page(request: Request):
    """Serve the test page for dynamic multilingual system"""
    return templates.TemplateResponse("test_dynamic.html", {"request": request})


@router.get("/test-fixed", response_class=HTMLResponse)
async def test_fixed_page(request: Request):
    """Serve the test page for fixed English categories"""
    return templates.TemplateResponse("test_fixed_english.html", {"request": request})


@router.get("/test-intelligent", response_class=HTMLResponse)
async def test_intelligent_page(request: Request):
    """Serve the test page for intelligent AI classification"""
    return templates.TemplateResponse("test_intelligent.html", {"request": request})


@router.get("/test-user", response_class=HTMLResponse)
async def test_user_page(request: Request):
    """Serve the test page for user's specific example"""
    return templates.TemplateResponse("test_user_example.html", {"request": request})


@router.get("/test-semantic", response_class=HTMLResponse)
async def test_semantic_page(request: Request):
    """Serve the test page for semantic AI classification"""
    return templates.TemplateResponse("test_semantic.html", {"request": request})


@router.post("/analyze", response_model=TextAnalysisResponse)
async def analyze_text(request: Request, input_data: TextInput):
    """
    Analyze financial text and extract structured information.
    
    Args:
        input_data: TextInput with the text to analyze
        
    Returns:
        TextAnalysisResponse with extracted financial data
    """
    start_time = time.time()
    
    try:
        # Rate limiting
        check_rate_limit(request, limit=settings.rate_limit_requests, window=60)
        
        logger.info(f"Text analysis request: {input_data.text[:50]}...")
        
        # Sanitize input
        sanitized_text = SecurityUtils.sanitize_text(input_data.text)
        
        # Analyze text
        analysis_result = await nlp_service.analyze_text(
            sanitized_text, 
            input_data.language
        )
        
        # Prepare response data
        response_data = TextAnalysisData(
            original_text=input_data.text,
            normalized_text=sanitized_text,
            analysis=analysis_result
        )
        
        # Log successful request
        duration_ms = (time.time() - start_time) * 1000
        log_request(logger, "POST", "/analyze", 
                   request.client.host if request.client else "unknown", 
                   duration_ms, 200)
        
        return TextAnalysisResponse(
            data=response_data,
            message="Text analysis completed successfully"
        )
        
    except ValidationError as e:
        logger.warning(f"Validation error: {e.message}")
        raise HTTPException(
            status_code=400,
            detail={
                "error": "validation_error",
                "message": e.message,
                "field": e.field
            }
        )
    except NLPProcessingError as e:
        log_error(logger, e, {"text_length": len(input_data.text)})
        raise HTTPException(
            status_code=500,
            detail={
                "error": "processing_error",
                "message": "Failed to analyze text. Please try again."
            }
        )
    except Exception as e:
        log_error(logger, e, {"endpoint": "/analyze"})
        raise HTTPException(
            status_code=500,
            detail={
                "error": "internal_error",
                "message": "An unexpected error occurred"
            }
        )


@router.post("/voice", response_model=VoiceAnalysisResponse)
async def analyze_voice(request: Request, file: UploadFile = File(...)):
    """
    Analyze financial voice recording and extract structured information.
    
    Args:
        file: Audio file upload (wav, mp3, m4a, ogg, webm, flac)
        
    Returns:
        VoiceAnalysisResponse with transcription and extracted financial data
    """
    start_time = time.time()
    
    try:
        # Stricter rate limiting for voice endpoint
        check_rate_limit(request, limit=5, window=60)
        
        # Validate file
        if not file.filename:
            raise ValidationError("No file provided", field="file")
        
        if not validate_file_extension(file.filename, settings.allowed_audio_extensions):
            raise ValidationError(
                f"Invalid file type. Allowed: {', '.join(settings.allowed_audio_extensions)}",
                field="file"
            )
        
        logger.info(f"Voice analysis request: {file.filename}")
        
        # Read file content
        content = await file.read()
        
        # Validate file size
        if not SecurityUtils.validate_file_size(content, settings.max_file_size):
            raise ValidationError(
                f"File too large. Maximum size: {settings.max_file_size / 1024 / 1024}MB",
                field="file"
            )
        
        # Get file info for logging
        file_info = get_file_info(content, file.filename)
        logger.info(f"Processing audio file: {file_info}")
        
        # Generate content hash for caching
        content_hash = get_content_hash(content)
        
        async with file_handler.create_temp_file(content, file.filename) as temp_path:
            transcription, confidence = await transcription_service.transcribe_audio(
                temp_path, content_hash
            )

            if not transcription or len(transcription.strip()) < 2:
                raise ValidationError(
                    "Could not transcribe audio. Please speak clearly and try again.",
                    field="file",
                )

            logger.info(f"Transcription: {transcription[:80]}... (confidence: {confidence:.2f})")

            analysis_result = await nlp_service.analyze_text(transcription)

            duration = max(0.5, len(content) / (16000 * 2))

            response_data = VoiceAnalysisData(
                transcription=transcription,
                confidence_score=confidence,
                language_detected=analysis_result.language_detected,
                audio_duration_seconds=duration,
                analysis=analysis_result,
            )

            duration_ms = (time.time() - start_time) * 1000
            log_request(
                logger,
                "POST",
                "/voice",
                request.client.host if request.client else "unknown",
                duration_ms,
                200,
            )

            return VoiceAnalysisResponse(
                data=response_data,
                message="Voice analysis completed successfully",
            )
    
    except ValidationError as e:
        logger.warning(f"Validation error: {e.message}")
        raise HTTPException(
            status_code=400,
            detail={
                "error": "validation_error",
                "message": e.message,
                "field": e.field
            }
        )
    except FileValidationError as e:
        logger.warning(f"File validation error: {e.message}")
        raise HTTPException(
            status_code=400,
            detail={
                "error": "file_validation_error",
                "message": e.message,
                "filename": e.filename
            }
        )
    except AudioProcessingError as e:
        log_error(logger, e, {"filename": file.filename})
        raise HTTPException(
            status_code=400,
            detail={
                "error": "audio_processing_error",
                "message": "Failed to process audio file"
            }
        )
    except TranscriptionError as e:
        log_error(logger, e, {"filename": file.filename})
        raise HTTPException(
            status_code=400,
            detail={
                "error": "transcription_error",
                "message": "Failed to transcribe audio"
            }
        )
    except NLPProcessingError as e:
        log_error(logger, e, {"filename": file.filename})
        raise HTTPException(
            status_code=500,
            detail={
                "error": "processing_error",
                "message": "Failed to analyze transcription"
            }
        )
    except Exception as e:
        log_error(logger, e, {"endpoint": "/voice", "filename": file.filename})
        raise HTTPException(
            status_code=500,
            detail={
                "error": "internal_error",
                "message": "An unexpected error occurred"
            }
        )