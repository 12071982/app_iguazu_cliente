import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paquete.dart';
import '../models/destino.dart';
import '../models/cliente.dart';
import '../models/reserva.dart';
import '../models/pago.dart';

class ApiService {
  static const String baseUrl = 'https://localhost:7047/api';

  // ════════════════════════════════════════════════
  // PAQUETES
  // ════════════════════════════════════════════════
  static Future<List<Paquete>> getPaquetes() async {
    final response = await http.get(Uri.parse('$baseUrl/Paquete'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Paquete.fromJson(item)).toList();
    }
    throw Exception('Error al cargar paquetes: ${response.statusCode}');
  }

  // ════════════════════════════════════════════════
  // DESTINOS
  // ════════════════════════════════════════════════
  static Future<List<Destino>> getDestinos() async {
    final response = await http.get(Uri.parse('$baseUrl/Destino'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Destino.fromJson(item)).toList();
    }
    throw Exception('Error al cargar destinos: ${response.statusCode}');
  }

  // ════════════════════════════════════════════════
  // CLIENTE — buscar por correo
  // Replica exacta del flujo HTML:
  //   1. Verificar si existe con /Cliente/email
  //   2. Si existe, traer lista y filtrar por correo
  // ════════════════════════════════════════════════
  static Future<Cliente?> getClienteByEmail(String correo) async {
    try {
      // Paso 1: verificar existencia
      final checkRes = await http.get(
        Uri.parse(
          '$baseUrl/Cliente/email?correo=${Uri.encodeComponent(correo)}',
        ),
      );

      // 404 = no existe
      if (checkRes.statusCode == 404) return null;
      // Error inesperado
      if (!checkRes.statusCode.toString().startsWith('2')) return null;

      // Paso 2: existe → traer lista y filtrar
      final listRes = await http.get(Uri.parse('$baseUrl/Cliente'));
      if (listRes.statusCode != 200) return null;

      final List<dynamic> data = json.decode(listRes.body);
      final clientes = data.map((c) => Cliente.fromJson(c)).toList();

      try {
        return clientes.firstWhere(
          (c) => c.correo.toLowerCase() == correo.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    } catch (e) {
      // Error de red → devolver null, se intentará crear
      return null;
    }
  }

  // ════════════════════════════════════════════════
  // CLIENTE — crear nuevo
  // ✅ toJson() ya NO envía iD_Cliente cuando es null
  // ════════════════════════════════════════════════
  static Future<Cliente> crearCliente(Cliente cliente) async {
    final body = cliente.toJson(); // iD_Cliente ausente si es null

    final response = await http.post(
      Uri.parse('$baseUrl/Cliente'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Cliente.fromJson(json.decode(response.body));
    }

    // Mostrar body completo para depuración
    throw Exception('Error al crear cliente: ${response.body}');
  }

  // ════════════════════════════════════════════════
  // RESERVA — crear
  // ════════════════════════════════════════════════
  static Future<Reserva> crearReserva(Reserva reserva) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Reserva'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(reserva.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Reserva.fromJson(json.decode(response.body));
    }

    throw Exception('Error al crear reserva: ${response.body}');
  }

  static Future<Map<String, dynamic>> confirmarReserva(
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Reserva/confirmar'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final errorText =
          response.body.isNotEmpty
              ? response.body
              : 'Error ${response.statusCode}';
      throw Exception('Error al confirmar reserva: $errorText');
    }
  }

  // ════════════════════════════════════════════════
  // PAGO — crear con detalle
  // Replica exacta del pagoBody del HTML
  // ════════════════════════════════════════════════
  static Future<Pago> crearPago(Pago pago, List<dynamic> detallePago) async {
    final body = {
      'iD_Reserva': pago.idReserva,
      'fecha_Pago': pago.fechaPago,
      'metodo_Pago': pago.metodoPago,
      'monto': pago.monto,
      'numero_Transaccion': pago.numeroTransaccion,
      'detallePago': detallePago,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/Pago'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // 204 No Content o body vacío → construir Pago mínimo
      if (response.body.isEmpty || response.statusCode == 204) {
        return pago;
      }
      return Pago.fromJson(json.decode(response.body));
    }

    throw Exception('Error al registrar pago: ${response.body}');
  }
}
