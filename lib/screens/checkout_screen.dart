import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import '../models/paquete.dart';
import '../models/destino.dart';
import '../models/cliente.dart';
import '../models/reserva.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  CONSTANTES GLOBALES
// ═══════════════════════════════════════════════════════════════════
const String verificapeToken = 'vp_live_aada01fa0e4c4fa290b3e042fc612bb8';
const String verificapeApi =
    'https://corsproxy.io/?https://api.verificape.com/v2/dni';

Map<String, dynamic> dniCache = {};
Map<String, Cliente?> clienteCache = {};

const String _apiBase = 'https://iguazu.bsite.net/api';

// ═══════════════════════════════════════════════════════════════════
//  PALETA DE COLORES (ticket térmico)
// ═══════════════════════════════════════════════════════════════════
const _kGreen = Color(0xFF059669);
const _kGreenBg = Color(0xFFD1FAE5);
const _kBlue = Color(0xFF0066CC);
const _kBlueBg = Color(0xFFEFF6FF);
const _kTextDark = Color(0xFF111111);
const _kTextMid = Color(0xFF444444);
const _kTextGray = Color(0xFF666666);
const _kBorder = Color(0xFFE9ECEF);
const _kBgTicket = Colors.white;
const _kBgPage = Color(0xFFF4F6F9);
const _kWarnBg = Color(0xFFFFFBEB);
const _kWarnBorder = Color(0xFFF59E0B);
const _kWarnText = Color(0xFF7C5309);

const double _kTicketWidth = 302.0;

// ═══════════════════════════════════════════════════════════════════
//  WIDGETS DE TICKET REUTILIZABLES
// ═══════════════════════════════════════════════════════════════════
Widget _dashed() => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: LayoutBuilder(
    builder: (_, bc) {
      const double dash = 6, gap = 4, h = 1;
      int count = (bc.maxWidth / (dash + gap)).floor();
      return Row(
        children: List.generate(
          count,
          (_) => const Padding(
            padding: EdgeInsets.only(right: gap),
            child: SizedBox(
              width: dash,
              height: h,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFAAAAAA)),
              ),
            ),
          ),
        ),
      );
    },
  ),
);

Widget _row(
  String label,
  String value, {
  bool bold = false,
  Color? valueColor,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: _kTextGray)),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 10,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? _kTextDark,
            fontFamily: 'monospace',
          ),
        ),
      ),
    ],
  ),
);

Widget _seccion(String titulo, List<Widget> children) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _dashed(),
    Center(
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: _kTextMid,
          letterSpacing: 0.4,
        ),
      ),
    ),
    const SizedBox(height: 6),
    ...children,
  ],
);

Widget _pasajeroCard({
  required String numero,
  required String nombre,
  required String doc,
  required String nac,
  required bool isTitular,
}) => Container(
  margin: const EdgeInsets.only(bottom: 5),
  padding: const EdgeInsets.all(6),
  decoration: BoxDecoration(
    color: const Color(0xFFFAFAFA),
    border: Border.all(color: _kBorder),
    borderRadius: BorderRadius.circular(4),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$numero. $nombre',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isTitular ? _kBlueBg : _kGreenBg,
              border: Border.all(
                color:
                    isTitular
                        ? const Color(0xFFBCD6F5)
                        : const Color(0xFFC3EBD0),
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              isTitular ? 'TITULAR' : 'ACOMP.',
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
                color: isTitular ? _kBlue : _kGreen,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 3),
      Text(
        'Doc: $doc  |  Nac: $nac',
        style: const TextStyle(
          fontSize: 8.5,
          color: _kTextGray,
          fontFamily: 'monospace',
        ),
      ),
    ],
  ),
);

// ═══════════════════════════════════════════════════════════════════
//  CHECKOUT SCREEN (con integración Yape)
// ═══════════════════════════════════════════════════════════════════
class CheckoutScreen extends StatefulWidget {
  final Paquete paquete;
  final Destino destino;

