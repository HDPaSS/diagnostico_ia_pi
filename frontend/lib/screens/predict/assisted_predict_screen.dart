import 'package:flutter/material.dart';
import '../../models/symptom_category.dart';
import '../../services/symptom_mappings.dart';
import '../../services/translations.dart'; 

class AssistedPredictScreen extends StatefulWidget {
  const AssistedPredictScreen({super.key});

  @override
  State<AssistedPredictScreen> createState() => _AssistedPredictScreenState();
}

class _AssistedPredictScreenState extends State<AssistedPredictScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _mainSymptom;
  List<String> _allQuestions = [];
  int _currentIndex = 0;
  final Set<String> _selectedSymptoms = {};

  bool get _isMainStep => _mainSymptom == null;

  // Todas las opciones de autocompletado
  List<String> get _allSymptoms {
    final symptoms = <String>{};
    for (var cat in symptomCategories) {
      symptoms.addAll(cat.symptoms);
    }
    return symptoms.toList()..sort();
  }

  // Formateo traducido
  String _formatSymptom(String s) => translateSymptom(s);

  void _startQuestions(String symptom) {
    setState(() {
      _mainSymptom = symptom;
      _selectedSymptoms.add(symptom);
    });

    // Buscar la categoría del síntoma
    String? categoryId;
    for (var cat in symptomCategories) {
      if (cat.symptoms.contains(symptom)) {
        categoryId = cat.id;
        break;
      }
    }
    categoryId ??= 'general';

    final rawQuestions = categoryQuestions[categoryId] ?? categoryQuestions['general']!;
    // Eliminar el síntoma principal de las preguntas (para no preguntarlo)
    _allQuestions = rawQuestions.where((q) => q != symptom).toList();
    _currentIndex = 0;
  }

  void _answerQuestion(bool positive) {
    if (_currentIndex >= _allQuestions.length) return;
    final symptom = _allQuestions[_currentIndex];
    if (positive) {
      _selectedSymptoms.add(symptom);
    }
    setState(() {
      _currentIndex++;
    });
  }

  void _finish() {
    Navigator.pop(context, _selectedSymptoms.toList());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta asistida'),
        actions: [
          if (!_isMainStep && _selectedSymptoms.isNotEmpty)
            TextButton(
              onPressed: _finish,
              child: const Text('Finalizar'),
            ),
        ],
      ),
      body: _isMainStep ? _buildMainSymptomStep(theme) : _buildQuestionStep(theme),
    );
  }

  Widget _buildMainSymptomStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.medical_services_outlined, size: 64, color: theme.primaryColor),
          const SizedBox(height: 16),
          Text(
            '¿Cuál es tu síntoma principal?',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) {
              final query = textEditingValue.text.toLowerCase();
              if (query.isEmpty) return const Iterable<String>.empty();
              // Busca en español (traducción)
              return _allSymptoms.where((s) =>
                  translateSymptom(s).toLowerCase().contains(query));
            },
            displayStringForOption: (option) => _formatSymptom(option),
            onSelected: _startQuestions,
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              _searchController.text = controller.text;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Buscar síntoma...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => controller.clear(),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(_formatSymptom(option)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Escribe un síntoma y selecciónalo de la lista.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionStep(ThemeData theme) {
    if (_currentIndex >= _allQuestions.length) {
      return _buildSummary(theme);
    }
    final currentSymptom = _allQuestions[_currentIndex];
    final progress = (_currentIndex + 1) / _allQuestions.length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 32),
          Text(
            'Pregunta ${_currentIndex + 1} de ${_allQuestions.length}',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            '¿Presentas ${_formatSymptom(currentSymptom).toLowerCase()}?',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AnswerButton(
                label: 'Sí',
                color: Colors.green,
                icon: Icons.check,
                onPressed: () => _answerQuestion(true),
              ),
              _AnswerButton(
                label: 'No',
                color: Colors.red,
                icon: Icons.close,
                onPressed: () => _answerQuestion(false),
              ),
              _AnswerButton(
                label: 'No sé',
                color: Colors.grey,
                icon: Icons.help_outline,
                onPressed: () => _answerQuestion(false),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: _finish,
            child: const Text('Finalizar consulta ahora'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: theme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Resumen de síntomas',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedSymptoms.length,
              itemBuilder: (_, i) {
                final s = _selectedSymptoms.elementAt(i);
                return ListTile(
                  leading: Icon(Icons.sick, color: theme.primaryColor),
                  title: Text(_formatSymptom(s)),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: Text('Diagnosticar (${_selectedSymptoms.length} síntomas)'),
            onPressed: _finish,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}



class _AnswerButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _AnswerButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}