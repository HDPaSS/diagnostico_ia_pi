import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/diagnostico_model.dart';

class ResultScreen extends StatelessWidget {
  final DiagnosticoResult resultado;
  final List<String> sintomas;

  const ResultScreen({
    super.key,
    required this.resultado,
    required this.sintomas,
  });

  String _formatLabel(String s) =>
      s.replaceAll('_', ' ')[0].toUpperCase() +
      s.replaceAll('_', ' ').substring(1);

  Color _colorForIndex(int i) {
    const colors = [Color(0xFF1A6B5A), Color(0xFF2D9E87), Color(0xFF8ECFC4)];
    return colors[i % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final top = resultado.top3;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0D1F1B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Resultado',
          style: GoogleFonts.dmSerifDisplay(
              fontSize: 22, color: const Color(0xFF0D1F1B)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Advertencia médica
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.amber[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Resultado orientativo. Consulta siempre a un profesional médico.',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: Colors.amber[900]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Advertencia del modelo si hay síntomas no reconocidos
            if (resultado.advertencia != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        resultado.advertencia!,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Diagnóstico principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A6B5A), Color(0xFF2D9E87)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diagnóstico principal',
                    style: GoogleFonts.dmSans(
                        color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatLabel(top.first.enfermedad),
                    style: GoogleFonts.dmSerifDisplay(
                        color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(top.first.confianza * 100).toStringAsFixed(1)}% de confianza',
                    style: GoogleFonts.dmSans(
                        color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Categoría: ${_formatLabel(top.first.categoria)}',
                    style: GoogleFonts.dmSans(
                        color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gráfico de barras Top 3
            Text(
              'Top 3 diagnósticos',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D1F1B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: BarChart(
                BarChartData(
                  maxY: 1.0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                        '${(rod.toY * 100).toStringAsFixed(1)}%',
                        GoogleFonts.dmSans(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(
                          '${(v * 100).toInt()}%',
                          style: GoogleFonts.dmSans(
                              fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i >= top.length) return const SizedBox();
                          final label = _formatLabel(top[i].enfermedad);
                          final short = label.length > 14
                              ? '${label.substring(0, 12)}...'
                              : label;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              short,
                              style: GoogleFonts.dmSans(
                                  fontSize: 10, color: Colors.grey[700]),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey[100]!,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(top.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: top[i].confianza,
                          color: _colorForIndex(i),
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Lista detallada Top 3
            ...List.generate(top.length, (i) {
              final item = top[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _colorForIndex(i).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.dmSans(
                            color: _colorForIndex(i),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatLabel(item.enfermedad),
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF0D1F1B),
                            ),
                          ),
                          Text(
                            _formatLabel(item.categoria),
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(item.confianza * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _colorForIndex(i),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Síntomas usados
            Text(
              'Síntomas analizados',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D1F1B),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: resultado.sintomasReconocidos.map((s) {
                return Chip(
                  label: Text(_formatLabel(s),
                      style: GoogleFonts.dmSans(fontSize: 12)),
                  backgroundColor: const Color(0xFF1A6B5A).withOpacity(0.08),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Volver a diagnosticar
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Nuevo diagnóstico'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                foregroundColor: const Color(0xFF1A6B5A),
                side: const BorderSide(color: Color(0xFF1A6B5A)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}