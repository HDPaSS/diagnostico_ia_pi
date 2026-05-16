from fastapi import APIRouter, HTTPException, status
from schemas import UserRegister, UserProfile, TokenVerify, MessageResponse
from services import firebase_service
import firebase_admin
from firebase_admin import auth as firebase_auth
from firebase_admin import firestore   

router = APIRouter(prefix="/auth", tags=["Autenticación"])


@router.post(
    "/register",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar nuevo usuario"
)
async def register(data: UserRegister):
    """
    Crea el usuario en Firebase Authentication y su documento en Firestore.
    Flutter se encarga de hacer login tras el registro y obtener el id_token.
    """
    try:
        user_record = firebase_auth.create_user(
            email=data.email,
            password=data.password,
            display_name=data.nombre
        )
    except firebase_auth.EmailAlreadyExistsError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe una cuenta con ese email."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al crear el usuario: {str(e)}"
        )

    firebase_service.crear_usuario_firestore(
        uid=user_record.uid,
        email=data.email,
        nombre=data.nombre,
        fecha_nacimiento=str(data.fecha_nacimiento)
    )

    return {"mensaje": f"Usuario '{data.nombre}' registrado correctamente."}


@router.post(
    "/verify",
    response_model=UserProfile,
    summary="Verificar token y obtener perfil"
)
async def verify_token(data: TokenVerify):
    """
    Verifica el id_token de Firebase enviado por Flutter.
    Devuelve el perfil completo del usuario desde Firestore.
    """
    decoded = firebase_service.verificar_token(data.id_token)
    uid = decoded["uid"]
    perfil = firebase_service.obtener_perfil_usuario(uid)
    return perfil


@router.delete(
    "/delete",
    response_model=MessageResponse,
    summary="Eliminar cuenta y todos sus datos"
)
async def delete_account(data: TokenVerify):
    """
    Elimina la cuenta del usuario de Firebase Auth y todos sus datos en Firestore.
    """
    decoded = firebase_service.verificar_token(data.id_token)
    uid = decoded["uid"]

    # 1. Borrar documentos de Firestore (consultas + perfil)
    db = firestore.client()
    try:
        # Borrar subcolección "consultas"
        consultas_ref = db.collection("users").document(uid).collection("consultas")
        docs = consultas_ref.stream()
        for doc in docs:
            doc.reference.delete()
        
        # Borrar documento principal del usuario
        db.collection("users").document(uid).delete()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al eliminar datos del usuario: {str(e)}"
        )

    # 2. Borrar usuario de Firebase Auth
    try:
        firebase_auth.delete_user(uid)
    except firebase_auth.UserNotFoundError:
        # El usuario ya no existe en Auth, seguimos adelante
        pass
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al eliminar la cuenta: {str(e)}"
        )

    return {"mensaje": "Cuenta y datos eliminados correctamente."}