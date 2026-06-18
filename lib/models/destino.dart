class Destino {
  final int id;
  final String nombre;
  final String pais;
  final String ciudad;
  final String atracciones;
  final String clima;
  final String idioma;
  final String moneda;

  Destino({
    required this.id,
    required this.nombre,
    required this.pais,
    required this.ciudad,
    required this.atracciones,
    required this.clima,
    required this.idioma,
    required this.moneda,
  });

  factory Destino.fromJson(Map<String, dynamic> json) {
    return Destino(
      id: json['iD_Destino'],
      nombre: json['nombre'],
      pais: json['pais'],
      ciudad: json['ciudad'],
      atracciones: json['atracciones'],
      clima: json['clima'],
      idioma: json['idioma'],
      moneda: json['moneda'],
    );
  }
}
