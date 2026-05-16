import os
import firebase_admin
from firebase_admin import credentials, auth, firestore
from datetime import datetime, timezone
from fastapi import HTTPException, status

# ── Inicialización única de Firebase Admin ─────────────────────────────────────
# En local: usa firebase_key.json (NO subir a git)
# En HuggingFace Space: usa variable de entorno FIREBASE_CREDENTIALS_JSON

def _init_firebase():
    if firebase_admin._apps:
        return

    # Opción 1: variable de entorno (producción en HuggingFace)
    creds_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
    if creds_json:
        import json
        cred_dict = json.loads(creds_json)
        cred = credentials.Certificate(cred_dict)
    # Opción 2: fichero local (desarrollo)
    elif os.path.exists("firebase_key.json"):
        cred = credentials.Certificate("firebase_key.json")
    else:
        raise RuntimeError(
            "Firebase no configurado. Necesitas 'firebase_key.json' "
            "o la variable de entorno 'FIREBASE_CREDENTIALS_JSON'."
        )

    firebase_admin.initialize_app(cred)

_init_firebase()
db = firestore.client()


# ══════════════════════════════════════════════════════════════════════════════
# AUTENTICACIÓN
# ══════════════════════════════════════════════════════════════════════════════

def verificar_token(id_token: str) -> dict:
    """
    Verifica el token Firebase enviado por Flutter.
    Devuelve el decoded token con uid, email, etc.
    Lanza 401 si el token es inválido o ha expirado.
    """
    try:
        decoded = auth.verify_id_token(id_token)
        return decoded
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expirado. Vuelve a iniciar sesión."
        )
    except auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Error de autenticación: {str(e)}"
        )


def crear_usuario_firestore(uid: str, email: str, nombre: str, fecha_nacimiento: str):
    """
    Crea el documento del usuario en Firestore tras el registro.
    Solo se llama una vez, cuando el usuario se registra por primera vez.
    """
    doc_ref = db.collection("users").document(uid)

    # Evitar sobrescribir si ya existe
    if doc_ref.get().exists:
        return

    doc_ref.set({
        "uid": uid,
        "email": email,
        "nombre": nombre,
        "fecha_nacimiento": fecha_nacimiento,
        "fecha_registro": datetime.now(timezone.utc).isoformat(),
        "total_consultas": 0
    })


def obtener_perfil_usuario(uid: str) -> dict:
    """Devuelve el documento del usuario desde Firestore."""
    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado en base de datos."
        )
    return doc.to_dict()


# ══════════════════════════════════════════════════════════════════════════════
# HISTORIAL DE CONSULTAS
# ══════════════════════════════════════════════════════════════════════════════

def guardar_consulta(uid: str, sintomas: list[str], resultado: dict):
    """
    Guarda una consulta en la subcolección users/{uid}/consultas.
    Actualiza el contador total_consultas del usuario.
    """
    user_ref = db.collection("users").document(uid)

    # Nuevo documento en la subcolección
    consulta_ref = user_ref.collection("consultas").document()
    consulta_ref.set({
        "consulta_id": consulta_ref.id,
        "fecha": datetime.now(timezone.utc).isoformat(),
        "sintomas": sintomas,
        "resultado": resultado
    })

    # Incrementar contador atómicamente
    user_ref.update({
        "total_consultas": firestore.Increment(1)
    })

    return consulta_ref.id


def obtener_historial(uid: str, limite: int = 20) -> list[dict]:
    """
    Devuelve las últimas `limite` consultas del usuario, ordenadas por fecha desc.
    """
    consultas_ref = (
        db.collection("users")
        .document(uid)
        .collection("consultas")
        .order_by("fecha", direction=firestore.Query.DESCENDING)
        .limit(limite)
    )

    docs = consultas_ref.stream()
    return [doc.to_dict() for doc in docs]