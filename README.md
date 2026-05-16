# DiagnósticIA 🩺

**Sistema de predicción de enfermedades basado en síntomas mediante IA.**  
Aplicación multiplataforma (Web + Android) construida con Flutter, FastAPI y Firebase, que utiliza un modelo híbrido Random Forest + XGBoost entrenado sobre más de 20.000 registros clínicos sintomáticos.

> ⚠️ **Aviso importante:** Este proyecto es de carácter académico y las predicciones no sustituyen el diagnóstico de un profesional médico.

---

## 📐 Arquitectura general
```
[Usuario]
   │
   ▼
[Flutter App]  (Firebase Hosting / APK)
   │  Firebase Auth + Firestore
   ▼
[Backend FastAPI]  (Hugging Face Space)
   │  Valida tokens, gestiona usuarios e historial
   ▼
[Microservicio Modelo IA]  (Hugging Face Space)
   │  Sistema híbrido RF + XGBoost
   └── Devuelve top 3 de diagnósticos con confianza
```


---

## ✨ Funcionalidades principales

- **Autenticación** con email/contraseña a través de Firebase Auth.
- **Predicción rápida** seleccionando síntomas desde una lista categorizada.
- **Mapa corporal interactivo** con zonas táctiles para seleccionar síntomas por región anatómica.
- **Consulta asistida** paso a paso (pregunta principal y preguntas de seguimiento).
- **Historial** de consultas realizadas, ordenado por fecha.
- **Perfil de usuario** con opciones de cambio de contraseña y eliminación total de la cuenta (borrado en Firebase Auth y Firestore).
- **Traducción completa al español** de síntomas (1385 términos) y enfermedades (557 enfermedades).
- **Búsqueda global** de síntomas con autocompletado.

---

## 🧠 Modelo de Inteligencia Artificial

| Característica          | Descripción |
|------------------------|-------------|
| **Tipo**               | Sistema híbrido Random Forest (categorización) + XGBoost especializado por categoría médica |
| **Entradas**           | 1385 síntomas binarios (presentes/ausentes) |
| **Salidas**            | 557 enfermedades posibles, agrupadas en categorías clínicas |
| **Dataset original**   | `symbipredict_2022.csv` (4961 filas, 132 síntomas, 41 enfermedades) |
| **Dataset ampliado**   | 20.471 filas generadas a partir de datasets públicos de HuggingFace (`QuyenAnhDE/Diseases_Symptoms`, `hanzohazashi1/llama_symptoms`) |
| **Métrica**            | Accuracy ponderado ~85% (varía según categoría) |
| **Optimización**       | Compresión zlib nivel 9, reducción de estimadores (300→150) para despliegue |

El modelo se sirve como microservicio independiente en HuggingFace Spaces, exponiendo endpoints `POST /predict` y `GET /features`.

---

## 🛠️ Stack tecnológico

### Frontend
- **Flutter 3.27** (Dart)
- Firebase Auth + Firestore
- Paquetes: `fl_chart`, `flutter_svg`, `url_launcher`, `google_fonts`, `intl`

### Backend
- **FastAPI** (Python 3.11)
- Firebase Admin SDK
- `httpx` para comunicación con el microservicio del modelo
- Desplegado como Docker container en HuggingFace Spaces

### Base de datos
- **Cloud Firestore** (NoSQL): usuarios, consultas, resultados

### Despliegue
| Componente            | Plataforma          |
|-----------------------|---------------------|
| Modelo IA             | HuggingFace Spaces  |
| API Backend           | HuggingFace Spaces  |
| Frontend Web          | Firebase Hosting    |
| APK Android           | Distribución directa |

---

## 🚀 Instalación y ejecución local

### Requisitos previos
- Python 3.10+
- Flutter 3.27+
- Firebase CLI (para despliegue)
- Git LFS (si se manejan archivos grandes)

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp firebase_key.json .   # clave privada de Firebase (no incluida en el repo)
python main.py
