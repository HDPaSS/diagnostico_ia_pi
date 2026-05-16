import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/diagnostico_model.dart';
import 'result_screen.dart';

// Lista de síntomas más comunes para el autocompletado
const List<String> kSintomas = [
  'fatigue', 'vomiting', 'fever', 'headache', 'nausea', 'dizziness',
  'chest_pain', 'cough', 'breathlessness', 'abdominal_pain', 'back_pain',
  'joint_pain', 'muscle_pain', 'skin_rash', 'itching', 'yellowish_skin',
  'weight_loss', 'weight_gain', 'loss_of_appetite', 'sweating', 'chills',
  'shivering', 'high_fever', 'mild_fever', 'swelling', 'pain_behind_eyes',
  'blurred_vision', 'runny_nose', 'throat_irritation', 'swollen_lymph_nodes',
  'malaise', 'phlegm', 'throat_pain', 'ulcers_on_tongue', 'stomach_pain',
  'acidity', 'indigestion', 'muscle_weakness', 'stiff_neck', 'swollen_legs',
  'anxiety', 'cold_hands_and_feet', 'mood_swings', 'restlessness',
  'irregular_sugar_level', 'polyuria', 'increased_appetite', 'excessive_hunger',
  'dark_urine', 'yellowing_of_eyes', 'bruising', 'dehydration',
  'diarrhoea', 'constipation', 'loss_of_smell', 'loss_of_taste',
  'fast_heart_rate', 'palpitations', 'breathlessness', 'weakness_of_limbs',
  'neck_pain', 'knee_pain', 'hip_joint_pain', 'muscle_weakness',
  'burning_micturition', 'continuous_sneezing', 'watering_from_eyes',
  'patches_in_throat', 'red_spots_over_body', 'nodal_skin_eruptions',
  'dischromic_patches', 'spotting_urination', 'foul_smell_of_urine',
  'puffy_face_and_eyes', 'enlarged_thyroid', 'brittle_nails',
  'swollen_extremeties', 'excessive_hunger', 'drying_and_tingling_lips',
  'slurred_speech', 'weakness_in_limbs', 'altered_sensorium',
];

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final _searchCtrl = TextEditingController();
  final List<String> _seleccionados = [];
  List<String> _sugerencias = [];
  bool _loading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _sugerencias = []);
      return;
    }
    final q = query.toLowerCase().replaceAll(' ', '_');
    setState(() {
      _sugerencias = kSintomas
          .where((s) => s.contains(q) && !_seleccionados.contains(s))
          .take(6)
          .toList();
    });
  }

  void _addSintoma(String sintoma) {
    if (_seleccionados.contains(sintoma)) return;
    setState(() {
      _seleccionados.add(sintoma);
      _sugerencias = [];
      _searchCtrl.clear();
    });
  }

  void _removeSintoma(String sintoma) {
    setState(() => _seleccionados.remove(sintoma));
  }

  String _formatSintoma(String s) =>
      s.replaceAll('_', ' ')[0].toUpperCase() +
      s.replaceAll('_', ' ').substring(1);

  Future<void> _predict() async {
    if (_seleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un síntoma')),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      final data = await ApiService.predict(_seleccionados);
      final result = DiagnosticoResult.fromJson(data);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            resultado: result,
            sintomas: List.from(_seleccionados),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A6B5A), Color(0xFF2D9E87)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Añade tus síntomas para obtener un diagnóstico orientativo. No sustituye a un médico.',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Buscador
          Text(
            'Buscar síntomas',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D1F1B),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Escribe un síntoma (ej: fatigue, fever...)',
              hintStyle: GoogleFonts.dmSans(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _sugerencias = []);
                      },
                    )
                  : null,
            ),
          ),

          // Sugerencias
          if (_sugerencias.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: _sugerencias.map((s) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.add_circle_outline,
                        color: Color(0xFF1A6B5A), size: 20),
                    title: Text(
                      _formatSintoma(s),
                      style: GoogleFonts.dmSans(fontSize: 14),
                    ),
                    onTap: () => _addSintoma(s),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Síntomas seleccionados
          Row(
            children: [
              Text(
                'Síntomas seleccionados',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D1F1B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A6B5A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_seleccionados.length}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A6B5A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_seleccionados.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.medical_services_outlined,
                      color: Colors.grey[300], size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Ningún síntoma añadido',
                    style: GoogleFonts.dmSans(
                        color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _seleccionados.map((s) {
                return Chip(
                  label: Text(
                    _formatSintoma(s),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF1A6B5A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: const Color(0xFF1A6B5A).withOpacity(0.1),
                  deleteIconColor: const Color(0xFF1A6B5A),
                  side: BorderSide.none,
                  onDeleted: () => _removeSintoma(s),
                );
              }).toList(),
            ),

          const SizedBox(height: 32),

          // Botón analizar
          ElevatedButton.icon(
            onPressed: _loading ? null : _predict,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.analytics_rounded),
            label: Text(_loading ? 'Analizando...' : 'Analizar síntomas'),
          ),
        ],
      ),
    );
  }
}