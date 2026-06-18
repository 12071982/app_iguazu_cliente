import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/paquete.dart';
import '../services/api_service.dart';
import 'checkout_screen.dart'; // Ajusta la ruta si es necesario

class PaqueteDetalleScreen extends StatelessWidget {
  final Paquete paquete;

  const PaqueteDetalleScreen({super.key, required this.paquete});

  void _contactarPorWhatsApp(BuildContext context, String mensaje) async {
    final url = Uri.parse(
      "https://wa.me/+51949804809?text=${Uri.encodeComponent(mensaje)}",
    );
    if (!context.mounted) return;

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ApiService.getDestinos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final destino = snapshot.data!.firstWhere(
          (d) => d.id == paquete.idDestino,
        );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green.shade700,
            title: const Row(
              children: [
                Text('💼', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text('Detalle del Paquete'),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼 Imagen con info y precio
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        paquete.imagen ?? 'assets/images/viaje.jpeg',
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(left: 16),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📍 ${destino.ciudad}, ${destino.pais}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                '🕒 Duración: ${paquete.duracion}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                '📅 Inicio: ${paquete.fechaInicio}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                '🏁 Fin: ${paquete.fechaFin}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '💵 ${paquete.precioBase.toStringAsFixed(2)} ${destino.moneda}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 🏷 Título
                Text(
                  paquete.nombre,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                // 📌 Descripción
                const Text(
                  '📌 Descripción:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(paquete.descripcion),

                const SizedBox(height: 10),
                Text('🎯 Atracciones: ${destino.atracciones}'),
                Text(
                  '🏷️ Tipo: ${paquete.tipo}   🌦️ Clima: ${destino.clima}   🗣️ Idioma: ${destino.idioma}',
                ),

                const SizedBox(height: 20),

                const Text(
                  '✅ Inclusiones:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  paquete.inclusiones.isNotEmpty
                      ? paquete.inclusiones
                      : 'No especificado',
                ),

                const SizedBox(height: 12),

                const Text(
                  '❌ Exclusiones:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  paquete.exclusiones.isNotEmpty
                      ? paquete.exclusiones
                      : 'No especificado',
                ),

                const SizedBox(height: 24),

                // 🎠 Carrusel de otros paquetes
                FutureBuilder(
                  future: ApiService.getPaquetes(),
                  builder: (context, snapPaquetes) {
                    if (!snapPaquetes.hasData) return const SizedBox.shrink();

                    final otros =
                        snapPaquetes.data!
                            .where((p) => p.idPaquete != paquete.idPaquete)
                            .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🌟 Otros paquetes recomendados:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: otros.length,
                            itemBuilder: (context, index) {
                              final otro = otros[index];
                              final destinoOtro = snapshot.data!.firstWhere(
                                (d) => d.id == otro.idDestino,
                              );
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => PaqueteDetalleScreen(
                                            paquete: otro,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 260,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: AssetImage(
                                        otro.imagen ??
                                            'assets/images/viaje.jpeg',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Info centrada
                                      Positioned.fill(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              left: 12,
                                            ),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.45,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '📍 ${destinoOtro.ciudad}, ${destinoOtro.pais}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  '🕒 Duración: ${otro.duracion}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  '📅 Inicio: ${otro.fechaInicio}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  '🏁 Fin: ${otro.fechaFin}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Precio en esquina inferior derecha
                                      Positioned(
                                        bottom: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.8,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '💵 ${otro.precioBase.toStringAsFixed(2)} ${destinoOtro.moneda}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),

                // 🟢 Botón PAGAR AHORA (nuevo)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('Pagar ahora'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(
                            paquete: paquete,
                            destino: destino,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // 🟢 Botón WhatsApp
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Text(
                      '📱',
                      style: TextStyle(fontSize: 20),
                    ),
                    label: const Text('Solicitar información'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed:
                        () => _contactarPorWhatsApp(
                          context,
                          'Hola, estoy interesado en el paquete "${paquete.nombre}" a ${destino.ciudad}.',
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}