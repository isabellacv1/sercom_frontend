import 'package:flutter/material.dart';
import '../services/certification_service.dart';

class CertificationDetailScreen extends StatefulWidget {
  final String certificationId;


  const CertificationDetailScreen({
    super.key,
    required this.certificationId,
  });

  @override
  State<CertificationDetailScreen> createState() =>
      _CertificationDetailScreenState();
}

class _CertificationDetailScreenState
    extends State<CertificationDetailScreen> {
  final CertificationService _service =
      CertificationService();

  CertificationDetail? certification;

  bool isLoading = true;

  bool isEnrolling = false;

  bool isEnrolled = false;

  @override
  void initState() {
    super.initState();
    loadCertification();
    checkEnrollment();
  }

  Future<void> loadCertification() async {
    try {
      setState(() {
        isLoading = true;
      });

      final result =
          await _service.getCertificationDetail(
        widget.certificationId,
      );

      setState(() {
        certification = result;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error cargando certificación: $e',
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

  Future<void> checkEnrollment() async {
  try {
    final enrollments =
        await _service.getMyEnrollments();

    final exists = enrollments.any(
      (e) =>
          e.certification.id ==
          widget.certificationId,
    );

    if (!mounted) return;

    setState(() {
      isEnrolled = exists;
    });
  } catch (_) {}
}

  Future<void> enroll() async {
  if (isEnrolling || isEnrolled) return;

  try {
    setState(() {
      isEnrolling = true;
    });

    await _service.enrollCertification(
      widget.certificationId,
    );

    if (!mounted) return;

    setState(() {
      isEnrolled = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Inscripción realizada correctamente',
        ),
      ),
    );
  } catch (e) {
  if (!mounted) return;

  final message = e.toString();

  final alreadyEnrolled =
      message.toLowerCase().contains(
        'ya estás inscrito',
      );

  if (alreadyEnrolled) {
    setState(() {
      isEnrolled = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ya estás inscrito en esta certificación',
        ),
      ),
    );

    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Error: $message',
      ),
    ),
  );
} finally {
    if (mounted) {
      setState(() {
        isEnrolling = false;
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
        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : certification == null
                ? const Center(
                    child: Text(
                      'No se encontró la certificación',
                    ),
                  )
                : SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration:
                                  BoxDecoration(
                                color: Colors.white,
                                shape:
                                    BoxShape.circle,
                                border: Border.all(
                                  color:
                                      borderColor,
                                ),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                  );
                                },
                                icon: const Icon(
                                  Icons
                                      .arrow_back_ios_new,
                                  color: textDark,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            const Expanded(
                              child: Text(
                                'Detalle',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                  color:
                                      textDark,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(
                            26,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              32,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color:
                                    Color(
                                  0x12000000,
                                ),
                                blurRadius:
                                    12,
                                offset:
                                    Offset(
                                  0,
                                  4,
                                ),
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
                                      vertical:
                                          7,
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
                                      certification!
                                          .category,
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
                                      const Icon(
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
                                        '${certification!.durationHours ?? 0} horas',
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
                                height: 24,
                              ),

                              Text(
                                certification!
                                    .name,
                                style:
                                    const TextStyle(
                                  fontSize: 34,
                                  height: 1.1,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                  color:
                                      textDark,
                                ),
                              ),

                              const SizedBox(
                                height: 18,
                              ),

                              Text(
                                certification!
                                        .description ??
                                    'Sin descripción disponible',
                                style:
                                    const TextStyle(
                                  fontSize: 16,
                                  height: 1.7,
                                  color:
                                      textSoft,
                                  fontWeight:
                                      FontWeight
                                          .w500,
                                ),
                              ),

                              const SizedBox(
                                height: 24,
                              ),

                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal:
                                      14,
                                  vertical: 10,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      difficultyColor(
                                    certification!
                                        .difficulty,
                                  ).withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    18,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize
                                          .min,
                                  children: [
                                    Icon(
                                      Icons
                                          .stars_rounded,
                                      size: 18,
                                      color:
                                          difficultyColor(
                                        certification!
                                            .difficulty,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      difficultyLabel(
                                        certification!
                                            .difficulty,
                                      ),
                                      style:
                                          TextStyle(
                                        color:
                                            difficultyColor(
                                          certification!
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
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        const Text(
                          'Módulos de la certificación',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.w800,
                            color: textDark,
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        ListView.separated(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount:
                              certification!
                                  .modules
                                  .length,
                          separatorBuilder:
                              (_, __) =>
                                  const SizedBox(
                            height: 16,
                          ),
                          itemBuilder:
                              (_, index) {
                            final module =
                                certification!
                                    .modules[index];

                            return Container(
                              padding:
                                  const EdgeInsets.all(
                                22,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,
                                borderRadius:
                                    BorderRadius.circular(
                                  26,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color:
                                        Color(
                                      0x10000000,
                                    ),
                                    blurRadius:
                                        8,
                                    offset:
                                        Offset(
                                      0,
                                      4,
                                    ),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          primaryColor,
                                      borderRadius:
                                          BorderRadius.circular(
                                        14,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${module.orderIndex}',
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors
                                                  .white,
                                          fontWeight:
                                              FontWeight
                                                  .w800,
                                          fontSize:
                                              16,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 16,
                                  ),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          module
                                              .title,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                20,
                                            fontWeight:
                                                FontWeight
                                                    .w800,
                                            color:
                                                textDark,
                                          ),
                                        ),

                                        const SizedBox(
                                          height:
                                              8,
                                        ),

                                        Text(
                                          module.description ??
                                              'Sin descripción',
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                15,
                                            height:
                                                1.5,
                                            color:
                                                textSoft,
                                            fontWeight:
                                                FontWeight
                                                    .w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(
                          height: 40,
                        ),

                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed:
                              isEnrolled || isEnrolling
                                  ? null
                                  : enroll,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  isEnrolled
                                  ? Colors.grey
                                  : primaryColor,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  22,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                if (isEnrolling)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                else ...[
                                  Text(
                                    isEnrolled
                                        ? 'Ya inscrito'
                                        : 'Comenzar certificación',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    isEnrolled
                                        ? Icons.check_circle_rounded
                                        : Icons
                                            .rocket_launch_rounded,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}