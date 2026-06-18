import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class GaleriaScreen extends StatefulWidget {
  const GaleriaScreen({super.key});

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  final List<String> imagenes = [
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

  // índice actual del carrusel para sincronizar con la galería
  int _carouselIndex = 0;

  void _abrirVisor(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => FullScreenGallery(imagenes: imagenes, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📸 Galería de Viajes"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ── Carrusel ────────────────────────────────────
          CarouselSlider.builder(
            itemCount: imagenes.length,
            options: CarouselOptions(
              height: 230,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              autoPlayInterval: const Duration(seconds: 3),
              onPageChanged: (i, _) => setState(() => _carouselIndex = i),
            ),
            itemBuilder:
                (context, index, _) => GestureDetector(
                  onTap: () => _abrirVisor(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      imagenes[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
          ),

          // Indicador de dots del carrusel
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                imagenes.asMap().entries.map((e) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _carouselIndex == e.key ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color:
                          _carouselIndex == e.key
                              ? Colors.green.shade700
                              : Colors.green.shade200,
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 12),

          // ── Grid ────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: imagenes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder:
                  (context, index) => GestureDetector(
                    onTap: () => _abrirVisor(index),
                    child: Hero(
                      tag: 'img_$index',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
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

// ═══════════════════════════════════════════════════════════════
//  VISOR A PANTALLA COMPLETA CON SWIPE ENTRE IMÁGENES
// ═══════════════════════════════════════════════════════════════
class FullScreenGallery extends StatefulWidget {
  final List<String> imagenes;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.imagenes,
    required this.initialIndex,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late final PageController _pageCtrl;
  late int _currentIndex;
  bool _isZoomed = false; // bloquea el swipe cuando hay zoom activo

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── PageView principal ───────────────────────────
          PageView.builder(
            controller: _pageCtrl,
            // Si hay zoom activo bloqueamos el deslizamiento de página
            physics:
                _isZoomed
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
            itemCount: widget.imagenes.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder:
                (context, index) => _ZoomablePage(
                  imagen: widget.imagenes[index],
                  heroTag: 'img_$index',
                  onZoomChanged: (zoomed) {
                    if (_isZoomed != zoomed) setState(() => _isZoomed = zoomed);
                  },
                ),
          ),

          // ── Botón cerrar ─────────────────────────────────
          Positioned(
            top: 42,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // ── Contador  "3 / 9" ────────────────────────────
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.imagenes.length}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),

          // ── Dots inferiores ──────────────────────────────
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  widget.imagenes.asMap().entries.map((e) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentIndex == e.key ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color:
                            _currentIndex == e.key
                                ? Colors.white
                                : Colors.white38,
                      ),
                    );
                  }).toList(),
            ),
          ),

          // ── Hint de zoom (solo en la primera imagen) ─────
          if (_currentIndex == widget.initialIndex && !_isZoomed)
            const Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Pellizca o doble toque para hacer zoom',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PÁGINA INDIVIDUAL CON ZOOM
// ═══════════════════════════════════════════════════════════════
class _ZoomablePage extends StatefulWidget {
  final String imagen;
  final String heroTag;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomablePage({
    required this.imagen,
    required this.heroTag,
    required this.onZoomChanged,
  });

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> {
  final TransformationController _ctrl = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    // Escucha cambios de escala para notificar al padre
    _ctrl.addListener(_onTransform);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTransform);
    _ctrl.dispose();
    super.dispose();
  }

  void _onTransform() {
    final scale = _ctrl.value.getMaxScaleOnAxis();
    widget.onZoomChanged(scale > 1.05);
  }

  void _doubleTapZoom() {
    final scale = _ctrl.value.getMaxScaleOnAxis();

    if (scale <= 1.05) {
      final pos = _doubleTapDetails!.localPosition;
      const s = 3.0;

      // tx/ty garantizan que el punto tocado quede fijo tras el zoom
      final tx =
          pos.dx * (1 - s); // ejemplo: toco en x=200 → tx = 200*(1-3) = -400
      final ty = pos.dy * (1 - s); // toco en y=400 → ty = 400*(1-3) = -800

      _ctrl.value =
          Matrix4.identity()
            ..translate(tx, ty) // ← un solo translate con X e Y
            ..scale(s);
    } else {
      _ctrl.value =
          Matrix4.identity(); // doble toque de nuevo → vuelve al normal
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _doubleTapDetails = d,
      onDoubleTap: _doubleTapZoom,
      child: InteractiveViewer(
        transformationController: _ctrl,
        minScale: 1.0,
        maxScale: 5.0,
        clipBehavior: Clip.none,
        child: Center(
          child: Hero(tag: widget.heroTag, child: Image.asset(widget.imagen)),
        ),
      ),
    );
  }
}
