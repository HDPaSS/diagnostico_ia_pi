import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/diagnostico_model.dart';
import '../../services/translations.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultScreen extends StatefulWidget {
  final List<String> symptoms;
  final DiagnosticoResult? previousResult;

  const ResultScreen({
    super.key,
    required this.symptoms,
    this.previousResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<DiagnosticoResult> _futureResult;

  @override
  void initState() {
    super.initState();
    if (widget.previousResult != null) {
      _futureResult = Future.value(widget.previousResult);
    } else {
      _futureResult = ApiService.predict(widget.symptoms)
          .then((map) => DiagnosticoResult.fromJson(map));
    }
  }

  // ── Abre la búsqueda en el navegador del sistema ──────────
  // platformDefault funciona en Android (abre el navegador por defecto),
  // en Web (abre una nueva pestaña) y en iOS sin configuración extra.
  Future<void> _openSearch(String enfermedad) async {
    final query = Uri.encodeComponent('definición médica $enfermedad');
    final url = Uri.parse('https://www.google.com/search?q=$query');

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.platformDefault,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el navegador')),
        );
      }
    } catch (_) {
      // Último fallback sin especificar modo
      try {
        await launchUrl(url);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al abrir: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
      ),
      body: FutureBuilder<DiagnosticoResult>(
        future: _futureResult,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Analizando síntomas...'),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final resultado = snapshot.data;
          if (resultado == null || resultado.top3.isEmpty) {
            return const Center(
              child: Text('No se encontraron diagnósticos probables.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (resultado.advertencia != null)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber,
                            color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(child: Text(resultado.advertencia!)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Categoría principal: ${resultado.categoriaPrincipal} '
                '(${(resultado.confianzaCategoria * 100).toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (resultado.sintomasReconocidos.isNotEmpty)
                Text(
                  'Síntomas analizados: ${resultado.sintomasReconocidos.join(", ")}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              if (resultado.sintomasNoReconocidos.isNotEmpty)
                Text(
                  'No reconocidos: ${resultado.sintomasNoReconocidos.join(", ")}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.redAccent),
                ),
              const SizedBox(height: 24),
              ...resultado.top3.asMap().entries.map((entry) {
                final index = entry.key;
                final diag = entry.value;
                final nombreEs = translateDisease(diag.enfermedad);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. $nombreEs',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Categoría: ${diag.categoria}'),
                        Text(
                          'Confianza: ${(diag.confianza * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: diag.confianza,
                          backgroundColor: Colors.grey[300],
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Text('Información'),
                            onPressed: () => _openSearch(nombreEs),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}