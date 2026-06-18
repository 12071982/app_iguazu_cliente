class Pago {
  final int? idPago;
  final int idReserva;
  final String fechaPago;
  final String metodoPago;
  final double monto;
  final String numeroTransaccion;
 
  Pago({
    this.idPago,
    required this.idReserva,
    required this.fechaPago,
    required this.metodoPago,
    required this.monto,
    required this.numeroTransaccion,
  });
 
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'iD_Reserva': idReserva,
      'fecha_Pago': fechaPago,
      'metodo_Pago': metodoPago,
      'monto': monto,
      'numero_Transaccion': numeroTransaccion,
    };
    if (idPago != null) map['iD_Pago'] = idPago;
    return map;
  }
 
  factory Pago.fromJson(Map<String, dynamic> json) => Pago(
        idPago: json['iD_Pago'] as int?,
        idReserva: (json['iD_Reserva'] as num).toInt(),
        fechaPago: json['fecha_Pago'] as String? ?? '',
        metodoPago: json['metodo_Pago'] as String? ?? '',
        monto: (json['monto'] as num).toDouble(),
        numeroTransaccion: json['numero_Transaccion'] as String? ?? '',
      );
}