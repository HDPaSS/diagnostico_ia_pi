import 'package:flutter/material.dart';
import '../../services/symptom_mappings.dart';
import '../body_map/body_map_screen.dart';
import 'result_screen.dart';
import 'assisted_predict_screen.dart';
import '../../services/translations.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _selectedSymptoms = [];
  final TextEditingController _searchController = TextEditingController();

  bool _searchMode = false;
  List<Map<String, String>> _globalSearchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: symptomCategories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatSymptom(String symptom) {
    return translateSymptom(symptom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar síntomas'),
        actions: [
          // Botón para abrir el mapa corporal
          IconButton(
            icon: const Icon(Icons.accessibility_new),
            tooltip: 'Mapa corporal',
            onPressed: () async {
              final result = await Navigator.push<List<String>>(
                context,
                MaterialPageRoute(
                  builder: (_) => BodyMapScreen(
                    initialSelection: _selectedSymptoms,
                  ),
                ),
              );
              if (result != null) {
                setState(() {
                  _selectedSymptoms
                    ..clear()
                    ..addAll(result);
                });
              }
            },
          ),
          // En el AppBar, dentro de actions:
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'Consulta asistida',
            onPressed: () async {
              final result = await Navigator.push<List<String>>(
                context,
                MaterialPageRoute(builder: (_) => const AssistedPredictScreen()),
              );
              if (result != null && result.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultScreen(symptoms: result),
                  ),  
                );
              }
            },
          ),

          // Chip que muestra el número de síntomas seleccionados
          if (_selectedSymptoms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(
                  '${_selectedSymptoms.length}',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar síntoma...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchMode = value.isNotEmpty;
                  if (_searchMode) {
                    _globalSearchResults = [];
                    for (var cat in symptomCategories) {
                      for (var symptom in cat.symptoms) {
                        final spanish = translateSymptom(symptom).toLowerCase();
                        if (spanish.contains(value.toLowerCase())) {
                          _globalSearchResults.add({
                            'sintoma': symptom,   // mantenemos la clave en inglés para enviar al backend
                            'categoria': cat.name,
                          });
                        }
                      }
                    }
                  }
                });
              },
            ),
          ),
          // Pestañas de categorías (solo si NO estamos en modo búsqueda)
          if (!_searchMode)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: symptomCategories
                  .map((category) => Tab(text: category.name))
                  .toList(),
            ),
          // Contenido principal (listado global o por pestañas)
          Expanded(
            child: _searchMode
                ? _buildGlobalSearchResults()
                : _buildCategorizedTabs(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedSymptoms.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultScreen(
                      symptoms: List<String>.from(_selectedSymptoms),
                    ),
                  ),
                );
              },
        icon: const Icon(Icons.search),
        label: const Text('Diagnosticar'),
      ),
    );
  }

  /// Vista de resultados de búsqueda global
  Widget _buildGlobalSearchResults() {
    if (_globalSearchResults.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron síntomas',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return ListView.builder(
      itemCount: _globalSearchResults.length,
      itemBuilder: (context, index) {
        final item = _globalSearchResults[index];
        final symptom = item['sintoma']!;
        final category = item['categoria']!;
        final isSelected = _selectedSymptoms.contains(symptom);
        return CheckboxListTile(
          title: Text('${translateSymptom(symptom)} - ${item['categoria']}'),
          value: isSelected,
          activeColor: Theme.of(context).primaryColor,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedSymptoms.add(symptom);
              } else {
                _selectedSymptoms.remove(symptom);
              }
            });
          },
        );
      },
    );
  }

  /// Vista normal por pestañas de categorías
  Widget _buildCategorizedTabs() {
    return TabBarView(
      controller: _tabController,
      children: symptomCategories.map((category) {
        final filteredSymptoms = category.symptoms;

        if (filteredSymptoms.isEmpty) {
          return Center(
            child: Text(
              'No se encontraron síntomas',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredSymptoms.length,
          itemBuilder: (context, index) {
            final symptom = filteredSymptoms[index];
            final isSelected = _selectedSymptoms.contains(symptom);
            return CheckboxListTile(
              title: Text(_formatSymptom(symptom)),
              value: isSelected,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedSymptoms.add(symptom);
                  } else {
                    _selectedSymptoms.remove(symptom);
                  }
                });
              },
            );
          },
        );
      }).toList(),
    );
  }
}

String _formatSymptom(String symptom) {
  return translateSymptom(symptom);
}