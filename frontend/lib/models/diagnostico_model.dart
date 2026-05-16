class DiagnosticoItem {
  final String enfermedad;
  final double confianza;
  final String categoria;

  DiagnosticoItem({
    required this.enfermedad,
    required this.confianza,
    required this.categoria,
  });

  factory DiagnosticoItem.fromJson(Map<String, dynamic> json) {
    return DiagnosticoItem(
      enfermedad: json['enfermedad'] ?? '',
      confianza: (json['confianza'] as num).toDouble(),
      categoria: json['categoria'] ?? '',
    );
  }
}


class DiagnosticoResult {
  final List<DiagnosticoItem> top3;
  final String categoriaPrincipal;
  final double confianzaCategoria;
  final List<String> sintomasReconocidos;
  final List<String> sintomasNoReconocidos;
  final String? advertencia;

  DiagnosticoResult({
    required this.top3,
    required this.categoriaPrincipal,
    required this.confianzaCategoria,
    required this.sintomasReconocidos,
    required this.sintomasNoReconocidos,
    this.advertencia,
  });

  factory DiagnosticoResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticoResult(
      top3: (json['top3'] as List)
          .map((e) => DiagnosticoItem.fromJson(e))
          .toList(),
      categoriaPrincipal: json['categoria_principal'] ?? '',
      confianzaCategoria: (json['confianza_categoria'] as num).toDouble(),
      sintomasReconocidos: List<String>.from(json['sintomas_reconocidos'] ?? []),
      sintomasNoReconocidos: List<String>.from(json['sintomas_no_reconocidos'] ?? []),
      advertencia: json['advertencia'],
    );
  }
}


class Consulta {
  final String consultaId;
  final String fecha;
  final List<String> sintomas;
  final DiagnosticoResult resultado;

  Consulta({
    required this.consultaId,
    required this.fecha,
    required this.sintomas,
    required this.resultado,
  });

  factory Consulta.fromJson(Map<String, dynamic> json) {
    return Consulta(
      consultaId: json['consulta_id'] ?? '',
      fecha: json['fecha'] ?? '',
      sintomas: List<String>.from(json['sintomas'] ?? []),
      resultado: DiagnosticoResult.fromJson(json['resultado']),
    );
  }
}