import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'payment_gateway.dart';

/// The Razorpay checkout sheet. The only file that imports
/// `razorpay_flutter`.
///
/// The SDK reports through events, so each [collect] registers the three
/// handlers, opens the sheet and completes with the first event, then
/// clears them. The sheet owns the screen while it is up; it has its own
/// back and close.
class RazorpayPaymentGateway implements PaymentGateway {
  RazorpayPaymentGateway({Razorpay Function()? newSdk})
    : _newSdk = newSdk ?? Razorpay.new;

  final Razorpay Function() _newSdk;
  Completer<GatewayPayment>? _inFlight;

  /// The brand colour of the sheet, Razorpay's own default otherwise.
  static const String themeColor = '#225542';

  @override
  Future<GatewayPayment> collect(GatewayCheckout checkout) {
    if (_inFlight != null) {
      return Future.error(
        const GatewayPaymentException(
          GatewayPaymentError.unknown,
          detail: 'A payment is already open.',
        ),
      );
    }
    final completer = _inFlight = Completer<GatewayPayment>();
    final sdk = _newSdk();

    void finish(void Function() complete) {
      sdk.clear();
      _inFlight = null;
      if (!completer.isCompleted) complete();
    }

    sdk
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
        final paymentId = response.paymentId ?? '';
        if (paymentId.isEmpty) {
          finish(
            () => completer.completeError(
              const GatewayPaymentException(
                GatewayPaymentError.unknown,
                detail: 'The sheet closed without a payment id.',
              ),
            ),
          );
          return;
        }
        _trace('paid $paymentId for ${checkout.orderId}');
        finish(
          () => completer.complete(
            GatewayPayment(
              paymentId: paymentId,
              orderId: response.orderId ?? checkout.orderId,
              signature: response.signature ?? '',
            ),
          ),
        );
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        final failure = classifyRazorpayError(
          code: response.code,
          message: response.message,
          error: response.error,
        );
        // Everything Razorpay said: the code, its text and the gateway's
        // error object (`reason`, `step`, `source`, `metadata`). The
        // customer is shown only the classified message.
        _trace(
          '${failure.error.isCancellation ? "cancelled" : "FAILED"} for '
          '${checkout.orderId} → ${failure.error.name}\n'
          '  code: ${response.code}\n'
          '  message: ${response.message}\n'
          '  error: ${response.error}',
        );
        finish(() => completer.completeError(failure));
      })
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        // The customer chose a wallet the sheet hands off to; Razorpay
        // reports no payment for it, so none is confirmed here.
        _trace('external wallet ${response.walletName}');
        finish(
          () => completer.completeError(
            const GatewayPaymentException(
              GatewayPaymentError.unknown,
              detail: 'The payment moved to an external wallet.',
            ),
          ),
        );
      });

    _trace(
      'opening ${checkout.orderId} for ₹'
      '${(checkout.amountPaise / 100).toStringAsFixed(2)} '
      'with key ${_keyLabel(checkout.keyId)}',
    );
    sdk.open(optionsFor(checkout));
    return completer.future;
  }

  /// The key's mode and first characters: enough to tell a test key from a
  /// live one, or one account's key from another's. A key id is public
  /// (it ships in the app), but the whole of it is not needed here.
  static String _keyLabel(String keyId) {
    final mode = keyId.startsWith('rzp_test_')
        ? 'TEST'
        : keyId.startsWith('rzp_live_')
        ? 'LIVE'
        : 'UNKNOWN';
    final head = keyId.length > 14 ? '${keyId.substring(0, 14)}…' : keyId;
    return '$head ($mode)';
  }

  /// Writes to the console in debug builds, so a payment that goes wrong
  /// can be read with `adb logcat -s flutter` (`dart:developer`'s `log`
  /// reaches only an attached debugger). Silent in release.
  static void _trace(String message) {
    if (kDebugMode) debugPrint('[razorpay] $message');
  }

  /// The SDK's options, as the previous app opens its sheet: no retry
  /// inside the sheet, the brand colour, the customer prefilled.
  static Map<String, dynamic> optionsFor(GatewayCheckout checkout) => {
    'key': checkout.keyId,
    'order_id': checkout.orderId,
    'amount': checkout.amountPaise,
    'currency': 'INR',
    'name': checkout.merchantName,
    'description': checkout.description,
    'retry': {'enabled': false},
    'theme': {'color': themeColor},
    'prefill': {'contact': ?checkout.contact, 'email': ?checkout.email},
  };
}

