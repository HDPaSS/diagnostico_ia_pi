# Debug_test/main_test.py

import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from route_test import auth, predict, history
from data import test_users, test_predictions

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
app.include_router(auth)
app.include_router(predict)
app.include_router(history)

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
        "main_test:app",
        host="0.0.0.0",
        port=8000,
        reload=True   # hot-reload en desarrollo
    )