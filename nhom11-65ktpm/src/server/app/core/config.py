from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "ChaiLish API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api"
    SECRET_KEY: str = "chailish_secret_key_development_only_2026"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 # 24 hours
    
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/chailish_db"
    
    ANTHROPIC_API_KEY: str = ""
    AZURE_SPEECH_KEY: str = ""
    AZURE_SPEECH_REGION: str = "southeastasia"

    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
