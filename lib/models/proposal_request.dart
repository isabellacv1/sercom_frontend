class ProposalRequest {
  final String serviceId;
  final num price;
  final String message;
  final String? estimatedDuration;

  ProposalRequest({
    required this.serviceId,
    required this.price,
    required this.message,
    this.estimatedDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'price': price,
      'message': message,
      if (estimatedDuration != null && estimatedDuration!.isNotEmpty)
        'estimated_duration': estimatedDuration,
    };
  }
}
