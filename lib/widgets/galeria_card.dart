import 'package:flutter/material.dart';

class GaleriaCard extends StatelessWidget {
  final String imagen;

  const GaleriaCard({super.key, required this.imagen});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        imagen,
        fit: BoxFit.cover,
      ),
    );
  }
}