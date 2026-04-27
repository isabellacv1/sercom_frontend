import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/proposal_request.dart';
import '../services/proposal_repository.dart';

class PostulationFormSheet extends StatefulWidget {
  final String serviceId;

  const PostulationFormSheet({Key? key, required this.serviceId}) : super(key: key);

  @override
  State<PostulationFormSheet> createState() => _PostulationFormSheetState();
}

class _PostulationFormSheetState extends State<PostulationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final ProposalRepository _repository = ProposalRepository();
  bool _isLoading = false;
  String? _timeError;

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3366E8), // Primary blue
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _validateTimeRange();
      });
    }
  }

  void _validateTimeRange() {
    if (_startTime != null && _endTime != null) {
      final startMin = _startTime!.hour * 60 + _startTime!.minute;
      final endMin = _endTime!.hour * 60 + _endTime!.minute;
      
      if (endMin <= startMin) {
        _timeError = 'La hora de fin debe ser posterior a la de inicio';
      } else {
        _timeError = null;
      }
    } else {
      _timeError = null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa la fecha y franja horaria'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    _validateTimeRange();
    if (_timeError != null) return;

    setState(() {
      _isLoading = true;
    });

    final request = ProposalRequest(
      serviceId: widget.serviceId,
      price: num.parse(_priceController.text),
      message: _messageController.text,
      availableDate: _selectedDate!.toIso8601String().split('T').first,
      availableFrom: '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
      availableTo: '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
    );

    try {
      await _repository.submitProposal(request);
      
      if (!mounted) return;
      
      Navigator.pop(context, true); // Close the BottomSheet and return true
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '¡Propuesta enviada con éxito!',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981), // Green success
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      
      if (errorMsg.contains('Ya te has postulado')) {
        Navigator.pop(context, true); // Close and return true to mark as postulated
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: const Color(0xFFEF4444), // Red error
          behavior: SnackBarBehavior.floating,
        ),
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
  Widget build(BuildContext context) {
    final textDark = const Color(0xFF101828);
    final textSoft = const Color(0xFF6B7A99);
    final borderColor = const Color(0xFFD9DEE8);
    final orangeColor = const Color(0xFFFF8A00);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Tu Propuesta',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'El cliente revisará tu oferta y perfil.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: textSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oferta Económica',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
                decoration: InputDecoration(
                  prefixText: 'COP \$ ',
                  prefixStyle: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textSoft,
                  ),
                  hintText: '0.00',
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'El precio es requerido';
                  final numVal = num.tryParse(value);
                  if (numVal == null || numVal <= 0) return 'El precio debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Alcance y Condiciones',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                maxLength: 500,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  color: textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Detalla tu servicio, materiales incluidos y condiciones...',
                  hintStyle: GoogleFonts.montserrat(color: textSoft),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 20) {
                    return 'Describe tu oferta con al menos 20 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Disponibilidad',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFF3366E8)),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? 'Selecciona una fecha'
                            : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: _selectedDate == null ? FontWeight.w500 : FontWeight.w600,
                          color: _selectedDate == null ? textSoft : textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(true),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(16),
                          border: _timeError != null ? Border.all(color: Colors.red.shade300) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Desde',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: textSoft,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _startTime?.format(context) ?? '--:--',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(false),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(16),
                          border: _timeError != null ? Border.all(color: Colors.red.shade300) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hasta',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: textSoft,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _endTime?.format(context) ?? '--:--',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_timeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    _timeError!,
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFFEF4444),
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Enviar Propuesta',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
}
