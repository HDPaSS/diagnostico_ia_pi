import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/diagnostico_model.dart';
import '../predict/result_screen.dart';
import '../../services/translations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Consulta>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadHistory();
  }

  Future<List<Consulta>> _loadHistory() async {
    final data = await ApiService.getHistory();
    final raw = data['consultas'] as List;
    return raw.map((e) => Consulta.fromJson(e)).toList();
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _formatLabel(String s) =>
      s.replaceAll('_', ' ')[0].toUpperCase() +
      s.replaceAll('_', ' ').substring(1);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Consulta>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 48),
                const SizedBox(height: 12),
                Text(
                  'Error al cargar el historial',
                  style: GoogleFonts.dmSans(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final result = await _loadHistory();
                    setState(() {
                      _future = Future.value(result);
                    });
                  }             ,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 44)),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final consultas = snap.data ?? [];

        if (consultas.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, color: Colors.grey[300], size: 56),
                const SizedBox(height: 14),
                Text(
                  'Sin consultas aún',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 20, color: Colors.grey[500]),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tus diagnósticos aparecerán aquí',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF1A6B5A),
          onRefresh: () async {
            final result = await _loadHistory();
            setState(() {
              _future = Future.value(result);
            });
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: consultas.length,
            itemBuilder: (_, i) {
              final c = consultas[i];
              final top1 = c.resultado.top3.first;

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultScreen(
                      symptoms: c.sintomas,
                      previousResult: c.resultado,
                    ),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A6B5A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.medical_information_outlined,
                            color: Color(0xFF1A6B5A), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translateDisease(top1.enfermedad),
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: const Color(0xFF0D1F1B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${c.sintomas.length} síntomas · ${_formatDate(c.fecha)}',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(top1.confianza * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: const Color(0xFF1A6B5A),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.grey, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}