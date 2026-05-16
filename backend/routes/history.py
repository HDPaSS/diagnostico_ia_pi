from fastapi import APIRouter, Query
from schemas import TokenVerify, HistorialResponse
from services import firebase_service

router = APIRouter(prefix="/history", tags=["Historial"])


@router.post(
    "",
    response_model=HistorialResponse,
    summary="Obtener historial de consultas del usuario"
)
async def get_history(
    data: TokenVerify,
    limite: int = Query(default=20, ge=1, le=100, description="Número máximo de consultas a devolver")
):
    """
    Devuelve el historial de consultas del usuario autenticado,
    ordenado de más reciente a más antiguo.

    Requiere el id_token de Firebase para identificar al usuario.
    """
    decoded = firebase_service.verificar_token(data.id_token)
    uid = decoded["uid"]

    perfil   = firebase_service.obtener_perfil_usuario(uid)
    consultas = firebase_service.obtener_historial(uid, limite=limite)

    return {
        "uid": uid,
        "total_consultas": perfil.get("total_consultas", 0),
        "consultas": consultas
    }