import 'package:flutter/material.dart';
import '../models/paquete.dart';
import '../models/destino.dart';

class PaqueteCard extends StatelessWidget {
  final Paquete paquete;
  final Destino destino;

  const PaqueteCard({super.key, required this.paquete, required this.destino});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 📸 Imagen de fondo
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.asset(
              paquete.imagen ?? 'assets/images/viaje.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          // 🌗 Capa para legibilidad
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
              ),
            ),
          ),

          // 🏷️ Nombre del paquete
          Positioned(
            top: 12,
            left: 16,
            child: Text(
              paquete.nombre,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
              ),
            ),
          ),

          // 📋 Contenido textual encapsulado
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 40),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
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
                      const SizedBox(height: 2),
                      Text(
                        '💵 ${paquete.precioBase.toStringAsFixed(2)} ${destino.moneda}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '🕒 Duración: ${paquete.duracion}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📅 Inicio: ${paquete.fechaInicio}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '🏁 Fin: ${paquete.fechaFin}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 🔘 Botón "Más información"
          Positioned(
            bottom: 12,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/paquete_detalle',
                  arguments: paquete,
                );
              },
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('Más información'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: const Color(0xFF333333),
                elevation: 6,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.normal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
