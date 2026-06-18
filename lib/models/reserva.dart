class Reserva {
  final int? idReserva;
  final int idCliente;
  final int idPaquete;
  final String fechaReserva;
  final int numeroPersonas;
  final double precioTotal;
  final String estatus;
  final String observaciones;
 
  Reserva({
    this.idReserva,
    required this.idCliente,
    required this.idPaquete,
    required this.fechaReserva,
    required this.numeroPersonas,
    required this.precioTotal,
    required this.estatus,
    required this.observaciones,
  });
 
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'iD_Cliente': idCliente,
      'iD_Paquete': idPaquete,
      'fecha_Reserva': fechaReserva,
      'numero_Personas': numeroPersonas,
      'precio_Total': precioTotal,
      'estatus': estatus,
      'observaciones': observaciones,
    };
    if (idReserva != null) map['iD_Reserva'] = idReserva;
    return map;
  }
 
  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
        idReserva: json['iD_Reserva'] as int?,
        idCliente: (json['iD_Cliente'] as num).toInt(),
        idPaquete: (json['iD_Paquete'] as num).toInt(),
        fechaReserva: json['fecha_Reserva'] as String? ?? '',
        numeroPersonas: (json['numero_Personas'] as num).toInt(),
        precioTotal: (json['precio_Total'] as num).toDouble(),
        estatus: json['estatus'] as String? ?? '',
        observaciones: json['observaciones'] as String? ?? '',
      );
}