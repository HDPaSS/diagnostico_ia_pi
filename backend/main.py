import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from routes import auth, predict, history
from services.model_service import _cargar_modelo_local


# ══════════════════════════════════════════════════════════════════════════════
# LIFESPAN — se ejecuta al arrancar y al apagar el servidor
# ══════════════════════════════════════════════════════════════════════════════

@asynccontextmanager
async def lifespan(app: FastAPI):
    # ARRANQUE: pre-cargar el modelo si está disponible localmente
    # Así la primera petición no sufre el delay de carga
    print("="*55)
    print("  Arrancando backend de diagnóstico médico")
    print("="*55)

    modelo = _cargar_modelo_local()
    if modelo:
        print("  Modelo local cargado en memoria.")
        print(f"  Features disponibles: {len(modelo['features'])}")
    else:
        hf_url = os.getenv("HF_MODEL_URL", "No configurada")
        print(f"  Modo producción — modelo en HuggingFace Space")
        print(f"  HF_MODEL_URL: {hf_url}")

    print("="*55)
    yield
    # APAGADO (cleanup si fuese necesario)
    print("  Backend detenido.")


# ══════════════════════════════════════════════════════════════════════════════
# APP
# ══════════════════════════════════════════════════════════════════════════════

app = FastAPI(
    title="API de Diagnóstico Médico",
    description=(
        "Backend del sistema de predicción de enfermedades por síntomas. "
        "Usa un modelo híbrido Random Forest + XGBoost con 557 enfermedades."
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",      # Swagger UI — desactivar en producción si se quiere
    redoc_url="/redoc"
)


# ══════════════════════════════════════════════════════════════════════════════
# CORS — permite peticiones desde Flutter Web y móvil
# ══════════════════════════════════════════════════════════════════════════════

# En producción, sustituye "*" por el dominio real de tu app Flutter Web
ALLOWED_ORIGINS = os.getenv(
    "ALLOWED_ORIGINS",
    "*"   # desarrollo: acepta cualquier origen
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ══════════════════════════════════════════════════════════════════════════════
# ROUTERS
# ══════════════════════════════════════════════════════════════════════════════

app.include_router(auth.router)
app.include_router(predict.router)
app.include_router(history.router)


# ══════════════════════════════════════════════════════════════════════════════
# ENDPOINTS AUXILIARES
# ══════════════════════════════════════════════════════════════════════════════

@app.get("/", tags=["Estado"])
async def root():
    return {"estado": "ok", "version": "1.0.0", "mensaje": "API de Diagnóstico Médico"}


@app.get("/health", tags=["Estado"])
async def health():
    """Endpoint de health check para Render / HuggingFace."""
    return {"status": "healthy"}


# ══════════════════════════════════════════════════════════════════════════════
# ARRANQUE LOCAL
# ══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True   # hot-reload en desarrollo
    )