import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/iguazu.webm')
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.setVolume(0);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _contactarPorWhatsapp() async {
    final mensaje = Uri.encodeComponent("¡Hola! Estoy interesado en un paquete turístico. ¿Me puedes brindar más información?");
    final url = 'https://wa.me/51949804809?text=$mensaje';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'No se pudo abrir WhatsApp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🎥 Banner de video recortado
            Stack(
              children: [
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.7,
                    child: SizedBox(
                      width: double.infinity,
                      height: 280,
                      child: _controller.value.isInitialized
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _controller.value.size.width,
                                height: _controller.value.size.height,
                                child: VideoPlayer(_controller),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Siente lo bueno de viajar!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Descubre todo lo que puedes conocer\ncon nosotros.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _contactarPorWhatsapp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Reservar ahora'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔻 Paquetes recomendados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const Text(
                    'LO MÁS BUSCADO POR LOS VIAJEROS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Atrévete a vivir un momento inolvidable visitando lugares únicos.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 🌀 Scroll inteligente horizontal
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double totalCardWidth = 160 * 4 + 8 * 6;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: totalCardWidth > constraints.maxWidth
                            ? const BouncingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: Row(
                          children: [
                            _cardDestino('Pozuzo', 'Pasco', 'assets/images/img_1.jpg'),
                            _cardDestino('Huaytapallana', 'Junín', 'assets/images/img_2.jpg'),
                            _cardDestino('Perené', 'Junín', 'assets/images/img_3.jpg'),
                            _cardDestino('Oxapampa', 'Pasco', 'assets/images/img_5.jpg'),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🔻 Experiencia destacada
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(child: Image.asset('assets/images/ruta.jpeg', height: 180)),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Una aventura única',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text(
                          '¿Qué esperas para visitar los increíbles lugares de la zona central del país?\n¡Te pasaremos increíble!',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🔻 Footer institucional
            Container(
              width: double.infinity,
              color: const Color(0xFFEEEEEE),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Más Información', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('📍 Dirección: Huancayo, Perú'),
                  Text('📞 Contáctanos: 930 164 767'),
                  Text('🌐 Facebook: Tour Express Iguazú'),
                  SizedBox(height: 8),
                  Text('© 2025 Creado por IC. Todos los derechos reservados'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌎 Tarjetas de destinos turísticos
  Widget _cardDestino(String nombre, String region, String imgPath) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.asset(imgPath, height: 100, width: double.infinity, fit: BoxFit.cover),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(region, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
