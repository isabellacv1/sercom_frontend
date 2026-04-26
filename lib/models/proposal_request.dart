class ProposalRequest {
  final String serviceId;
  final num price;
  final String message;
  final String availableDate;
  final String availableFrom;
  final String availableTo;

  ProposalRequest({
    required this.serviceId,
    required this.price,
    required this.message,
    required this.availableDate,
    required this.availableFrom,
    required this.availableTo,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'price': price,
      'message': message,
      'available_date': availableDate,
      'available_from': availableFrom,
      'available_to': availableTo,
    };
  }
}
