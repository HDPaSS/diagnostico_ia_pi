import os
import joblib
import numpy as np
import pandas as pd
import httpx
from fastapi import HTTPException, status

# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ══════════════════════════════════════════════════════════════════════════════

# URL del microservicio del modelo en HuggingFace Spaces
# Se puede sobreescribir con variable de entorno
HF_MODEL_URL = os.getenv(
    "HF_MODEL_URL",
    "https://HDPa-diagnostico-modelo.hf.space/predict" 
)

# Timeout generoso por el cold start de HuggingFace (~5s)
HF_TIMEOUT = float(os.getenv("HF_TIMEOUT", "30"))

# Modo local: si existe el pkl en /model, úsalo directamente (desarrollo)
LOCAL_MODEL_PATH = os.path.join(os.path.dirname(__file__), "..", "model", "sistema_hibrido_v3.pkl")

_sistema = None  # caché en memoria del modelo local


def _cargar_modelo_local():
    """Carga el sistema híbrido V3 desde disco (solo en desarrollo local)."""
    global _sistema
    if _sistema is None:
        if not os.path.exists(LOCAL_MODEL_PATH):
            return None
        print("[model_service] Cargando modelo local desde disco...")
        _sistema = joblib.load(LOCAL_MODEL_PATH)
        print("[model_service] Modelo cargado correctamente.")
    return _sistema


# ══════════════════════════════════════════════════════════════════════════════
# VALIDACIÓN DE SÍNTOMAS
# ══════════════════════════════════════════════════════════════════════════════

def _normalizar_sintoma(s: str) -> str:
    return s.strip().lower().replace(" ", "_")


def validar_sintomas(sintomas: list[str], features: list[str]) -> tuple[list[str], list[str]]:
    """
    Separa los síntomas recibidos en reconocidos (en el vocabulario del modelo)
    y no reconocidos.
    Devuelve (reconocidos, no_reconocidos).
    """
    features_set = set(features)
    reconocidos = []
    no_reconocidos = []

    for s in sintomas:
        s_norm = _normalizar_sintoma(s)
        if s_norm in features_set:
            reconocidos.append(s_norm)
        else:
            no_reconocidos.append(s)

    return reconocidos, no_reconocidos


# ══════════════════════════════════════════════════════════════════════════════
# PREDICCIÓN LOCAL (desarrollo)
# ══════════════════════════════════════════════════════════════════════════════

def _predecir_local(sintomas_reconocidos: list[str]) -> dict:
    """
    Llama al sistema híbrido V3 directamente en memoria.
    Solo se usa cuando el modelo está disponible localmente.
    """
    sistema = _cargar_modelo_local()
    if sistema is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Modelo no disponible localmente. Configura HF_MODEL_URL."
        )

    rf_model    = sistema["rf_model"]
    rf_encoder  = sistema["rf_encoder"]
    especializados = sistema["especializados"]
    features    = sistema["features"]
    categorias  = sistema["categorias"]

    # Construir vector de entrada
    input_vec = pd.DataFrame(0, index=[0], columns=features)
    for s in sintomas_reconocidos:
        if s in features:
            input_vec[s] = 1

    # Nivel 1: RF → categoría médica
    rf_probs = rf_model.predict_proba(input_vec)[0]
    rf_top   = np.argsort(rf_probs)[::-1][:10]

    # Determinar categoría principal
    def asignar_categoria(enf):
        enf_l = str(enf).lower()
        mejor, mejor_len = "general", 0
        for cat, patrones in categorias.items():
            for p in patrones:
                if p in enf_l and len(p) > mejor_len:
                    mejor, mejor_len = cat, len(p)
        return mejor

    votos_cat = {}
    for idx in rf_top:
        enf = rf_encoder.inverse_transform([idx])[0]
        cat = asignar_categoria(enf)
        votos_cat[cat] = votos_cat.get(cat, 0) + rf_probs[idx]

    cat_principal   = max(votos_cat, key=votos_cat.get)
    confianza_cat   = votos_cat[cat_principal] / sum(votos_cat.values())

    # Nivel 2: votación ponderada RF (60%) + XGBoost especializado (40%)
    resultados = {}
    esp = especializados.get(cat_principal)
    tiene_esp = esp is not None and esp.get("modelo") is not None

    peso_rf = 0.6
    for idx, prob in enumerate(rf_probs):
        enf = rf_encoder.inverse_transform([idx])[0]
        cat_enf = asignar_categoria(enf)
        factor = 1.5 if cat_enf == cat_principal else 0.5
        resultados[enf] = resultados.get(enf, 0) + prob * peso_rf * factor

    if tiene_esp:
        xgb_probs   = esp["modelo"].predict_proba(input_vec)[0]
        xgb_encoder = esp["encoder"]
        for idx, prob in enumerate(xgb_probs):
            enf = xgb_encoder.inverse_transform([idx])[0]
            resultados[enf] = resultados.get(enf, 0) + prob * 0.4

    # Ordenar y normalizar top 3
    ordenados = sorted(resultados.items(), key=lambda x: x[1], reverse=True)
    total = sum(v for _, v in ordenados[:10]) or 1

    top3 = []
    for enf, score in ordenados[:3]:
        top3.append({
            "enfermedad": enf,
            "confianza": round(score / total, 4),
            "categoria": asignar_categoria(enf)
        })

    return {
        "top3": top3,
        "categoria_principal": cat_principal,
        "confianza_categoria": round(float(confianza_cat), 4)
    }


