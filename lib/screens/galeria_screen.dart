import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class GaleriaScreen extends StatelessWidget {
  const GaleriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final imagenes = [
      'assets/images/img_1.jpg',
      'assets/images/img_2.jpg',
      'assets/images/img_3.jpg',
      'assets/images/img_4.jpg',
      'assets/images/img_5.jpg',
      'assets/images/img_6.jpg',
      'assets/images/img_7.jpg',
      'assets/images/img_8.jpg',
      'assets/images/img_9.jpg',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("📸 Galería de Viajes"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // 🎠 Carrusel de presentación
          CarouselSlider(
            options: CarouselOptions(
              height: 230,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              autoPlayInterval: const Duration(seconds: 3),
            ),
            items: imagenes.map((img) {
              return Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImage(imagen: img),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(img, fit: BoxFit.cover, width: double.infinity),
                    ),
                  );
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // 🖼️ Galería tipo grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: imagenes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImage(imagen: imagenes[index]),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(imagenes[index], fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔍 Pantalla completa con zoom
class FullScreenImage extends StatefulWidget {
  final String imagen;
  const FullScreenImage({super.key, required this.imagen});

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool isZoomed = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Área superior clickeable
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.25,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Imagen interactiva
          Center(
            child: GestureDetector(
              onDoubleTapDown: (details) {
                _doubleTapDetails = details;
              },
              onDoubleTap: () {
                final position = _doubleTapDetails!.localPosition;
                if (!isZoomed) {
                  _transformationController.value = Matrix4.identity()
                    ..translate(-position.dx * 1.5 + MediaQuery.of(context).size.width / 2)
                    ..translate(-position.dy * 1.5 + MediaQuery.of(context).size.height / 2)
                    ..scale(3.0);
                } else {
                  _transformationController.value = Matrix4.identity();
                }
                isZoomed = !isZoomed;
              },
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1,
                maxScale: 4,
                child: Image.asset(widget.imagen),
              ),
            ),
          ),

          // Área inferior clickeable
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.25,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Botón de cerrar
          Positioned(
            top: 30,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
