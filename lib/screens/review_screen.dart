import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MockReviewScreen – Placeholder de Calificación.
/// Objetivo: validar el flujo de navegación. La lógica de reviews se implementará en otra H.U.
class ReviewScreen extends StatelessWidget {
  final String serviceId;

  const ReviewScreen({Key? key, required this.serviceId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.star_rounded,
                  size: 48,
                  color: Color(0xFFF97316),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Pantalla de Calificación',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Próximamente',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Servicio #$serviceId',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Volver al Inicio',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
