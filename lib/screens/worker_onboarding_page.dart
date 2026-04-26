import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'worker_home_screen.dart';

class WorkerOnboardingPage extends StatefulWidget {
  const WorkerOnboardingPage({Key? key}) : super(key: key);

  @override
  State<WorkerOnboardingPage> createState() => _WorkerOnboardingPageState();
}

class _WorkerOnboardingPageState extends State<WorkerOnboardingPage> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _activateProfile() async {
    setState(() => _isLoading = true);
    try {
      await _authService.activateWorkerProfile();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WorkerHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al activar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Modo Trabajador',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.handyman, size: 100, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '¡Tu talento tiene\nrecompensa!',
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Únete a la comunidad de TaskRank, completa misiones y genera ingresos con tus habilidades.',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureItem(
              icon: Icons.monetization_on,
              iconColor: const Color(0xFFFF8A00),
              iconBgColor: const Color(0xFFFFF1E8),
              title: 'Genera Ingresos Extras',
              description: 'Encuentra misiones que se ajusten a tu tiempo y habilidades en tu zona.',
            ),
            const SizedBox(height: 24),
            _buildFeatureItem(
              icon: Icons.star,
              iconColor: const Color(0xFF2563EB),
              iconBgColor: const Color(0xFFEFF6FF),
              title: 'Mejora tu Ranking',
              description: 'Entre más misiones completes con éxito, mayor será tu visibilidad y reputación.',
            ),
            const SizedBox(height: 24),
            _buildFeatureItem(
              icon: Icons.verified_user,
              iconColor: Colors.green,
              iconBgColor: Colors.green.withOpacity(0.1),
              title: 'Seguridad Total',
              description: 'Pagos garantizados y soporte técnico para cada una de tus misiones.',
            ),
            const SizedBox(height: 48),
            Text(
              'Puedes volver al modo cliente en cualquier momento desde tu perfil.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _activateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A20), // Naranja vibrante
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Activar Perfil de Trabajador',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
