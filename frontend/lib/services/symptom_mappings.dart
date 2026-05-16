import '../models/symptom_category.dart';

// ── TODOS los síntomas están verificados contra symbipredict_expanded.csv ──

const List<SymptomCategory> symptomCategories = [

  // ─────────────────────────────────────────────
  // CABEZA / NEUROLÓGICO
  // ─────────────────────────────────────────────
  SymptomCategory(
    id: 'head',
    name: 'Cabeza',
    bodyZone: 'head',
    symptoms: [
      'headache',
      'dizziness',
      'vertigo',
      'stiff_neck',
      'neck_pain',
      'sensitivity_to_light',
      'blurred_vision',
      'blurred_and_distorted_vision',
      'double_vision',
      'eye_pain',
      'redness_of_eyes',
      'ear_pain',
      'hearing_loss',
      'nasal_congestion',
      'runny_nose',
      'continuous_sneezing',
      'loss_of_smell',
      'visual_disturbances',
      'altered_sensorium',
      'disabling_migraines',
      'facial_numbness',
      'pain_behind_the_eyes',
    ],
  ),

  // ─────────────────────────────────────────────
  // PECHO / CARDIO-RESPIRATORIO
  // ─────────────────────────────────────────────
  SymptomCategory(
    id: 'chest',
    name: 'Pecho',
    bodyZone: 'chest',
    symptoms: [
      'chest_pain',
      'chest_tightness',
      'palpitations',
      'breathlessness',
      'shortness_of_breath',
      'difficulty_breathing',
      'wheezing',
      'cough',
      'cough_with_phlegm_or_pus',
      'phlegm',
      'rapid_breathing',
      'sore_throat',
      'throat_irritation',
      'swollen_lymph_nodes',
      'fast_heart_rate',
      'irregular_heartbeat',
      'hoarseness',
      'stridor',
    ],
  ),

  // ─────────────────────────────────────────────
  // ABDOMEN / DIGESTIVO
  // ─────────────────────────────────────────────
  SymptomCategory(
    id: 'abdomen',
    name: 'Abdomen',
    bodyZone: 'abdomen',
    symptoms: [
      'abdominal_pain',
      'stomach_pain',
      'abdominal_bloating',
      'abdominal_cramps',
      'nausea',
      'vomiting',
      'diarrhoea',
      'constipation',
      'acid_reflux',
      'acidity',
      'heartburn',
      'indigestion',
      'loss_of_appetite',
      'excessive_hunger',
      'increased_appetite',
      'weight_loss',
      'weight_gain',
      'yellowish_skin',
      'yellowing_of_eyes',
      'dark_urine',
      'passage_of_gases',
      'distention_of_abdomen',
      'belly_pain',
      'bloody_stool',
      'mucoid_sputum',
    ],
  ),

  // ─────────────────────────────────────────────
  // ESPALDA / MUSCULOESQUELÉTICO
  // ─────────────────────────────────────────────
  SymptomCategory(
    id: 'back',
    name: 'Espalda',
    bodyZone: 'back',
    symptoms: [
      'back_pain',
      'lower_back_pain',
      'backache',
      'low_back_pain',
      'neck_or_back_pain',
      'chronic_back_pain_and_stiffness',
      'muscle_pain',
      'joint_pain',
      'stiffness',
      'muscle_weakness',
      'neck_stiffness',
      'spasm',
      'tetany_muscle_spasms',
      'hip_joint_pain',
      'knee_pain',
    ],
  ),

  // ─────────────────────────────────────────────
  // EXTREMIDADES
  // ─────────────────────────────────────────────
  SymptomCategory(
    id: 'limbs',
    name: 'Extremidades',
    bodyZone: 'limbs',
    symptoms: [
      'leg_pain',
      'arm',
      'joint_swelling',
      'swollen_legs',
      'cold_hands_and_feets',
      'heavy_legs',
      'cramping',
      'cramps',
      'muscle_cramps',
      'numbness',
      'tingling',
      'intense_joint_pain',
      'joint_and_muscle_pain',
      'weakness_in_limbs',
      'weakness_of_one_body_side',
      'movement_stiffness',
      'loss_of_balance',
      'foot_pain_or_achiness',
      'foot_fatigue',
      'swelling_joints',
      'painful_walking',
    ],
  ),

  // ─────────────────────────────────────────────
  // PIEL
  // ─────────────────────────────────────────────
  SymptomCategory(
    id: 'skin',
    name: 'Piel',
    bodyZone: 'skin',
    symptoms: [
      'skin_rash',
      'itching',
      'itchy_skin',
      'itchy_bumps',
      'intense_itching',
      'itching_or_burning_sensation',
      'redness',
      'nodal_skin_eruptions',
      'abnormal_sweating',
      'excessive_sweating_beyond_what_is_necessary_for_temperature_regulation',
      'night_sweats',
      'sweating',
      'dry_skin',
      'bruising',
      'acne',
      'pus_filled_pimples',
      'blackheads',
      'scurring',
      'skin_peeling',
      'silver_like_dusting',
      'small_dents_in_nails',
      'inflammatory_nails',
      'blister',
      'red_sore_around_nose',
      'yellow_crust_ooze',
      'dischromic__patches',
    ],
  ),

  // ─────────────────────────────────────────────
  // GENERALES / SISTÉMICOS
  // ─────────────────────────────────────────────
  SymptomCategory(
    id: 'general',
    name: 'Generales',
    bodyZone: 'general',
    symptoms: [
      'fever',
      'high_fever',
      'mild_fever',
      'chills',
      'shivering',
      'fatigue',
      'malaise',
      'weakness',
      'lethargy',
      'irritability',
      'insomnia',
      'sleeplessness',
      'restless_sleep',
      'sleep_disturbances',
      'dehydration',
      'fluid_overload',
      'sunken_eyes',
      'pale_skin',
      'puffy_face_and_eyes',
      'swollen_blood_vessels',
      'enlarged_thyroid',
      'swollen_extremeties',
      'brittle_nails',
      'excessive_hunger',
      'irregular_sugar_level',
      'polyuria',
      'loss_of_consciousness',
      'altered_perception_of_reality',
    ],
  ),
];

