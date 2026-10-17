/// What the payment sheet is opened with: the gateway order to collect
/// against, the key of the account it was created in, and who is paying.
class GatewayCheckout {
  const GatewayCheckout({
    required this.keyId,
    required this.orderId,
    required this.amountPaise,
    required this.merchantName,
    required this.description,
    this.contact,
    this.email,
  });

  /// The public key of the account the order was created in. The gateway
  /// looks the order up inside that account, so another account's key
  /// fails at the gateway.
  final String keyId;

  /// The gateway's order id, e.g. `order_…`.
  final String orderId;

  /// The amount in paise (rupees × 100): the only place the app deals in
  /// paise.
  final int amountPaise;
  final String merchantName;

  /// Shown on the sheet. KO's payment webhook recognises this app's orders
  /// by it, so the caller must pass the text KO expects.
  final String description;

  /// `+91XXXXXXXXXX`, to prefill the sheet; null leaves it blank.
  final String? contact;
  final String? email;
}

/// A payment the sheet reported as collected. The gateway's success says
/// the sheet closed happily; whether the money was captured is for the
/// server to confirm.
class GatewayPayment {
  const GatewayPayment({
    required this.paymentId,
    required this.orderId,
    this.signature = '',
  });

  final String paymentId;
  final String orderId;
  final String signature;
}

/// Why the sheet closed without a payment, as far as the gateway says.
/// [cancelled] and [upiTimeout] are not faults: no money moved.
enum GatewayPaymentError {
  /// The customer backed out of the sheet.
  cancelled,

  /// The gateway could not tell a cancellation from a UPI app that never
  /// answered.
  upiTimeout,
  network,
  insufficientFunds,
  incorrectOtp,
  timeout,
  invalidVpa,
  cardDeclined,
  cardExpired,
  invalidCard,
  bankDown,
  limitExceeded,

  /// The sheet could not open: a missing key, an outdated plugin, TLS.
  notConfigured,
  unknown;

  /// The customer, not the bank, ended the payment.
  bool get isCancellation => this == cancelled || this == upiTimeout;
}

/// Thrown by [PaymentGateway.collect] when no payment was collected.
class GatewayPaymentException implements Exception {
  const GatewayPaymentException(this.error, {this.detail});

  final GatewayPaymentError error;

  /// The gateway's own text, when it was short and readable; null
  /// otherwise. Never shown as it is.
  final String? detail;

  @override
  String toString() => 'GatewayPaymentException($error: $detail)';
}

/// The payment sheet. One payment at a time: a second [collect] while one
/// is open fails with [GatewayPaymentError.unknown].
abstract interface class PaymentGateway {
  /// Opens the sheet for [checkout] and completes with the payment it
  /// collected, or throws [GatewayPaymentException].
  Future<GatewayPayment> collect(GatewayCheckout checkout);
}
