import 'package:flutter/material.dart';
import '../services/certification_service.dart';
import 'certification_detail_screen.dart';

class CertificationsScreen extends StatefulWidget {
  const CertificationsScreen({super.key});

  @override
  State<CertificationsScreen> createState() =>
      _CertificationsScreenState();
}

class _CertificationsScreenState
    extends State<CertificationsScreen> {
  final CertificationService _service =
      CertificationService();

  List<CertificationInfo> certifications = [];

  bool isLoading = true;

  String? selectedCategory;

  List<String> get categories {
  final unique = certifications
      .map((e) => e.category)
      .where((e) => e.trim().isNotEmpty)
      .toSet()
      .toList();

  unique.sort();

  return ['Todas', ...unique];
}

  @override
  void initState() {
    super.initState();
    loadCertifications();
  }

  Future<void> loadCertifications() async {
    try {
      setState(() {
        isLoading = true;
      });

      final result = await _service.getCertifications(
  category: (selectedCategory == null ||
          selectedCategory == 'Todas')
      ? null
      : selectedCategory,
);

      setState(() {
        certifications = result;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error cargando certificaciones: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String difficultyLabel(String? difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Principiante';

      case 'intermediate':
        return 'Intermedio';

      case 'advanced':
        return 'Avanzado';

      default:
        return 'No definido';
    }
  }

  Color difficultyColor(String? difficulty) {
    switch (difficulty) {
      case 'beginner':
        return const Color(0xFF28C76F);

      case 'intermediate':
        return const Color(0xFFFF9F43);

      case 'advanced':
        return const Color(0xFFEA5455);

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF5F6FA);
    const textDark = Color(0xFF101828);
    const textSoft = Color(0xFF6B7A99);
    const borderColor = Color(0xFFD9DEE8);
    const primaryColor = Color(0xFFFF7F2A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadCertifications,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Certificaciones',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_outlined,
                        color: textDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8ED),
                    borderRadius:
                        BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFFFE1B3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Impulsa tu perfil profesional',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight:
                                    FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Explora certificaciones disponibles y mejora tus habilidades laborales.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: textSoft,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius:
                              BorderRadius.circular(
                            22,
                          ),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      final category =
                          categories[index];

                      final isSelected =
                          selectedCategory ==
                                  category ||
                              (selectedCategory ==
                                      null &&
                                  category ==
                                      'Todas');

                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            selectedCategory =
                                category;
                          });

                          await loadCertifications();
                        },
                        child: AnimatedContainer(
                          duration:
                              const Duration(
                            milliseconds: 200,
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : borderColor,
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : textDark,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 26),

                if (isLoading)
                  const Center(
                    child: Padding(
                      padding:
                          EdgeInsets.only(top: 80),
                      child:
                          CircularProgressIndicator(),
                    ),
                  )
                else if (certifications.isEmpty)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 64,
                          color: textSoft,
                        ),
                        SizedBox(height: 18),
                        Text(
                          'No hay certificaciones disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    itemCount:
                        certifications.length,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 18),
                    itemBuilder: (_, index) {
                      final cert =
                          certifications[index];

                      return Container(
                        padding:
                            const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            30,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color:
                                  Color(0x12000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal:
                                        12,
                                    vertical: 7,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        const Color(
                                      0xFFFFF0E5,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                  child: Text(
                                    cert.category,
                                    style:
                                        const TextStyle(
                                      color:
                                          primaryColor,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .schedule_rounded,
                                      size: 18,
                                      color:
                                          textSoft,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      '${cert.durationHours ?? 0}h',
                                      style:
                                          const TextStyle(
                                        color:
                                            textSoft,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            Text(
                              cert.name,
                              style:
                                  const TextStyle(
                                fontSize: 28,
                                height: 1.1,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                color: textDark,
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            Text(
                              cert.description ??
                                  'Sin descripción disponible',
                              style:
                                  const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: textSoft,
                                fontWeight:
                                    FontWeight
                                        .w500,
                              ),
                            ),

                            const SizedBox(
                              height: 22,
                            ),

                            Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal:
                                        12,
                                    vertical: 8,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        difficultyColor(
                                      cert
                                          .difficulty,
                                    ).withValues(
                                      alpha:
                                          0.15,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      18,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons
                                            .stars_rounded,
                                        size: 16,
                                        color:
                                            difficultyColor(
                                          cert
                                              .difficulty,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      Text(
                                        difficultyLabel(
                                          cert
                                              .difficulty,
                                        ),
                                        style:
                                            TextStyle(
                                          color:
                                              difficultyColor(
                                            cert
                                                .difficulty,
                                          ),
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 26,
                            ),

                            SizedBox(
                              width:
                                  double.infinity,
                              height: 58,
                              child: OutlinedButton(
                                onPressed: () {
                                            Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CertificationDetailScreen(
                                                certificationId: cert.id,
                                              ),
                                            ),
                                          );
                                },
                                style:
                                    OutlinedButton.styleFrom(
                                  side:
                                      const BorderSide(
                                    color:
                                        primaryColor,
                                  ),
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      18,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Text(
                                      'Ver certificación',
                                      style:
                                          TextStyle(
                                        color:
                                            primaryColor,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        fontSize:
                                            16,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Icon(
                                      Icons
                                          .arrow_forward_rounded,
                                      color:
                                          primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}