import '../core/api_client.dart';

class MercadoPagoLink {
  final String paymentId;
  final String checkoutUrl;
  final String status;

  MercadoPagoLink({
    required this.paymentId,
    required this.checkoutUrl,
    required this.status,
  });

  factory MercadoPagoLink.fromJson(Map<String, dynamic> json) {
    return MercadoPagoLink(
      paymentId: json['payment_id']?.toString() ??
          json['paymentId']?.toString() ??
          json['id']?.toString() ??
          '',
      checkoutUrl: json['checkout_url']?.toString() ??
          json['checkoutUrl']?.toString() ??
          json['init_point']?.toString() ??
          json['url']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

class PaymentService {
  final _dio = ApiClient().dio;

  Future<MercadoPagoLink> createMercadoPagoLink(String serviceId) async {
    try {
      final response = await _dio.post(
        '/payments/mercadopago/link',
        data: {
          'service_id': serviceId,
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Respuesta inválida del servidor');
      }

      final link = MercadoPagoLink.fromJson(data);

      if (link.checkoutUrl.isEmpty) {
        throw Exception('El backend no devolvió el link de Mercado Pago');
      }

      return link;
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<MercadoPagoLink?> findByService(String serviceId) async {
    try {
      final response = await _dio.get('/payments/service/$serviceId');
      final data = response.data;

      if (data == null) return null;

      if (data is! Map<String, dynamic>) {
        throw Exception('Respuesta inválida del servidor');
      }

      return MercadoPagoLink.fromJson(data);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(Object error) {
    final dynamic e = error;

    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    return error.toString().replaceAll('Exception: ', '');
  }
}