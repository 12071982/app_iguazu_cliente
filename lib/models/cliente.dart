class Cliente {
  final int? idCliente;
  final int idUsuario;
  final String frecuenciaViajero;
  final String correo;
  final String nombre;
  final String apellido;
  final String telefono;
  final String direccion;
  final String nacionalidad;
  final String pasaporte;
  final String fechaNacimiento;

  Cliente({
    this.idCliente,
    required this.idUsuario,
    required this.frecuenciaViajero,
    required this.correo,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.direccion,
    required this.nacionalidad,
    required this.pasaporte,
    required this.fechaNacimiento,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      // ✅ NO incluir iD_Cliente si es null
      // La API de .NET lo genera automáticamente (IDENTITY)
      'iD_Usuario': idUsuario,
      'frecuencia_Viajero': frecuenciaViajero,
      'correo': correo,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'direccion': direccion,
      'nacionalidad': nacionalidad,
      'pasaporte': pasaporte,
      'fecha_Nacimiento': fechaNacimiento,
    };
    // Solo incluir el ID si ya existe (edición, no creación)
    if (idCliente != null) {
      map['iD_Cliente'] = idCliente;
    }
    return map;
  }

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        idCliente: json['iD_Cliente'] as int?,
        idUsuario: (json['iD_Usuario'] as num?)?.toInt() ?? 1,
        frecuenciaViajero: json['frecuencia_Viajero'] as String? ?? 'Normal',
        correo: json['correo'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        apellido: json['apellido'] as String? ?? '',
        telefono: json['telefono'] as String? ?? '',
        direccion: json['direccion'] as String? ?? '',
        nacionalidad: json['nacionalidad'] as String? ?? '',
        pasaporte: json['pasaporte'] as String? ?? '',
        fechaNacimiento: json['fecha_Nacimiento'] as String? ?? '',
      );
}