from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from data import test_users, test_predictions
from typing import Optional, Dict, Any

# --- Router de Auth ---
auth = APIRouter(prefix="/auth", tags=["Auth"])

class UserRegister(BaseModel):
    username: str
    password: str
    email: str
    nombre: Optional[str] = None
    fecha_nacimiento: Optional[str] = None

class UserLogin(BaseModel):
    username: str
    password: str

class TokenVerify(BaseModel):
    id_token: str

class UserProfile(BaseModel):
    uid: str
    email: str
    nombre: str
    fecha_nacimiento: Optional[str] = None

class MessageResponse(BaseModel):
    mensaje: str

def _find_user(username: str) -> Optional[Dict[str, Any]]:
    for user in test_users:
        if user["username"] == username:
            return user
    return None

def _find_user_by_uid(uid: str) -> Optional[Dict[str, Any]]:
    for user in test_users:
        if user.get("uid") == uid:
            return user
    return None

@auth.post("/register", response_model=MessageResponse, status_code=status.HTTP_201_CREATED, summary="Registrar nuevo usuario")
async def register_user(user: UserRegister):
    if _find_user(user.username):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Username already exists")
    new_user = user.dict()
    new_user["uid"] = str(len(test_users) + 1)
    test_users.append(new_user)
    return {"mensaje": f"Usuario '{user.username}' registrado correctamente."}

@auth.post("/login", response_model=Dict[str, Any], status_code=status.HTTP_200_OK, summary="Iniciar sesión")
async def login_user(user: UserLogin):
    db_user = _find_user(user.username)
    if not db_user or db_user["password"] != user.password:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    token = f"test_token_{db_user['uid']}"
    return {"message": "Login successful", "id_token": token, "user": db_user}

@auth.post("/verify", response_model=UserProfile, summary="Verificar token y obtener perfil")
async def verify_token(data: TokenVerify):
    uid = data.id_token.split("_")[-1]
    db_user = _find_user_by_uid(uid)
    if not db_user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    return {
        "uid": db_user["uid"],
        "email": db_user["email"],
        "nombre": db_user.get("nombre", ""),
        "fecha_nacimiento": db_user.get("fecha_nacimiento")
    }

@auth.delete("/delete", response_model=MessageResponse, summary="Eliminar cuenta de usuario")
async def delete_account(data: TokenVerify):
    uid = data.id_token.split("_")[-1]
    db_user = _find_user_by_uid(uid)
    if not db_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    test_users.remove(db_user)
    return {"mensaje": "Cuenta eliminada correctamente."}

# --- Router de Predict ---
predict = APIRouter(prefix="/predict", tags=["Predict"])

class PredictionRequest(BaseModel):
    features: list

@predict.post("/", status_code=status.HTTP_200_OK)
async def predict_disease(request: PredictionRequest):
    return {"predictions": test_predictions["predictions"], "features": request.features}

# --- Router de History ---
history = APIRouter(prefix="/history", tags=["History"])

class HistoryRequest(BaseModel):
    username: str

@history.post("/", status_code=status.HTTP_200_OK)
async def get_history(request: HistoryRequest):
    return {"history": "Some history data"}