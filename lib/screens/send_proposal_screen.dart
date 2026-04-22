import 'package:flutter/material.dart';
import '../models/proposal_request.dart';
import '../services/proposal_service.dart';

class SendProposalScreen extends StatefulWidget {
  final String serviceId;

  const SendProposalScreen({Key? key, required this.serviceId}) : super(key: key);

  @override
  State<SendProposalScreen> createState() => _SendProposalScreenState();
}

class _SendProposalScreenState extends State<SendProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  final _durationController = TextEditingController();
  
  final ProposalService _proposalService = ProposalService();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final request = ProposalRequest(
      serviceId: widget.serviceId,
      price: num.parse(_priceController.text),
      message: _messageController.text,
      estimatedDuration: _durationController.text.isEmpty ? null : _durationController.text,
    );

    try {
      await _proposalService.submitProposal(request);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propuesta enviada exitosamente')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Propuesta'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio propuesto',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa un precio';
                      }
                      if (num.tryParse(value) == null) {
                        return 'Debe ser un número válido';
                      }
                      if (num.parse(value) <= 0) {
                        return 'El precio debe ser mayor a 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duración estimada (opcional)',
                      border: OutlineInputBorder(),
                      hintText: 'Ej. 2 horas, 1 día',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje al cliente',
                      border: OutlineInputBorder(),
                      hintText: 'Explica por qué eres el mejor para el trabajo...',
                    ),
                    maxLines: 5,
                    maxLength: 500,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa un mensaje';
                      }
                      if (value.length < 20) {
                        return 'El mensaje debe tener al menos 20 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Enviar Propuesta', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
