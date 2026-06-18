class Pasajero {
  String dni;
  String nombre;
  String apellido;
  String nacionalidad;
  DateTime fechaNacimiento;
  // solo para el titular
  String? correo;
  String? telefono;
  String? direccion;

  Pasajero({
    required this.dni,
    required this.nombre,
    required this.apellido,
    required this.nacionalidad,
    required this.fechaNacimiento,
    this.correo,
    this.telefono,
    this.direccion,
  });
}