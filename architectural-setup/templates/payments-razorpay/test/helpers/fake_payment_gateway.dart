import 'dart:async';

import 'package:template_app/core/services/payments/payment_gateway.dart';

/// In-memory [PaymentGateway] for tests: the sheet reports [payment], or
/// throws [error] when set; [gate] holds the sheet open. Every opening is
/// recorded in [checkouts].
class FakePaymentGateway implements PaymentGateway {
  GatewayPayment payment = const GatewayPayment(
    paymentId: 'pay_01',
    orderId: 'order_01',
    signature: 'sig_01',
  );
  GatewayPaymentException? error;
  Completer<void>? gate;

  final List<GatewayCheckout> checkouts = [];

  GatewayCheckout get lastCheckout => checkouts.last;

  @override
  Future<GatewayPayment> collect(GatewayCheckout checkout) async {
    checkouts.add(checkout);
    await gate?.future;
    final error = this.error;
    if (error != null) throw error;
    return payment;
  }
}
