import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/service_option_model.dart';
import '../models/mission_model.dart';
import '../services/mission_service.dart';

class CreateMissionPage extends StatefulWidget {
  const CreateMissionPage({super.key});

  @override
  State<CreateMissionPage> createState() => _CreateMissionPageState();
}

class _CreateMissionPageState extends State<CreateMissionPage> {
  final _formKey = GlobalKey<FormState>();
  final MissionService _missionService = MissionService();

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  int currentStep = 1;
  double minBudget = 40000;
  double maxBudget = 80000;
  bool isSubmitting = false;

  CategoryModel? category;
  ServiceOptionModel? serviceOption;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      final rawCategory = args['category'];
      final rawServiceOption = args['serviceOption'];

      if (rawCategory is CategoryModel) {
        category = rawCategory;
      }

      if (rawServiceOption is ServiceOptionModel) {
        serviceOption = rawServiceOption;
      }
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> submitMission() async {
    if (!_formKey.currentState!.validate()) return;

    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar una categoría')),
      );
      return;
    }

    if (serviceOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar una opción de servicio')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final MissionModel mission = await _missionService.createMission(
        categoryId: category!.id,
        serviceOptionId: serviceOption!.id,
        title: serviceOption!.title,
        description: descriptionController.text.trim(),
        address: addressController.text.trim(),
        minBudget: minBudget.round(),
        maxBudget: maxBudget.round(),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/mission-dispatch',
        arguments: mission,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear misión: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void nextStep() {
    if (currentStep == 1) {
      if (descriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes ingresar una descripción')),
        );
        return;
      }
    }

    if (currentStep == 2) {
      if (addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes ingresar una dirección')),
        );
        return;
      }
    }

    if (currentStep < 3) {
      setState(() {
        currentStep++;
      });
    } else {
      submitMission();
    }
  }

  void previousStep() {
    if (currentStep > 1) {
      setState(() {
        currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  String formatPrice(double value) {
    return '\$${value.round()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(23),
                          ),
                          child: IconButton(
                            onPressed: previousStep,
                            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Nueva Misión',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 46),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildStepper(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: currentStep == 1
                      ? _buildDetailStep()
                      : currentStep == 2
                          ? _buildLocationStep()
                          : _buildBudgetStep(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0x332563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: isSubmitting ? null : nextStep,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            currentStep < 3
                                ? 'Siguiente'
                                : 'Solicitar despacho automático',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStep() {
    final remaining = 500 - descriptionController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category != null
              ? '¿Qué necesitas en ${category!.name}?'
              : '¿Qué necesitas arreglar?',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        if (serviceOption != null) ...[
          const SizedBox(height: 6),
          Text(
            'Servicio seleccionado: ${serviceOption!.title}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: descriptionController,
            maxLength: 500,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Describe el problema que necesitas solucionar',
              border: InputBorder.none,
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La descripción es obligatoria';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$remaining caracteres restantes',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación del servicio',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: addressController,
            decoration: const InputDecoration(
              hintText: 'Av. Siempre Viva 123',
              prefixIcon: Icon(Icons.location_on_outlined),
              border: InputBorder.none,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La dirección es obligatoria';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xFFDFF1FF),
            image: const DecorationImage(
              image: NetworkImage(
                'https://static.vecteezy.com/system/resources/previews/002/206/854/non_2x/city-map-with-gps-navigation-blue-marker-free-vector.jpg',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Presupuesto estimado (opcional)',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 18),
        _buildBudgetCard(
          title: 'Presupuesto mínimo',
          value: minBudget,
          onChanged: (value) {
            setState(() {
              minBudget = value;
              if (minBudget > maxBudget) {
                maxBudget = minBudget;
              }
            });
          },
        ),
        const SizedBox(height: 18),
        _buildBudgetCard(
          title: 'Presupuesto máximo',
          value: maxBudget,
          onChanged: (value) {
            setState(() {
              maxBudget = value;
              if (maxBudget < minBudget) {
                minBudget = maxBudget;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildBudgetCard({
    required String title,
    required double value,
    required Function(double) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatPrice(value),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2563EB),
            ),
          ),
          Slider(
            value: value,
            min: 10000,
            max: 1000000,
            divisions: 99,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    Widget step(int index, String label) {
      final active = currentStep == index;
      final done = currentStep > index;

      return Expanded(
        child: Row(
          children: [
            if (index != 1)
              Expanded(
                child: Container(
                  height: 2,
                  color: done || active
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF2563EB)
                        : done
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: active || done
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: active
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF64748B),
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (index != 3)
              Expanded(
                child: Container(
                  height: 2,
                  color: currentStep > index
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFFE2E8F0),
                ),
              ),
          ],
        ),
      );
    }

    return Row(
      children: [
        step(1, 'Detalle'),
        step(2, 'Ubicación'),
        step(3, 'Presupuesto'),
      ],
    );
  }
}