  const CheckoutScreen({
    super.key,
    required this.paquete,
    required this.destino,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int numeroPasajeros = 1;
  final List<PasajeroFormController> pasajerosControllers = [];
  bool isPaying = false;
  String? paymentError;

  @override
  void initState() {
    super.initState();
    _agregarPasajero(0);
  }

  void _agregarPasajero(int index) {
    final isTitular = index == 0;
    pasajerosControllers.add(
      PasajeroFormController(
        index: index,
        isTitular: isTitular,
        onDniVerified: (idx, persona) => _rellenarPasajero(idx, persona),
        onVerifying: (idx, loading) => setState(() {}),
        onDniClientLookup: isTitular ? _getClienteByDni : null,
      ),
    );
  }

  void _removerPasajero(int index) {
    pasajerosControllers.removeAt(index);
    for (int i = 0; i < pasajerosControllers.length; i++) {
      pasajerosControllers[i].index = i;
      pasajerosControllers[i].isTitular = i == 0;
    }
    setState(() {});
  }

  void _rellenarPasajero(int idx, Map<String, dynamic> persona) {
    final c = pasajerosControllers[idx];
    c.nombreController.text = persona['names'] ?? '';
    final apPat = persona['paternalSurname'] ?? '';
    final apMat = persona['maternalSurname'] ?? '';
    c.apellidoController.text = '$apPat $apMat'.trim();
    c.nacionalidadController.text = 'Peruana';
    final fechaRaw = persona['birthDate'] as String? ?? '';
    if (fechaRaw.contains('/')) {
      final parts = fechaRaw.split('/');
      if (parts.length == 3) {
        c.fechaNacController.text =
            '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
    }
    setState(() {});
  }

  void _cambiarPasajeros(int delta) {
    setState(() {
      int nuevo = (numeroPasajeros + delta).clamp(1, 20);
      if (nuevo > numeroPasajeros) {
        for (int i = numeroPasajeros; i < nuevo; i++) {
          _agregarPasajero(i);
        }
      } else {
        for (int i = numeroPasajeros - 1; i >= nuevo; i--) {
          _removerPasajero(i);
        }
      }
      numeroPasajeros = nuevo;
    });
  }

  double get precioTotal => widget.paquete.precioBase * numeroPasajeros;
  double get subtotal => precioTotal / 1.18;
  double get igv => precioTotal - subtotal;

  bool _validarPasajeros() {
    for (var ctrl in pasajerosControllers) {
      if (ctrl.dniController.text.trim().isEmpty ||
          ctrl.nombreController.text.trim().isEmpty ||
          ctrl.apellidoController.text.trim().isEmpty ||
          ctrl.nacionalidadController.text.trim().isEmpty ||
          ctrl.fechaNacController.text.trim().isEmpty) {
        _snack('Complete todos los campos obligatorios de cada pasajero');
        return false;
      }

      final fechaStr = ctrl.fechaNacController.text.trim();
      if (fechaStr.isNotEmpty) {
        final nacimiento = DateTime.tryParse(fechaStr);
        if (nacimiento != null) {
          final hoy = DateTime.now();
          int edad = hoy.year - nacimiento.year;
          final mes = hoy.month - nacimiento.month;
          if (mes < 0 || (mes == 0 && hoy.day < nacimiento.day)) edad--;

          if (ctrl.isTitular && edad < 18) {
            _snack('El pasajero titular debe ser mayor de 18 años');
            return false;
          }
          if (!ctrl.isTitular && edad < 3) {
            _snack('El pasajero ${ctrl.index + 1} debe tener al menos 3 años');
            return false;
          }
        }
      }

      if (ctrl.isTitular) {
        if (ctrl.correoController.text.trim().isEmpty ||
            ctrl.telefonoController.text.trim().isEmpty ||
            ctrl.direccionController.text.trim().isEmpty) {
          _snack('Complete correo, teléfono y dirección del titular');
          return false;
        }
      }
    }
    return true;
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
  );

  Future<void> _procesarPago() async {
    if (!_validarPasajeros()) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => PaymentModal(
            precioTotal: precioTotal,
            onConfirm: (paymentData) async {
              Navigator.pop(ctx);
              if (paymentData['method'] == 'tarjeta') {
                await _realizarPagoTarjeta(paymentData);
              } else if (paymentData['method'] == 'yape') {
                await _realizarPagoYape(paymentData);
              }
            },
          ),
    );
  }

  Future<Cliente?> _getClienteByDni(String dni) async {
    try {
      final response = await http.get(Uri.parse('$_apiBase/Cliente'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        for (final item in jsonList) {
          final cliente = Cliente.fromJson(item);
          if (cliente.pasaporte == dni) {
            return cliente;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _realizarPagoTarjeta(Map<String, dynamic> cardData) async {
    setState(() => isPaying = true);
    try {
      final titular = pasajerosControllers[0];

      Cliente cliente;
      final clienteExistente = await _getClienteByDni(
        titular.dniController.text.trim(),
      );
      if (clienteExistente != null) {
        cliente = clienteExistente;
      } else {
        cliente = await ApiService.crearCliente(
          Cliente(
            idUsuario: 1,
            frecuenciaViajero: 'Normal',
            correo: titular.correoController.text,
            nombre: titular.nombreController.text,
            apellido: titular.apellidoController.text,
            telefono: titular.telefonoController.text,
            direccion: titular.direccionController.text,
            nacionalidad: titular.nacionalidadController.text,
            pasaporte: titular.dniController.text,
            fechaNacimiento: _formatFechaApi(titular.fechaNacController.text),
          ),
        );
      }
      if (cliente.idCliente == null) {
        throw Exception('ID de cliente no disponible');
      }

      final fechaFormateada =
          DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()).toLowerCase();
      final numTransaccion = 'APP-${DateTime.now().millisecondsSinceEpoch}';

      final acompanantes = <Map<String, dynamic>>[];
      for (int i = 1; i < pasajerosControllers.length; i++) {
        final p = pasajerosControllers[i];
        acompanantes.add({
          'ID_Cliente': 0,
          'Nombre': p.nombreController.text,
          'Apellido': p.apellidoController.text,
          'Telefono': '',
          'Correo': '',
          'Pasaporte': p.dniController.text,
          'Nacionalidad': p.nacionalidadController.text,
        });
      }

      final payload = {
        'ID_Cliente': cliente.idCliente,
        'ID_Paquete': widget.paquete.idPaquete,
        'Fecha_Reserva': fechaFormateada,
        'Numero_Personas': numeroPasajeros,
        'Precio_Total': precioTotal,
        'Observaciones': _buildObservaciones(),
        'Metodo_Pago': 'Tarjeta (Simulado)',
        'Monto': precioTotal,
        'Fecha_Pago': fechaFormateada,
        'Numero_Transaccion': numTransaccion,
        'Moneda': widget.destino.moneda,
        'DestinoNombre': '${widget.destino.ciudad}, ${widget.destino.pais}',
        'Cliente': {
          'ID_Cliente': cliente.idCliente,
          'Nombre': cliente.nombre,
          'Apellido': cliente.apellido,
          'Telefono': cliente.telefono,
          'Correo': cliente.correo,
          'Pasaporte': cliente.pasaporte,
          'Nacionalidad': cliente.nacionalidad,
        },
        'Acompanantes': acompanantes,
        'Paquete': {
          'ID_Paquete': widget.paquete.idPaquete,
          'Nombre': widget.paquete.nombre,
          'Descripcion': widget.paquete.descripcion,
          'Fecha_Inicio': widget.paquete.fechaInicio,
          'Fecha_Fin': widget.paquete.fechaFin,
          'Precio_Base': widget.paquete.precioBase,
          'ID_Destino': widget.paquete.idDestino,
          'Inclusiones': widget.paquete.inclusiones,
          'Exclusiones': widget.paquete.exclusiones,
        },
      };

      final response = await ApiService.confirmarReserva(payload);
      if (response['success'] != true) {
        throw Exception(response['mensaje'] ?? 'Error al confirmar reserva');
      }

      if (mounted) {
        if (response['correoEnviado'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ El comprobante ha sido enviado a tu correo electrónico.',
              ),
              backgroundColor: _kGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Reserva creada, pero no se pudo enviar el correo (el cliente no tiene email o hubo un error).',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      final reservaCreada = Reserva(
        idReserva: response['id_Reserva'],
        idCliente: cliente.idCliente!,
        idPaquete: widget.paquete.idPaquete,
        fechaReserva: fechaFormateada,
        numeroPersonas: numeroPasajeros,
        precioTotal: precioTotal,
        estatus: 'Pagado',
        observaciones: _buildObservaciones(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => BoletaScreen(
                  paquete: widget.paquete,
                  destino: widget.destino,
                  reserva: reservaCreada,
                  numeroTransaccion: numTransaccion,
                  titular: titular,
                  cliente: cliente,
                  pasajeros: pasajerosControllers.sublist(1),
                  total: precioTotal,
                  fechaPago: DateTime.now(),
                ),
          ),
        );
      }
    } catch (e) {
      setState(() => paymentError = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isPaying = false);
    }
  }

  Future<void> _realizarPagoYape(Map<String, dynamic> yapeData) async {
    setState(() => isPaying = true);
    try {
      final titular = pasajerosControllers[0];

      Cliente cliente;
      final clienteExistente = await _getClienteByDni(
        titular.dniController.text.trim(),
      );
      if (clienteExistente != null) {
        cliente = clienteExistente;
      } else {
        cliente = await ApiService.crearCliente(
          Cliente(
            idUsuario: 1,
            frecuenciaViajero: 'Normal',
            correo: titular.correoController.text,
            nombre: titular.nombreController.text,
            apellido: titular.apellidoController.text,
            telefono: titular.telefonoController.text,
            direccion: titular.direccionController.text,
            nacionalidad: titular.nacionalidadController.text,
            pasaporte: titular.dniController.text,
            fechaNacimiento: _formatFechaApi(titular.fechaNacController.text),
          ),
        );
      }
      if (cliente.idCliente == null) {
        throw Exception('ID de cliente no disponible');
      }

      final fechaFormateada =
          DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()).toLowerCase();
      final numTransaccion = 'YAPE-${DateTime.now().millisecondsSinceEpoch}';

      final acompanantes = <Map<String, dynamic>>[];
      for (int i = 1; i < pasajerosControllers.length; i++) {
        final p = pasajerosControllers[i];
        acompanantes.add({
          'ID_Cliente': 0,
          'Nombre': p.nombreController.text,
          'Apellido': p.apellidoController.text,
          'Telefono': '',
          'Correo': '',
          'Pasaporte': p.dniController.text,
          'Nacionalidad': p.nacionalidadController.text,
        });
      }

      final payload = {
        'ID_Cliente': cliente.idCliente,
        'ID_Paquete': widget.paquete.idPaquete,
        'Fecha_Reserva': fechaFormateada,
        'Numero_Personas': numeroPasajeros,
        'Precio_Total': precioTotal,
        'Observaciones': _buildObservaciones(),
        'Metodo_Pago': 'Yape',
        'Monto': precioTotal,
        'Fecha_Pago': fechaFormateada,
        'Numero_Transaccion': numTransaccion,
        'Moneda': widget.destino.moneda,
        'DestinoNombre': '${widget.destino.ciudad}, ${widget.destino.pais}',
        'Cliente': {
          'ID_Cliente': cliente.idCliente,
          'Nombre': cliente.nombre,
          'Apellido': cliente.apellido,
          'Telefono': cliente.telefono,
          'Correo': cliente.correo,
          'Pasaporte': cliente.pasaporte,
          'Nacionalidad': cliente.nacionalidad,
        },
        'Acompanantes': acompanantes,
        'Paquete': {
          'ID_Paquete': widget.paquete.idPaquete,
          'Nombre': widget.paquete.nombre,
          'Descripcion': widget.paquete.descripcion,
          'Fecha_Inicio': widget.paquete.fechaInicio,
          'Fecha_Fin': widget.paquete.fechaFin,
          'Precio_Base': widget.paquete.precioBase,
          'ID_Destino': widget.paquete.idDestino,
          'Inclusiones': widget.paquete.inclusiones,
          'Exclusiones': widget.paquete.exclusiones,
        },
      };

      final response = await ApiService.confirmarReserva(payload);
      if (response['success'] != true) {
        throw Exception(response['mensaje'] ?? 'Error al confirmar reserva');
      }

      if (mounted) {
        if (response['correoEnviado'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ Pago con Yape exitoso. Comprobante enviado a tu correo.',
              ),
              backgroundColor: _kGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Reserva creada con Yape, pero no se pudo enviar el correo.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      final reservaCreada = Reserva(
        idReserva: response['id_Reserva'],
        idCliente: cliente.idCliente!,
        idPaquete: widget.paquete.idPaquete,
        fechaReserva: fechaFormateada,
        numeroPersonas: numeroPasajeros,
        precioTotal: precioTotal,
        estatus: 'Pagado',
        observaciones: _buildObservaciones(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => BoletaScreen(
                  paquete: widget.paquete,
                  destino: widget.destino,
                  reserva: reservaCreada,
                  numeroTransaccion: numTransaccion,
                  titular: titular,
                  cliente: cliente,
                  pasajeros: pasajerosControllers.sublist(1),
                  total: precioTotal,
                  fechaPago: DateTime.now(),
                ),
          ),
        );
      }
    } catch (e) {
      setState(() => paymentError = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isPaying = false);
    }
  }

  String _buildObservaciones() {
    final buf = StringBuffer();
    for (int i = 1; i < pasajerosControllers.length; i++) {
      final p = pasajerosControllers[i];
      buf.write(
        'Pax ${i + 1}: ${p.nombreController.text} ${p.apellidoController.text}'
        ' - Doc: ${p.dniController.text}'
        ' - Nac: ${p.nacionalidadController.text} | ',
      );
    }
    final result = buf.toString().trim();
    return result.isEmpty ? 'Sin acompañantes' : result;
  }

  String _formatFechaApi(String isoDate) {
    if (isoDate.isEmpty) return '';
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPackageCard(),
                const SizedBox(height: 16),
                _buildPasajerosSelector(),
                const SizedBox(height: 16),
                ...pasajerosControllers.map((c) => c.buildForm(context)),
                const SizedBox(height: 8),
                _buildResumen(),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock_outline),
                  label: const Text(
                    'Pagar ahora',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isPaying ? null : _procesarPago,
                ),
                if (paymentError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      paymentError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          if (isPaying)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: _kGreen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPackageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                widget.paquete.imagen ?? 'assets/images/viaje.jpeg',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: _kGreenBg,
                      child: const Icon(Icons.image, color: _kGreen),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.paquete.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${widget.destino.ciudad}, ${widget.destino.pais}',
                    style: const TextStyle(color: _kTextGray, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Duración: ${widget.paquete.duracion}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'Por persona: ',
                        style: TextStyle(fontSize: 12),
                      ),
                      Flexible(
                        child: Text(
                          '${widget.destino.moneda} ${widget.paquete.precioBase.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _kGreen,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasajerosSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Número de pasajeros',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _numBtn(Icons.remove, () => _cambiarPasajeros(-1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$numeroPasajeros',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _numBtn(Icons.add, () => _cambiarPasajeros(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numBtn(IconData icon, VoidCallback onPressed) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: _kGreen),
    ),
  );

  Widget _buildResumen() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _resumenRow(
              'Subtotal (sin IGV)',
              '${widget.destino.moneda} ${subtotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 4),
            _resumenRow(
              'IGV (18%)',
              '${widget.destino.moneda} ${igv.toStringAsFixed(2)}',
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '${widget.destino.moneda} ${precioTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: _kGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: _kTextGray)),
      Text(value),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
//  CONTROLADOR DE FORMULARIO POR PASAJERO
// ═══════════════════════════════════════════════════════════════════
class PasajeroFormController {
  int index;
  bool isTitular;
  final TextEditingController dniController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();
  final TextEditingController nacionalidadController = TextEditingController();
  final TextEditingController fechaNacController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final Function(int, Map<String, dynamic>) onDniVerified;
  final Function(int, bool) onVerifying;
  final Future<Cliente?> Function(String dni)? onDniClientLookup;
  bool _isVerifying = false;
  String? _dniMsg;

  PasajeroFormController({
    required this.index,
    required this.isTitular,
    required this.onDniVerified,
    required this.onVerifying,
    this.onDniClientLookup,
  });

  bool get isVerifying => _isVerifying;

  void _rellenarDesdeCliente(Cliente cliente) {
    correoController.text = cliente.correo;
    telefonoController.text = cliente.telefono;
    direccionController.text = cliente.direccion;
    nacionalidadController.text = cliente.nacionalidad;
    final fp = cliente.fechaNacimiento.split('/');
    if (fp.length == 3) {
      fechaNacController.text =
          '${fp[2]}-${fp[1].padLeft(2, '0')}-${fp[0].padLeft(2, '0')}';
    }
  }

  Future<void> verificarDni() async {
    final dni = dniController.text.trim();
    if (dni.length < 8) return;

    _isVerifying = true;
    onVerifying(index, true);

    if (dniCache.containsKey(dni)) {
      final cached = dniCache[dni];
      _isVerifying = false;
      onVerifying(index, false);
      if (cached['success'] == true) {
        onDniVerified(index, cached['data']);
        if (isTitular && onDniClientLookup != null) {
          final cliente = await onDniClientLookup!(dni);
          if (cliente != null) _rellenarDesdeCliente(cliente);
        }
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$verificapeApi/$dni'),
        headers: {'Authorization': 'Bearer $verificapeToken'},
      );
      _isVerifying = false;
      onVerifying(index, false);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          dniCache[dni] = {'success': true, 'data': data['data']};
          onDniVerified(index, data['data'] as Map<String, dynamic>);
          if (isTitular && onDniClientLookup != null) {
            final cliente = await onDniClientLookup!(dni);
            if (cliente != null) _rellenarDesdeCliente(cliente);
          }
        } else {
          dniCache[dni] = {'success': false};
        }
      } else {
        dniCache[dni] = {'success': false};
      }
    } catch (_) {
      _isVerifying = false;
      onVerifying(index, false);
      dniCache[dni] = {'success': false};
    }
  }

  Widget buildForm(BuildContext context) {
    final minEdad = isTitular ? 18 : 3;
    final edadLabel = isTitular ? '(≥ 18 años)' : '(≥ 3 años)';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: _kGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTitular ? 'Pasajero titular' : 'Pasajero ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isTitular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _kGreenBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Titular',
                      style: TextStyle(
                        color: _kGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: dniController,
                    decoration: _dec('DNI / Pasaporte', Icons.badge_outlined),
                    onEditingComplete:
                        verificarDni, // sigue buscando al presionar "siguiente"
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child:
                      _isVerifying
                          // ── Buscando: spinner en lugar del botón ──
                          ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: _kGreen,
                              ),
                            ),
                          )
                          // ── Botón buscar ──
                          : ElevatedButton.icon(
                            icon: const Icon(Icons.search, size: 16),
                            label: const Text(
                              'Buscar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              verificarDni();
                            },
                          ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: nombreController,
                    decoration: _dec('Nombre', Icons.person_outline),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: apellidoController,
                    decoration: _dec('Apellido', Icons.person_outline),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: nacionalidadController,
                    decoration: _dec('Nacionalidad', Icons.flag_outlined),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatefulBuilder(
                    builder: (ctx, setS) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: fechaNacController,
                            decoration: _dec(
                              'Fecha nac. $edadLabel',
                              Icons.cake_outlined,
                            ),
                            readOnly: true,
                            onTap: () async {
                              final hoy = DateTime.now();
                              final max =
                                  isTitular
                                      ? DateTime(
                                        hoy.year - 18,
                                        hoy.month,
                                        hoy.day,
                                      )
                                      : DateTime(
                                        hoy.year - 3,
                                        hoy.month,
                                        hoy.day,
                                      );
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: max,
                                firstDate: DateTime(1900),
                                lastDate: max,
                              );
                              if (date != null) {
                                fechaNacController.text =
                                    date.toIso8601String().split('T').first;
                                setS(() {});
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            if (isTitular) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: correoController,
                decoration: _dec('Correo electrónico', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: telefonoController,
                      decoration: _dec('Teléfono', Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: direccionController,
                decoration: _dec('Dirección', Icons.location_on_outlined),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 18, color: _kGreen),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _kGreen, width: 1.8),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    labelStyle: const TextStyle(fontSize: 13),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  MODAL DE PAGO (TARJETA + YAPE) – CENTRADO VERTICAL
// ═══════════════════════════════════════════════════════════════════
class PaymentModal extends StatefulWidget {
  final double precioTotal;
  final Future<void> Function(Map<String, dynamic>) onConfirm;

  const PaymentModal({
    super.key,
    required this.precioTotal,
    required this.onConfirm,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Tarjeta ──────────────────────────────────────────
  final _cardFormKey = GlobalKey<FormState>();
  final _numCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  String _brand = '';
  bool _cardLoading = false;

  // ── Yape ─────────────────────────────────────────────
  final _yapeFormKey = GlobalKey<FormState>();
  final _celularCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpNodes = List.generate(6, (_) => FocusNode());
  bool _yapeLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _numCtrl.dispose();
    _expCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    _docCtrl.dispose();
    _celularCtrl.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final n in _otpNodes) {
      n.dispose();
    }
    super.dispose();
  }

  // ─── Tarjeta: detección de marca y validación ──────────
  void _detectBrand(String num) {
    final clean = num.replaceAll(' ', '');
    setState(() {
      if (clean.startsWith('4')) {
        _brand = 'Visa';
      } else if (clean.startsWith('5'))
        _brand = 'Mastercard';
      else if (clean.startsWith('3'))
        _brand = 'American Express';
      else
        _brand = '';
    });
  }

  bool _luhn(String num) {
    int sum = 0;
    bool alt = false;
    for (int i = num.length - 1; i >= 0; i--) {
      int d = int.parse(num[i]);
      if (alt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  Color _brandColor() {
    switch (_brand) {
      case 'Visa':
        return const Color(0xFF1A1F71);
      case 'Mastercard':
        return const Color(0xFFEB001B);
      case 'American Express':
        return const Color(0xFF007BC1);
      default:
        return Colors.grey;
    }
  }

  // ─── Yape: OTP ───────────────────────────────────────
  void _onOtpChanged(int idx, String val) {
    if (val.length == 1 && idx < 5) {
      _otpNodes[idx + 1].requestFocus();
    }
  }

  void _onOtpPaste(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '').substring(0, 6);
    if (digits.isEmpty) return;
    for (int i = 0; i < 6; i++) {
      _otpCtrls[i].text = i < digits.length ? digits[i] : '';
    }
    final lastIdx = (digits.length - 1).clamp(0, 5);
    _otpNodes[lastIdx].requestFocus();
  }

  // ─── Construcción de la UI ───────────────────────────
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Método de pago',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            'Selecciona cómo deseas pagar',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: _tabController,
            builder: (context, _) {
              final index = _tabController.index;
              return TabBar(
                controller: _tabController,
                indicatorColor:
                    index == 1
                        ? const Color(0xFF742384)
                        : const Color(0xFF1E88E5),
                labelColor: Colors.transparent,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 20,
                          color:
                              index == 0
                                  ? const Color(0xFF1E88E5)
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tarjeta',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                index == 0
                                    ? const Color(0xFF1E88E5)
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: 20,
                          color:
                              index == 1
                                  ? const Color(0xFF742384)
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Yape',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                index == 1
                                    ? const Color(0xFF742384)
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 550,
        child: TabBarView(
          controller: _tabController,
          children: [_buildTarjetaTab(), _buildYapeTab()],
        ),
      ),
    );
  }

  // ─── PESTAÑA TARJETA (centrada verticalmente) ──────────
  Widget _buildTarjetaTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Form(
                  key: _cardFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Detección de marca (sin cambios)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _brandIcon(Icons.credit_card, 'Visa'),
                            const SizedBox(width: 8),
                            _brandIcon(Icons.credit_card, 'Mastercard'),
                            const SizedBox(width: 8),
                            _brandIcon(Icons.credit_card, 'American Express'),
                            const Spacer(),
                            if (_brand.isNotEmpty)
                              Text(
                                _brand,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _brandColor(),
                                  fontSize: 13,
                                ),
                              ),
                            if (_brand.isEmpty)
                              Text(
                                'Detección automática',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Campos (idénticos a los actuales)
                      TextFormField(
                        controller: _numCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Número de tarjeta',
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          String c = val.replaceAll(' ', '');
                          if (c.length > 16) c = c.substring(0, 16);
                          String f = '';
                          for (int i = 0; i < c.length; i++) {
                            if (i > 0 && i % 4 == 0) f += ' ';
                            f += c[i];
                          }
                          _numCtrl.value = TextEditingValue(
                            text: f,
                            selection: TextSelection.collapsed(
                              offset: f.length,
                            ),
                          );
                          _detectBrand(c);
                        },
                        validator: (v) {
                          final c = v!.replaceAll(' ', '');
                          if (c.length < 13) return 'Número incompleto';
                          if (!_luhn(c)) return 'Número de tarjeta inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expCtrl,
                              decoration: const InputDecoration(
                                labelText: 'MM/AA',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                String n = v.replaceAll(RegExp(r'[^0-9]'), '');
                                if (n.length > 4) n = n.substring(0, 4);
                                String f =
                                    n.length >= 3
                                        ? '${n.substring(0, 2)}/${n.substring(2)}'
                                        : n;
                                if (_expCtrl.text != f) {
                                  _expCtrl.value = TextEditingValue(
                                    text: f,
                                    selection: TextSelection.collapsed(
                                      offset: f.length,
                                    ),
                                  );
                                }
                              },
                              validator: (v) {
                                if (v == null || v.length != 5) {
                                  return 'Formato MM/AA';
                                }
                                final p = v.split('/');
                                final mm = int.tryParse(p[0]);
                                final yy = int.tryParse(p[1]);
                                if (mm == null ||
                                    yy == null ||
                                    mm < 1 ||
                                    mm > 12) {
                                  return 'Mes inválido';
                                }
                                final exp = DateTime(2000 + yy, mm);
                                final now = DateTime.now();
                                if (exp.isBefore(
                                  DateTime(now.year, now.month),
                                )) {
                                  return 'Tarjeta vencida';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _cvvCtrl,
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                              ),
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              validator:
                                  (v) => v!.length < 3 ? 'CVV inválido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre en tarjeta',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator:
                            (v) => v!.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _docCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Documento (DNI/CE)',
                        ),
                        keyboardType: TextInputType.number,
                        validator:
                            (v) => v!.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total a pagar',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              'S/ ${widget.precioTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF059669),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed:
                            _cardLoading
                                ? null
                                : () async {
                                  if (!_cardFormKey.currentState!.validate()) {
                                    return;
                                  }
                                  setState(() => _cardLoading = true);
                                  await widget.onConfirm({
                                    'method': 'tarjeta',
                                    'number': _numCtrl.text.replaceAll(' ', ''),
                                    'expiry': _expCtrl.text,
                                    'cvv': _cvvCtrl.text,
                                    'name': _nameCtrl.text,
                                    'doc': _docCtrl.text,
                                  });
                                  if (mounted) {
                                    setState(() => _cardLoading = false);
                                  }
                                },
                        child:
                            _cardLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_outline, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Confirmar pago',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── PESTAÑA YAPE (centrada verticalmente) ─────────────
  Widget _buildYapeTab() {
    const yapePrimary = Color(0xFF742384);
    const yapeBg = Color(0xFFF9FAFB);
    const yapeBorder = Color(0xFFE5E7EB);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Form(
                key: _yapeFormKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: yapeBorder),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Yape
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQvAAvbqUFoCgtMpPmzqDUBETvkc5mYyLw1fw&s',
                          width: 220,
                          height: 70,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (_, __, ___) => const Text(
                                'yape',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: yapePrimary,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paga de forma rápida y segura',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),

                      // Celular Yape
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Ingresa tu celular Yape ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const TextSpan(
                                text: '*',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _celularCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 14, right: 8),
                            child: Text(
                              '+51',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          hintText: '000 000 000',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: yapeBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: yapePrimary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.replaceAll(' ', '').length != 9) {
                            return 'Ingresa un número de 9 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Código OTP
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Código de aprobación ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const TextSpan(
                                text: '*',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (i) {
                          return SizedBox(
                            width: 48,
                            height: 56,
                            child: TextFormField(
                              controller: _otpCtrls[i],
                              focusNode: _otpNodes[i],
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: yapeBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: yapePrimary,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                              onChanged: (val) => _onOtpChanged(i, val),
                              onTap: () {
                                if (_otpNodes[i].hasFocus) _otpCtrls[i].clear();
                              },
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: yapePrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Encuéntralo en el menú de Yape.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: yapeBg,
                          border: Border.all(color: yapeBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ambiente de pruebas — cualquier código de 6 dígitos es válido',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Total y botón
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: yapeBg,
                          border: Border.all(color: yapeBorder),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total a pagar',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'S/ ${widget.precioTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: yapePrimary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: yapePrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed:
                              _yapeLoading
                                  ? null
                                  : () async {
                                    if (!_yapeFormKey.currentState!
                                        .validate()) {
                                      return;
                                    }
                                    final otp =
                                        _otpCtrls.map((c) => c.text).join();
                                    if (otp.length != 6) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Ingresa los 6 dígitos del código.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() => _yapeLoading = true);
                                    await widget.onConfirm({
                                      'method': 'yape',
                                      'celular': _celularCtrl.text,
                                      'codigo': otp,
                                    });
                                    if (mounted) {
                                      setState(() => _yapeLoading = false);
                                    }
                                  },
                          child:
                              _yapeLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text('Yapear'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _brandIcon(IconData icon, String brand) => Icon(
    icon,
    size: 26,
    color: _brand == brand ? _brandColor() : Colors.grey.shade300,
  );
}

// ═══════════════════════════════════════════════════════════════════
//  BOLETA SCREEN — Ticket térmico 80mm (sin cambios)
// ═══════════════════════════════════════════════════════════════════
class BoletaScreen extends StatelessWidget {
  final Paquete paquete;
  final Destino destino;
  final Reserva reserva;
  final String numeroTransaccion;
  final PasajeroFormController titular;
  final Cliente cliente;
  final List<PasajeroFormController> pasajeros;
  final double total;
  final DateTime fechaPago;

  const BoletaScreen({
    super.key,
    required this.paquete,
    required this.destino,
    required this.reserva,
    required this.numeroTransaccion,
    required this.titular,
    required this.cliente,
    required this.pasajeros,
    required this.total,
    required this.fechaPago,
  });

  String get _nroBoleta {
    final id = reserva.idReserva;
    if (id == null) return 'B001-0000000';
    return 'B001-${id.toString().padLeft(7, '0')}';
  }

  String get _moneda => destino.moneda;
  double get _subtotal => total / 1.18;
  double get _igv => total - _subtotal;
  String _fmt(double v) => '$_moneda ${v.toStringAsFixed(2)}';

  Future<void> _generarPDF(BuildContext context) async {
    try {
      final pdf = pw.Document();
      final fechaStr = DateFormat('dd/MM/yyyy HH:mm').format(fechaPago);

      pw.Widget pdash() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          children: List.generate(
            40,
            (_) => pw.Expanded(
              child: pw.Container(
                height: 0.5,
                margin: const pw.EdgeInsets.symmetric(horizontal: 1.5),
                color: const PdfColor.fromInt(0xFFAAAAAA),
              ),
            ),
          ),
        ),
      );

      pw.Widget prow(
        String label,
        String value, {
        bool bold = false,
        PdfColor? color,
      }) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColor.fromInt(0xFF666666),
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color ?? PdfColors.black,
              ),
            ),
          ],
        ),
      );

      pw.Widget pseccion(String titulo, List<pw.Widget> children) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pdash(),
          pw.Center(
            child: pw.Text(
              titulo,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          ...children,
        ],
      );

      pw.Widget ppax(
        String num,
        String nombre,
        String doc,
        String nac,
        bool titular,
      ) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 4),
        padding: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE9ECEF)),
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    '$num. $nombre',
                    maxLines: 1,
                    softWrap: false,
                    overflow: pw.TextOverflow.clip,
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Text(
                  titular ? 'TITULAR' : 'ACOMP.',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color:
                        titular
                            ? const PdfColor.fromInt(0xFF0066CC)
                            : const PdfColor.fromInt(0xFF059669),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Doc: $doc  |  Nac: $nac',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            80 * PdfPageFormat.mm,
            double.infinity,
            marginAll: 7 * PdfPageFormat.mm,
          ),
          build:
              (ctx) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'TOUR EXPRESS IGUAZU E.I.R.L',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Agencia de Viajes y Turismo',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Huancayo, Perú',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Tel: 930 164 767',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'RUC: 20605995480',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: const PdfColor.fromInt(0xFFE9ECEF),
                      ),
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'BOLETA ELECTRÓNICA',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'NRO OPERACIÓN: $_nroBoleta',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          fechaStr,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),

                  pseccion('INFORMACIÓN DE LA RESERVA', [
                    prow(
                      'Cliente:',
                      '${cliente.nombre} ${cliente.apellido}',
                      bold: true,
                    ),
                    prow('Teléfono:', cliente.telefono),
                    prow('Email:', cliente.correo),
                    prow(
                      'Total personas:',
                      '${pasajeros.length + 1}',
                      bold: true,
                    ),
                  ]),

                  pseccion('PASAJEROS EN LA RESERVA', [
                    ppax(
                      '1',
                      '${cliente.nombre} ${cliente.apellido}',
                      cliente.pasaporte,
                      cliente.nacionalidad,
                      true,
                    ),
                    ...pasajeros.asMap().entries.map(
                      (e) => ppax(
                        '${e.key + 2}',
                        '${e.value.nombreController.text} ${e.value.apellidoController.text}',
                        e.value.dniController.text,
                        e.value.nacionalidadController.text,
                        false,
                      ),
                    ),
                  ]),

                  pseccion('DETALLES DEL PAQUETE', [
                    pw.Text(
                      paquete.nombre,
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    prow('Duración:', paquete.duracion),
                    prow('Precio base:', _fmt(paquete.precioBase)),
                  ]),

                  pseccion('RESUMEN DE VENTA', [
                    prow(
                      'Multi-Pasajero:',
                      '${pasajeros.length + 1} × ${_fmt(paquete.precioBase)}',
                    ),
                    pdash(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL IMPORTE:',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          _fmt(total),
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    pdash(),
                    prow('Op. gravadas:', _fmt(_subtotal)),
                    prow('IGV (18%):', _fmt(_igv)),
                    pdash(),
                    prow('Método:', 'Tarjeta (Prueba)'),
                    prow('N° Transacción:', numeroTransaccion),
                  ]),

                  pdash(),
                  pw.Center(
                    child: pw.Text(
                      '¡Gracias por confiar en IGUAZÚ Tours Express!',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Center(
                    child: pw.Text(
                      'Emitida el: $fechaStr',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Text(
                      'Toda cancelación debe comunicarse a la agencia dentro de '
                      'las 24 horas posteriores a la reserva. Se aplicará una '
                      'penalidad del 10% sobre el monto total pagado.',
                      style: const pw.TextStyle(fontSize: 7.5),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final a =
            html.AnchorElement(href: url)
              ..setAttribute(
                'download',
                'Boleta_${reserva.idReserva ?? 0}_IGUAZU.pdf',
              )
              ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/Boleta_${reserva.idReserva ?? 0}_IGUAZU.pdf',
        );
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Boleta IGUAZÚ Tours Express',
          text: 'Comprobante N° $_nroBoleta — ${paquete.nombre}',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comprobante generado correctamente'),
            backgroundColor: _kGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _compartirTexto() {
    final buf =
        StringBuffer()
          ..writeln('IGUAZÚ TOURS EXPRESS — Huancayo, Perú — Tel: 930 164 767')
          ..writeln('BOLETA ELECTRÓNICA  N° $_nroBoleta')
          ..writeln(DateFormat('dd/MM/yyyy HH:mm').format(fechaPago))
          ..writeln('─' * 38)
          ..writeln(
            'CLIENTE: ${cliente.nombre} ${cliente.apellido}  Doc: ${cliente.pasaporte}',
          )
          ..writeln('Email: ${cliente.correo}')
          ..writeln('─' * 38)
          ..writeln('PAQUETE: ${paquete.nombre}')
          ..writeln('Precio unit.: ${_fmt(paquete.precioBase)}')
          ..writeln('─' * 38)
          ..writeln('PASAJEROS:')
          ..writeln(
            '1. ${titular.nombreController.text} ${titular.apellidoController.text}  [TITULAR]',
          );
    for (int i = 0; i < pasajeros.length; i++) {
      final p = pasajeros[i];
      buf.writeln(
        '${i + 2}. ${p.nombreController.text} ${p.apellidoController.text}  ${p.dniController.text}',
      );
    }
    buf
      ..writeln('─' * 38)
      ..writeln('Op. gravadas : ${_fmt(_subtotal)}')
      ..writeln('IGV 18%      : ${_fmt(_igv)}')
      ..writeln('TOTAL        : ${_fmt(total)}')
      ..writeln('Transacción  : $numeroTransaccion')
      ..writeln('✓ PAGADO')
      ..writeln('─' * 38)
      ..writeln(
        '⚠ Cancelaciones dentro de 24 h. Penalidad 10% sobre el total.',
      );

    Share.share(
      buf.toString(),
      subject: 'Boleta IGUAZÚ Tours Express — $_nroBoleta',
    );
  }

  @override
  Widget build(BuildContext context) {
    final fechaStr = DateFormat('dd/MM/yyyy').format(fechaPago);
    final horaStr = DateFormat('HH:mm').format(fechaPago);

    return Scaffold(
      backgroundColor: _kBgPage,
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '¡Pago exitoso!',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Descargar PDF',
            onPressed: () => _generarPDF(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _kGreenBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kGreen.withValues(alpha: 0.35)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle_rounded, color: _kGreen, size: 38),
                  SizedBox(height: 6),
                  Text(
                    'Reserva confirmada',
                    style: TextStyle(
                      color: _kGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Guarda o imprime tu comprobante',
                    style: TextStyle(color: Color(0xFF065F46), fontSize: 12),
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                width: _kTicketWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _kBgTicket,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 22,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'TOUR EXPRESS IGUAZU E.I.R.L',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Agencia de Viajes y Turismo',
                      style: TextStyle(fontSize: 8.5, color: _kTextGray),
                    ),
                    const Text(
                      'Huancayo, Perú',
                      style: TextStyle(fontSize: 8.5, color: _kTextGray),
                    ),
                    const Text(
                      'Tel: 930 164 767',
                      style: TextStyle(fontSize: 8.5, color: _kTextGray),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'RUC: 20605995480',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _kTextMid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 7,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        border: Border.all(color: _kBorder),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'BOLETA ELECTRÓNICA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _kTextDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'NRO OPERACIÓN: $_nroBoleta',
                            style: const TextStyle(
                              fontSize: 9,
                              color: _kTextGray,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            '$fechaStr  $horaStr',
                            style: const TextStyle(
                              fontSize: 9,
                              color: _kTextGray,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    _seccion('INFORMACIÓN DE LA RESERVA', [
                      _row(
                        'Cliente:',
                        '${cliente.nombre} ${cliente.apellido}',
                        bold: true,
                      ),
                      _row('Teléfono:', cliente.telefono),
                      _row('Email:', cliente.correo),
                      _row(
                        'Total personas:',
                        '${pasajeros.length + 1}',
                        bold: true,
                      ),
                    ]),
                    _seccion('PASAJEROS EN LA RESERVA', [
                      _pasajeroCard(
                        numero: '1',
                        nombre: '${cliente.nombre} ${cliente.apellido}',
                        doc: cliente.pasaporte,
                        nac: cliente.nacionalidad,
                        isTitular: true,
                      ),
                      ...pasajeros.asMap().entries.map(
                        (e) => _pasajeroCard(
                          numero: '${e.key + 2}',
                          nombre:
                              '${e.value.nombreController.text} ${e.value.apellidoController.text}',
                          doc: e.value.dniController.text,
                          nac: e.value.nacionalidadController.text,
                          isTitular: false,
                        ),
                      ),
                    ]),
                    _seccion('DETALLES DEL PAQUETE', [
                      Text(
                        paquete.nombre,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _row('Duración:', paquete.duracion),
                      _row('Precio base:', _fmt(paquete.precioBase)),
                    ]),
                    _seccion('RESUMEN DE VENTA', [
                      _row(
                        'Multi-Pasajero:',
                        '${pasajeros.length + 1} × ${_fmt(paquete.precioBase)}',
                      ),
                      _dashed(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL IMPORTE:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _kTextDark,
                            ),
                          ),
                          Text(
                            _fmt(total),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _kGreen,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      _dashed(),
                      _row('Op. gravadas:', _fmt(_subtotal)),
                      _row('IGV (18%):', _fmt(_igv)),
                      _dashed(),
                      _row('Método:', 'Tarjeta (Prueba)'),
                      _row('N° Transacción:', numeroTransaccion),
                    ]),
                    _dashed(),
                    const Center(
                      child: Text(
                        '¡Gracias por confiar en IGUAZÚ Tours Express!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _kTextMid,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Emitida el: $fechaStr a las $horaStr',
                        style: const TextStyle(fontSize: 8, color: _kTextGray),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kWarnBg,
                        border: Border.all(color: _kWarnBorder),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '⚠  Toda cancelación debe comunicarse a la agencia dentro de '
                        'las 24 horas posteriores a la reserva. Se aplicará una '
                        'penalidad del 10% sobre el monto total pagado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 7.5, color: _kWarnText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _kGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✓  PAGADO',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Compartir por texto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kGreen,
                    side: const BorderSide(color: _kGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _compartirTexto,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('Descargar PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _generarPDF(context),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
