class SymptomCategory {
  final String id;
  final String name;        // ej. "Cabeza"
  final String bodyZone;    // zona en el SVG: head, chest, abdomen, etc.
  final List<String> symptoms; // lista de síntomas en inglés (snake_case)

  const SymptomCategory({
    required this.id,
    required this.name,
    required this.bodyZone,
    required this.symptoms,
  });
}