import 'package:flutter/material.dart';
import '../models/paquete.dart';
import '../models/destino.dart';
import '../services/api_service.dart';
import '../widgets/paquete_card.dart';

class PaquetesScreen extends StatefulWidget {
  const PaquetesScreen({super.key});

  @override
  State<PaquetesScreen> createState() => _PaquetesScreenState();
}

class _PaquetesScreenState extends State<PaquetesScreen> {
  List<Paquete> _paquetes = [];
  Map<int, Destino> _destinos = {};

  // Filtros
  String _filtroTexto = '';
  String _filtroMoneda = 'Todos';
  String _filtroPais = 'Todos';
  String _filtroCiudad = 'Todos';
  String _filtroTipo = 'Todos';
  String _filtroClima = 'Todos';
  String _filtroIdioma = 'Todos';
  String _ordenPrecio = 'Normal';
  double? _precioMin;
  double? _precioMax;

  // Opciones dinámicas
  final List<String> _opcionesMoneda = ['Todos'];
  final List<String> _opcionesPais = ['Todos'];
  final List<String> _opcionesCiudad = ['Todos'];
  final List<String> _opcionesTipo = ['Todos'];
  final List<String> _opcionesClima = ['Todos'];
  final List<String> _opcionesIdioma = ['Todos'];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final paquetes = await ApiService.getPaquetes();
    final destinos = await ApiService.getDestinos();

    setState(() {
      _paquetes = paquetes;
      _destinos = {for (var d in destinos) d.id: d};

      _opcionesMoneda.addAll(destinos.map((d) => d.moneda).toSet());
      _opcionesPais.addAll(destinos.map((d) => d.pais).toSet());
      _opcionesCiudad.addAll(destinos.map((d) => d.ciudad).toSet());
      _opcionesClima.addAll(destinos.map((d) => d.clima).toSet());
      _opcionesIdioma.addAll(destinos.map((d) => d.idioma).toSet());
      _opcionesTipo.addAll(paquetes.map((p) => p.tipo).toSet());
    });
  }

  List<Paquete> get _paquetesFiltrados {
    var filtrados =
        _paquetes.where((p) {
          final destino = _destinos[p.idDestino];
          if (destino == null) return false;

          final texto = _filtroTexto.toLowerCase();

          final coincideTexto =
              p.nombre.toLowerCase().contains(texto) ||
              p.descripcion.toLowerCase().contains(texto) ||
              destino.ciudad.toLowerCase().contains(texto) ||
              destino.pais.toLowerCase().contains(texto) ||
              destino.clima.toLowerCase().contains(texto) ||
              destino.idioma.toLowerCase().contains(texto) ||
              destino.atracciones.toLowerCase().contains(texto) ||
              p.tipo.toLowerCase().contains(texto);

          final enRango =
              (_precioMin == null || p.precioBase >= _precioMin!) &&
              (_precioMax == null || p.precioBase <= _precioMax!);

          return coincideTexto &&
              (_filtroMoneda == 'Todos' || destino.moneda == _filtroMoneda) &&
              (_filtroPais == 'Todos' || destino.pais == _filtroPais) &&
              (_filtroCiudad == 'Todos' || destino.ciudad == _filtroCiudad) &&
              (_filtroTipo == 'Todos' || p.tipo == _filtroTipo) &&
              (_filtroClima == 'Todos' || destino.clima == _filtroClima) &&
              (_filtroIdioma == 'Todos' || destino.idioma == _filtroIdioma) &&
              enRango;
        }).toList();

    if (_ordenPrecio == 'Mayor precio') {
      filtrados.sort((a, b) => b.precioBase.compareTo(a.precioBase));
    } else if (_ordenPrecio == 'Menor precio') {
      filtrados.sort((a, b) => a.precioBase.compareTo(b.precioBase));
    }

    return filtrados;
  }

  Widget _filtroChip({
    required String label,
    required String valorActual,
    required List<String> opciones,
    required Function(String) onChanged,
  }) {
    return PopupMenuButton<String>(
      initialValue: valorActual,
      onSelected: onChanged,
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: $valorActual', style: const TextStyle(fontSize: 14)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
        backgroundColor: Colors.green.shade100,
      ),
      itemBuilder:
          (_) =>
              opciones
                  .map((op) => PopupMenuItem(value: op, child: Text(op)))
                  .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Row(
          children: [
            Text('💼', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Paquetes Turísticos'),
          ],
        ),

        centerTitle: true,
      ),
      body:
          _paquetes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔰 Presentación
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Texto
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Descubre nuestras experiencias turísticas',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '🌄 Paquetes increíbles con transporte, alimentación y guías locales',
                                ),
                                Text(
                                  '📍 Viajes a Oxapampa, Huancayo, Pozuzo, Perené y más',
                                ),
                                Text('📅 Disponibles todo el año'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/Info.png',
                              width: 180,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔍 Buscador
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '🔍 Buscar paquete deseado',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() => _filtroTexto = val),
                    ),
                    const SizedBox(height: 12),

                    // 🎯 Filtros
                    Align(
                      alignment: Alignment.center,
                      child: Wrap(
                        alignment:
                            WrapAlignment.center, // Centra horizontalmente
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _filtroChip(
                            label: '💰 Moneda',
                            valorActual: _filtroMoneda,
                            opciones: _opcionesMoneda,
                            onChanged: (v) => setState(() => _filtroMoneda = v),
                          ),
                          _filtroChip(
                            label: '🌍 País',
                            valorActual: _filtroPais,
                            opciones: _opcionesPais,
                            onChanged: (v) => setState(() => _filtroPais = v),
                          ),
                          _filtroChip(
                            label: '📍 Ciudad',
                            valorActual: _filtroCiudad,
                            opciones: _opcionesCiudad,
                            onChanged: (v) => setState(() => _filtroCiudad = v),
                          ),
                          _filtroChip(
                            label: '🏷️ Tipo',
                            valorActual: _filtroTipo,
                            opciones: _opcionesTipo,
                            onChanged: (v) => setState(() => _filtroTipo = v),
                          ),
                          _filtroChip(
                            label: '🌦️ Clima',
                            valorActual: _filtroClima,
                            opciones: _opcionesClima,
                            onChanged: (v) => setState(() => _filtroClima = v),
                          ),
                          _filtroChip(
                            label: '🗣️ Idioma',
                            valorActual: _filtroIdioma,
                            opciones: _opcionesIdioma,
                            onChanged: (v) => setState(() => _filtroIdioma = v),
                          ),
                          _filtroChip(
                            label: '📈 Orden',
                            valorActual: _ordenPrecio,
                            opciones: [
                              'Normal',
                              'Mayor precio',
                              'Menor precio',
                            ],
                            onChanged: (v) => setState(() => _ordenPrecio = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Rango de precios
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Precio mínimo',
                              isDense: true,
                            ),
                            onChanged:
                                (val) => setState(
                                  () => _precioMin = double.tryParse(val),
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Precio máximo',
                              isDense: true,
                            ),
                            onChanged:
                                (val) => setState(
                                  () => _precioMax = double.tryParse(val),
                                ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🧳 Resultados
                    ..._paquetesFiltrados.map((p) {
                      final destino = _destinos[p.idDestino];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PaqueteCard(paquete: p, destino: destino!),
                      );
                    }),
                  ],
                ),
              ),
    );
  }
}
