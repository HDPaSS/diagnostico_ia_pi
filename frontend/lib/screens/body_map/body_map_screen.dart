import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/symptom_category.dart';
import '../../services/symptom_mappings.dart';

// ─────────────────────────────────────────────────────────────
// Zona táctil definida en porcentajes del ancho/alto del lienzo.
// Así funciona igual en cualquier tamaño de pantalla.
// ─────────────────────────────────────────────────────────────
class _RelativeZone {
  final double left;   // 0.0 → 1.0
  final double top;
  final double width;
  final double height;
  const _RelativeZone(this.left, this.top, this.width, this.height);

  Rect toRect(double canvasW, double canvasH) => Rect.fromLTWH(
        left * canvasW,
        top * canvasH,
        width * canvasW,
        height * canvasH,
      );
}

class BodyMapScreen extends StatefulWidget {
  final List<String> initialSelection;
  const BodyMapScreen({super.key, this.initialSelection = const []});

  @override
  State<BodyMapScreen> createState() => _BodyMapScreenState();
}

class _BodyMapScreenState extends State<BodyMapScreen> {
  late List<String> _selectedSymptoms;
  bool _showFront = true;
  String? _activeZone;
  List<String> _currentZoneSymptoms = [];

  // ── Mapa zona → categoría ──────────────────────────────────
  static const Map<String, String> _zoneToCategory = {
    'head':            'head',
    'chest':           'chest',
    'abdomen':         'abdomen',
    'left_arm':        'limbs',
    'right_arm':       'limbs',
    'left_leg':        'limbs',
    'right_leg':       'limbs',
    'upper_back':      'back',
    'lower_back':      'back',
  };

  // ── Zonas FRENTE en porcentajes (viewBox 250×500) ──────────
  // Cada zona: left%, top%, width%, height%
  static const Map<String, _RelativeZone> _frontZones = {
    'head':       _RelativeZone(0.28, 0.00, 0.44, 0.18),  // cx=125 cy=42 rx=36 ry=44
    'chest':      _RelativeZone(0.30, 0.18, 0.40, 0.22),  // torso superior
    'abdomen':    _RelativeZone(0.30, 0.40, 0.40, 0.22),  // torso inferior
    'left_arm':   _RelativeZone(0.00, 0.18, 0.28, 0.40),  // brazo + antebrazo izq
    'right_arm':  _RelativeZone(0.72, 0.18, 0.28, 0.40),  // brazo + antebrazo der
    'left_leg':   _RelativeZone(0.28, 0.62, 0.20, 0.38),  // pierna izq
    'right_leg':  _RelativeZone(0.52, 0.62, 0.20, 0.38),  // pierna der
  };

  // ── Zonas ESPALDA en porcentajes ───────────────────────────
  static const Map<String, _RelativeZone> _backZones = {
    'head':       _RelativeZone(0.28, 0.00, 0.44, 0.18),
    'upper_back': _RelativeZone(0.26, 0.18, 0.48, 0.24),
    'lower_back': _RelativeZone(0.28, 0.42, 0.44, 0.22),
    'left_arm':   _RelativeZone(0.00, 0.18, 0.26, 0.38),
    'right_arm':  _RelativeZone(0.74, 0.18, 0.26, 0.38),
    'left_leg':   _RelativeZone(0.28, 0.64, 0.20, 0.36),
    'right_leg':  _RelativeZone(0.52, 0.64, 0.20, 0.36),
  };

  @override
  void initState() {
    super.initState();
    _selectedSymptoms = List<String>.from(widget.initialSelection);
  }

  // ── Helpers ───────────────────────────────────────────────
  String _getZoneName(String? zoneId) {
    if (zoneId == null) return '';
    final catId = _zoneToCategory[zoneId] ?? '';
    return symptomCategories
        .firstWhere((c) => c.id == catId,
            orElse: () => symptomCategories.first)
        .name;
  }

  String _formatSymptom(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');

  void _onZoneTap(String zoneId) {
    final catId = _zoneToCategory[zoneId];
    if (catId == null) return;
    final cat = symptomCategories.firstWhere(
      (c) => c.id == catId,
      orElse: () => symptomCategories.first,
    );
    setState(() {
      _activeZone = zoneId;
      _currentZoneSymptoms = cat.symptoms;
    });
    _showPicker();
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            builder: (_, sc) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Síntomas — ${_getZoneName(_activeZone)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      controller: sc,
                      itemCount: _currentZoneSymptoms.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final s = _currentZoneSymptoms[i];
                        final sel = _selectedSymptoms.contains(s);
                        return CheckboxListTile(
                          title: Text(_formatSymptom(s)),
                          value: sel,
                          activeColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) {
                            setModal(() => v == true
                                ? _selectedSymptoms.add(s)
                                : _selectedSymptoms.remove(s));
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Confirmar selección',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final zones = _showFront ? _frontZones : _backZones;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa corporal'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _showFront ? 'Ver espalda' : 'Ver frente',
            icon: Icon(_showFront
                ? Icons.accessibility_new
                : Icons.directions_run),
            onPressed: () => setState(() {
              _showFront = !_showFront;
              _activeZone = null;
            }),
          ),
          if (_selectedSymptoms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Chip(
                  label: Text(
                    '${_selectedSymptoms.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculamos el tamaño del lienzo manteniendo la proporción
          // 250:500 = 1:2 del SVG original
          const double svgAspect = 250 / 500; // ancho / alto
          final double maxH = constraints.maxHeight * 0.90;
          final double maxW = constraints.maxWidth * 0.80;

          double canvasH = maxH;
          double canvasW = canvasH * svgAspect;
          if (canvasW > maxW) {
            canvasW = maxW;
            canvasH = canvasW / svgAspect;
          }

          return Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 2.5,
              child: SizedBox(
                width: canvasW,
                height: canvasH,
                child: Stack(
                  children: [
                    // SVG de fondo
                    SvgPicture.asset(
                      _showFront
                          ? 'assets/body_front.svg'
                          : 'assets/body_back.svg',
                      width: canvasW,
                      height: canvasH,
                      fit: BoxFit.fill,
                    ),

                    // Zonas táctiles — coordenadas calculadas en tiempo de ejecución
                    ...zones.entries.map((entry) {
                      final rect = entry.value.toRect(canvasW, canvasH);
                      final isActive = _activeZone == entry.key;
                      return Positioned(
                        left: rect.left,
                        top: rect.top,
                        width: rect.width,
                        height: rect.height,
                        child: GestureDetector(
                          onTap: () => _onZoneTap(entry.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.22)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isActive
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _selectedSymptoms.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pop(context, _selectedSymptoms),
              icon: const Icon(Icons.done_all),
              label: Text('Listo (${_selectedSymptoms.length})'),
            )
          : null,
    );
  }
}