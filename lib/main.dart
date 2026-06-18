import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/paquetes_screen.dart';
import 'screens/galeria_screen.dart';
import 'screens/paquete_detalle_screen.dart';
import 'models/paquete.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PaquetesScreen(),
    const GaleriaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tours Iguazú',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: const Color(0xFFF6F9F9),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_travel),
              label: 'Paquetes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_album),
              label: 'Galería',
            ),
          ],
        ),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/paquete_detalle') {
          final paquete = settings.arguments;
          if (paquete is Paquete) {
            return MaterialPageRoute(
              builder: (_) => PaqueteDetalleScreen(paquete: paquete),
            );
          }
        }
        return null;
      },
    );
  }
}