# ══════════════════════════════════════════════════════════════════════════════
# PREDICCIÓN REMOTA (producción → HuggingFace Space)
# ══════════════════════════════════════════════════════════════════════════════

async def _predecir_remoto(sintomas_reconocidos: list[str]) -> dict:
    """
    Llama al microservicio del modelo alojado en HuggingFace Spaces.
    """
    try:
        async with httpx.AsyncClient(timeout=HF_TIMEOUT) as client:
            response = await client.post(
                HF_MODEL_URL,
                json={"sintomas": sintomas_reconocidos}
            )
            response.raise_for_status()
            return response.json()
    except httpx.TimeoutException:
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="El servicio de predicción tardó demasiado. Inténtalo de nuevo."
        )
    except httpx.HTTPStatusError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error en el servicio de predicción: {e.response.status_code}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Servicio de predicción no disponible: {str(e)}"
        )


# ══════════════════════════════════════════════════════════════════════════════
# PUNTO DE ENTRADA UNIFICADO
# ══════════════════════════════════════════════════════════════════════════════

async def predecir(sintomas: list[str]) -> dict:
    """
    Decide si usar el modelo local (desarrollo) o el remoto (producción).
    Siempre devuelve el mismo formato de respuesta.
    """
    # Obtener features del modelo para validar síntomas
    sistema_local = _cargar_modelo_local()
    if sistema_local:
        features = sistema_local["features"]
    else:
        # En producción: pedir la lista de features al Space de HF
        # (el Space expone GET /features)
        try:
            features_url = HF_MODEL_URL.replace("/predict", "/features")
            async with httpx.AsyncClient(timeout=10) as client:
                r = await client.get(features_url)
                features = r.json()["features"]
        except Exception:
            features = []

    # Validar síntomas
    reconocidos, no_reconocidos = validar_sintomas(sintomas, features)

    if not reconocidos:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Ningún síntoma reconocido. Comprueba los nombres e inténtalo de nuevo."
        )

    # Predecir
    if sistema_local:
        resultado = _predecir_local(reconocidos)
    else:
        resultado = await _predecir_remoto(reconocidos)

    # Añadir metadatos de síntomas y advertencia si procede
    resultado["sintomas_reconocidos"]   = reconocidos
    resultado["sintomas_no_reconocidos"] = no_reconocidos

    if len(reconocidos) < 3:
        resultado["advertencia"] = (
            "Menos de 3 síntomas reconocidos. "
            "Añade más síntomas para obtener un diagnóstico más preciso."
        )
    elif no_reconocidos:
        resultado["advertencia"] = (
            f"{len(no_reconocidos)} síntoma(s) no reconocido(s): "
            f"{', '.join(no_reconocidos[:3])}{'...' if len(no_reconocidos) > 3 else ''}."
        )
    else:
        resultado["advertencia"] = None

    return resultado