/// What a Razorpay failure means, read the previous app's way
/// (`paymentErrors.ts`): a cancellation first (code 2, or "cancel" in the
/// text), then the network code, then the gateway's own `reason` or
/// description. The plugin hands the gateway's error object over as
/// [error] (`{ "code", "description", "reason", "step", … }`) with its
/// description as [message]; an older build sends the whole envelope as
/// JSON text in [message] instead, so both are read.
GatewayPaymentException classifyRazorpayError({
  int? code,
  String? message,
  Map<dynamic, dynamic>? error,
}) {
  final raw = (message ?? '').trim();
  Map<dynamic, dynamic> inner = error ?? const {};
  if (inner.isEmpty && raw.startsWith('{')) {
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        final nested = parsed['error'];
        inner = nested is Map<String, dynamic> ? nested : parsed;
      }
    } on FormatException {
      // Not JSON after all: read the text as it is.
    }
  }
  final reason = '${inner['reason'] ?? ''}';
  final description = '${inner['description'] ?? ''}';
  final text = '$reason $description $raw';

  bool has(String pattern) =>
      RegExp(pattern, caseSensitive: false).hasMatch(text);

  if (code == Razorpay.PAYMENT_CANCELLED ||
      has('cancel|dismiss|user_cancel|back')) {
    // Razorpay's own text for this case is "You may have cancelled the
    // payment or there was a delay in response from the UPI app".
    return GatewayPaymentException(
      has('delay in response|upi app')
          ? GatewayPaymentError.upiTimeout
          : GatewayPaymentError.cancelled,
    );
  }
  if (code == Razorpay.NETWORK_ERROR) {
    return const GatewayPaymentException(GatewayPaymentError.network);
  }
  if (code == Razorpay.INVALID_OPTIONS ||
      code == Razorpay.TLS_ERROR ||
      code == Razorpay.INCOMPATIBLE_PLUGIN) {
    return GatewayPaymentException(
      GatewayPaymentError.notConfigured,
      detail: _readable(raw),
    );
  }

  for (final (pattern, error) in _reasons) {
    if (has(pattern)) return GatewayPaymentException(error);
  }
  return GatewayPaymentException(
    GatewayPaymentError.unknown,
    detail: _readable(description.isNotEmpty ? description : raw),
  );
}

/// The gateway's text when it is short, plain and not JSON.
String? _readable(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || trimmed.startsWith('{') || trimmed.length >= 160) {
    return null;
  }
  return trimmed;
}

const List<(String, GatewayPaymentError)> _reasons = [
  (
    r'insufficient[_ ]funds|insufficient balance',
    GatewayPaymentError.insufficientFunds,
  ),
  (
    r'incorrect[_ ]otp|invalid[_ ]otp|otp[_ ]failed',
    GatewayPaymentError.incorrectOtp,
  ),
  (r'payment[_ ]timeout|timed[_ ]out|timeout', GatewayPaymentError.timeout),
  (r'invalid[_ ]vpa|vpa|upi[_ ]id', GatewayPaymentError.invalidVpa),
  (
    r'card[_ ]declined|declined by (the )?bank|do not honou?r|transaction not permitted',
    GatewayPaymentError.cardDeclined,
  ),
  (r'expired[_ ]card|card[_ ]expired', GatewayPaymentError.cardExpired),
  (
    r'incorrect[_ ]cvv|invalid[_ ]cvv|incorrect[_ ]card|invalid[_ ]card',
    GatewayPaymentError.invalidCard,
  ),
  (
    r'gateway[_ ]error|bank[_ ]?(is )?down|issuer[_ ]down|server[_ ]error|internal[_ ]error',
    GatewayPaymentError.bankDown,
  ),
  (r'limit[_ ]exceeded|exceeds', GatewayPaymentError.limitExceeded),
  (r'network|internet|connection|unreachable', GatewayPaymentError.network),
];
