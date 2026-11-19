from fastapi import APIRouter

router = APIRouter(prefix="/health", tags=["Health"])

@router.get("")
def health_check():
    return {
        "status": "healthy",
        "service": "pronounce-ai-backend",
        "version": "1.0.0"
    }
