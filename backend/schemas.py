from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import date, datetime


# ═══════════════════════════════════════════════════════════
# AUTH / USUARIO
# ═══════════════════════════════════════════════════════════

class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    nombre: str = Field(min_length=2, max_length=80)
    fecha_nacimiento: date

    model_config = {
        "json_schema_extra": {
            "example": {
                "email": "juan@ejemplo.com",
                "password": "secreto123",
                "nombre": "Juan García",
                "fecha_nacimiento": "1995-04-21"
            }
        }
    }


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserProfile(BaseModel):
    uid: str
    email: str
    nombre: str
    fecha_nacimiento: str
    fecha_registro: str
    total_consultas: int


class TokenVerify(BaseModel):
    """Token Firebase enviado desde Flutter para verificar sesión."""
    id_token: str


# ═══════════════════════════════════════════════════════════
# PREDICCIÓN
# ═══════════════════════════════════════════════════════════

class PredictRequest(BaseModel):
    sintomas: list[str] = Field(
        min_length=1,
        description="Lista de síntomas en snake_case"
    )
    id_token: str = Field(description="Token Firebase del usuario autenticado")

    model_config = {
        "json_schema_extra": {
            "example": {
                "sintomas": ["fatigue", "vomiting", "yellowish_skin", "abdominal_pain"],
                "id_token": "eyJhbGci..."
            }
        }
    }


class DiagnosticoItem(BaseModel):
    enfermedad: str
    confianza: float = Field(ge=0.0, le=1.0)
    categoria: str


class PredictResponse(BaseModel):
    top3: list[DiagnosticoItem]
    categoria_principal: str
    confianza_categoria: float
    sintomas_reconocidos: list[str]
    sintomas_no_reconocidos: list[str]
    advertencia: Optional[str] = None


# ═══════════════════════════════════════════════════════════
# HISTORIAL
# ═══════════════════════════════════════════════════════════

class ConsultaGuardada(BaseModel):
    consulta_id: str
    fecha: str
    sintomas: list[str]
    resultado: PredictResponse


class HistorialResponse(BaseModel):
    uid: str
    total_consultas: int
    consultas: list[ConsultaGuardada]


# ═══════════════════════════════════════════════════════════
# GENERALES
# ═══════════════════════════════════════════════════════════

class MessageResponse(BaseModel):
    mensaje: str

class ErrorResponse(BaseModel):
    error: str
    detalle: Optional[str] = None