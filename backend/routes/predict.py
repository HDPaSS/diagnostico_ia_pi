from fastapi import APIRouter, status
from schemas import PredictRequest, PredictResponse
from services import firebase_service, model_service

router = APIRouter(prefix="/predict", tags=["Diagnóstico"])


@router.post(
    "",
    response_model=PredictResponse,
    summary="Predecir enfermedad a partir de síntomas"
)
async def predict(data: PredictRequest):
    """
    Recibe la lista de síntomas y el token Firebase del usuario.

    Flujo:
    1. Verifica el token → obtiene uid
    2. Llama al servicio del modelo (local o HuggingFace Space)
    3. Guarda la consulta en Firestore
    4. Devuelve el top 3 de diagnósticos con confianza

    Los síntomas deben enviarse en snake_case (ej: 'chest_pain', 'fatigue').
    """
    # 1. Autenticar usuario
    decoded = firebase_service.verificar_token(data.id_token)
    uid = decoded["uid"]

    # 2. Predecir
    resultado = await model_service.predecir(data.sintomas)

    # 3. Guardar en Firestore (no bloqueante para el usuario)
    firebase_service.guardar_consulta(
        uid=uid,
        sintomas=data.sintomas,
        resultado=resultado
    )

    return resultado