// ─────────────────────────────────────────────
// MAPEO DE PREGUNTAS DE SEGUIMIENTO POR ZONA
// ─────────────────────────────────────────────
const Map<String, List<String>> categoryQuestions = {
  'head': [
    'fever',
    'headache',
    'dizziness',
    'nausea',
    'blurred_vision',
    'stiff_neck',
    'sensitivity_to_light',
    'ear_pain',
  ],
  'chest': [
    'cough',
    'fever',
    'breathlessness',
    'chest_pain',
    'fatigue',
    'wheezing',
    'palpitations',
    'sore_throat',
  ],
  'abdomen': [
    'abdominal_pain',
    'nausea',
    'vomiting',
    'diarrhoea',
    'loss_of_appetite',
    'abdominal_bloating',
    'constipation',
    'yellowish_skin',
  ],
  'back': [
    'back_pain',
    'muscle_pain',
    'stiffness',
    'joint_pain',
    'neck_pain',
    'leg_pain',
  ],
  'limbs': [
    'joint_pain',
    'muscle_pain',
    'joint_swelling',
    'numbness',
    'tingling',
    'muscle_cramps',
  ],
  'skin': [
    'skin_rash',
    'itching',
    'redness',
    'dry_skin',
    'bruising',
    'night_sweats',
  ],
  'general': [
    'fever',
    'fatigue',
    'weakness',
    'chills',
    'malaise',
    'insomnia',
  ],
};

// Índice rápido síntoma → categorías
Map<String, List<String>> buildSymptomToCategories() {
  final map = <String, List<String>>{};
  for (var cat in symptomCategories) {
    for (var s in cat.symptoms) {
      map.putIfAbsent(s, () => []).add(cat.id);
    }
  }
  return map;
}