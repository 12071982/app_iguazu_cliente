class Paquete {
  final int idPaquete;
  final int idDestino;
  final String nombre;
  final String descripcion;
  final String duracion;
  final double precioBase;
  final String tipo;
  final String fechaInicio;
  final String fechaFin;
  final String inclusiones;
  final String exclusiones;
  final String? imagen;

  Paquete({
    required this.idPaquete,
    required this.idDestino,
    required this.nombre,
    required this.descripcion,
    required this.duracion,
    required this.precioBase,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.inclusiones,
    required this.exclusiones,
    this.imagen,
  });

  factory Paquete.fromJson(Map<String, dynamic> json) {
    return Paquete(
      idPaquete: json['iD_Paquete'],
      idDestino: json['iD_Destino'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      duracion: json['duracion'],
      precioBase: (json['precio_Base'] as num).toDouble(),
      tipo: json['tipo'],
      fechaInicio: json['fecha_Inicio'],
      fechaFin: json['fecha_Fin'],
      inclusiones: json['inclusiones'],
      exclusiones: json['exclusiones'],
      imagen: json['imagen'],
    );
  }
}
