import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/service_option_model.dart';
import '../services/service_option_service.dart';

class CategoryServicesPage extends StatefulWidget {
  const CategoryServicesPage({super.key});

  @override
  State<CategoryServicesPage> createState() => _CategoryServicesPageState();
}

class _CategoryServicesPageState extends State<CategoryServicesPage> {
  final ServiceOptionService _serviceOptionService = ServiceOptionService();
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  List<ServiceOptionModel> services = [];
  List<ServiceOptionModel> filteredServices = [];

  late CategoryModel category;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    category = ModalRoute.of(context)!.settings.arguments as CategoryModel;
    loadServices();
  }

  Future<void> loadServices() async {
    try {
      final result = await _serviceOptionService.getByCategory(category.id);
      setState(() {
        services = result;
        filteredServices = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error cargando servicios: $e');
    }
  }

  void filterServices(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        filteredServices = services;
      } else {
        filteredServices = services.where((service) {
          return service.title.toLowerCase().contains(q) ||
              service.description.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  IconData _getServiceIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('luminaria') || t.contains('lampara')) {
      return Icons.lightbulb;
    }
    if (t.contains('tablero') || t.contains('breaker')) {
      return Icons.warning_amber_rounded;
    }
    if (t.contains('tomacorriente') || t.contains('enchufe')) {
      return Icons.power;
    }
    if (t.contains('domot')) {
      return Icons.home;
    }
    return Icons.build_circle_outlined;
  }

  Color _getServiceColor(int index) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFFF97316),
      const Color(0xFF22C55E),
      const Color(0xFFA855F7),
    ];
    return colors[index % colors.length];
  }

  String _getRecommendedSpecialist(String title) {
    final t = title.toLowerCase();
    if (t.contains('tablero') || t.contains('breaker')) {
      return 'Recomendado: Especialista Categoría III';
    }
    if (t.contains('luminaria') || t.contains('domot')) {
      return 'Recomendado: Especialista Categoría II';
    }
    return 'Recomendado: Especialista Categoría I';
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                            Expanded(
                              flex: 4,
                              child: Text(
                                category.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: searchController,
                            onChanged: filterServices,
                            decoration: InputDecoration(
                              hintText: 'Buscar servicios en ${category.name}...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF64748B),
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredServices.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron servicios',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              const Text(
                                'Servicios Disponibles',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 18),
                              ...List.generate(filteredServices.length, (index) {
                                final service = filteredServices[index];
                                final color = _getServiceColor(index);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/create-mission',
                                        arguments: {
                                          'category': category,
                                          'serviceOption': service,
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x12000000),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: color.withOpacity(0.15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  _getServiceIcon(service.title),
                                                  color: color,
                                                  size: 30,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      service.title,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w800,
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      service.description,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        color: Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right,
                                                color: Color(0xFF64748B),
                                                size: 28,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(22),
                                              border: Border.all(
                                                color: const Color(0xFFBFDBFE),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.verified_user,
                                                  size: 18,
                                                  color: Color(0xFF2563EB),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _getRecommendedSpecialist(
                                                      service.title,
                                                    ),
                                                    style: const TextStyle(
                                                      color: Color(0xFF2563EB),
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}