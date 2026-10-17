import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/services/payments/payment_gateway.dart';
import 'package:template_app/core/services/payments/razorpay_payment_gateway.dart';

void main() {
  group('classifyRazorpayError', () {
    GatewayPaymentError errorOf({int? code, String? message}) =>
        classifyRazorpayError(code: code, message: message).error;

    test('code 2 is a cancellation, whatever the text', () {
      expect(errorOf(code: 2), GatewayPaymentError.cancelled);
      expect(
        errorOf(code: 2, message: 'Payment processing cancelled by user'),
        GatewayPaymentError.cancelled,
      );
      expect(GatewayPaymentError.cancelled.isCancellation, isTrue);
    });

    test('a cancellation that may be a UPI app not answering says so', () {
      expect(
        classifyRazorpayError(
          code: 0,
          message:
              'You may have cancelled the payment or there was a delay in '
              'response from the UPI app',
          error: const {'reason': 'payment_cancelled'},
        ).error,
        GatewayPaymentError.upiTimeout,
      );
    });

    test('code 0 without a cancellation is a network error', () {
      expect(
        errorOf(code: 0, message: 'Network error'),
        GatewayPaymentError.network,
      );
    });

    test("reads the gateway's reason out of the error object the plugin "
        'hands over', () {
      GatewayPaymentError withReason(String reason) => classifyRazorpayError(
        code: 100,
        message: 'Payment failed',
        error: {
          'code': 'BAD_REQUEST_ERROR',
          'description': 'Payment failed',
          'reason': reason,
          'step': 'payment_authorization',
        },
      ).error;

      expect(
        withReason('insufficient_funds'),
        GatewayPaymentError.insufficientFunds,
      );
      expect(withReason('incorrect_otp'), GatewayPaymentError.incorrectOtp);
      expect(withReason('payment_timeout'), GatewayPaymentError.timeout);
      expect(withReason('invalid_vpa'), GatewayPaymentError.invalidVpa);
      expect(withReason('card_declined'), GatewayPaymentError.cardDeclined);
      expect(withReason('expired_card'), GatewayPaymentError.cardExpired);
      expect(withReason('incorrect_cvv'), GatewayPaymentError.invalidCard);
      expect(withReason('gateway_error'), GatewayPaymentError.bankDown);
      expect(withReason('limit_exceeded'), GatewayPaymentError.limitExceeded);
    });

    test('reads the same reason out of a JSON envelope in the text', () {
      expect(
        errorOf(
          code: 100,
          message:
              '{"error":{"code":"BAD_REQUEST_ERROR","description":"",'
              '"reason":"insufficient_funds"}}',
        ),
        GatewayPaymentError.insufficientFunds,
      );
    });

    test('the sheet refusing to open is a configuration problem', () {
      expect(
        errorOf(code: 1, message: 'Key is required.'),
        GatewayPaymentError.notConfigured,
      );
      expect(errorOf(code: 3), GatewayPaymentError.notConfigured);
      expect(errorOf(code: 4), GatewayPaymentError.notConfigured);
    });

    test('an unknown reason keeps a short readable text, never JSON', () {
      final plain = classifyRazorpayError(
        code: 100,
        message: 'Something odd happened.',
      );
      expect(plain.error, GatewayPaymentError.unknown);
      expect(plain.detail, 'Something odd happened.');

      final json = classifyRazorpayError(
        code: 100,
        message: '{"error":{"description":"","reason":"weird"}}',
      );
      expect(json.error, GatewayPaymentError.unknown);
      expect(json.detail, isNull);

      final long = classifyRazorpayError(code: 100, message: 'x' * 200);
      expect(long.detail, isNull);
    });
  });

  test('the sheet opens with the previous app\'s options, in paise', () {
    final options = RazorpayPaymentGateway.optionsFor(
      const GatewayCheckout(
        keyId: 'rzp_live_key',
        orderId: 'order_01',
        amountPaise: 21300,
        merchantName: 'Katyayani Organics',
        description: 'Order from My Mali App',
        contact: '+919876543210',
        email: 'asha@example.com',
      ),
    );

    expect(options['key'], 'rzp_live_key');
    expect(options['order_id'], 'order_01');
    expect(options['amount'], 21300);
    expect(options['currency'], 'INR');
    expect(options['name'], 'Katyayani Organics');
    expect(options['description'], 'Order from My Mali App');
    expect(options['retry'], {'enabled': false});
    expect(options['prefill'], {
      'contact': '+919876543210',
      'email': 'asha@example.com',
    });
    expect(options['theme'], {'color': RazorpayPaymentGateway.themeColor});
  });

  test('a blank contact and email are left out of the prefill', () {
    final options = RazorpayPaymentGateway.optionsFor(
      const GatewayCheckout(
        keyId: 'k',
        orderId: 'o',
        amountPaise: 100,
        merchantName: 'm',
        description: 'd',
      ),
    );

    expect(options['prefill'], isEmpty);
  });
}
