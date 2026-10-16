import 'app_events.dart';

/// One event as Google Analytics 4 (Firebase Analytics) takes it.
class Ga4Event {
  const Ga4Event(this.name, this.parameters);

  final String name;
  final Map<String, Object> parameters;
}

/// One event as Meta (Facebook) App Events takes it.
class MetaEvent {
  const MetaEvent(
    this.name,
    this.parameters, {
    this.valueToSum,
    this.isPurchase = false,
    this.currency = defaultCurrency,
  });

  /// Meta's standard event name where there is one, else the app's own.
  final String name;
  final Map<String, Object> parameters;

  /// The money (or rating) the event carries. Meta reads it as the
  /// `valueToSum` argument; a `_valueToSum` parameter key is ignored.
  final double? valueToSum;

  /// Whether it is sent with `logPurchase`, which logs Meta's standard
  /// Purchase with its revenue. The only event that is.
  final bool isPurchase;
  final String currency;
}

const String defaultCurrency = 'INR';

/// GA4's own names for the events it has a recommended event for; GA4 only
/// builds its ecommerce reports from these exact names. Anything else gets
/// its name derived by [ga4NameFor].
const Map<String, String> _ga4Names = {
  AppEvents.login: 'login_completed',
  AppEvents.verified: 'login',
  AppEvents.addToCart: 'add_to_cart',
  AppEvents.removeFromCart: 'remove_from_cart',
  AppEvents.addToFavorite: 'add_to_wishlist',
  AppEvents.productView: 'view_item',
  AppEvents.productSearch: 'search',
  AppEvents.checkoutStarted: 'begin_checkout',
  AppEvents.paymentStarted: 'add_payment_info',
  AppEvents.orderPlaced: 'purchase',
  AppEvents.orderRated: 'order_rated',
};

/// Meta's standard names for the events it has one for. Meta optimises ads
/// and builds audiences only from its standard events. "Order Placed" is not
/// here on purpose: it goes through `logPurchase`, and mapping it as well
/// would log Purchase twice.
const Map<String, String> _metaStandardNames = {
  AppEvents.verified: 'fb_mobile_complete_registration',
  AppEvents.addToCart: 'fb_mobile_add_to_cart',
  AppEvents.addToFavorite: 'fb_mobile_add_to_wishlist',
  AppEvents.productView: 'fb_mobile_content_view',
  AppEvents.productSearch: 'fb_mobile_search',
  AppEvents.checkoutStarted: 'fb_mobile_initiated_checkout',
  AppEvents.paymentStarted: 'fb_mobile_add_payment_info',
  AppEvents.orderRated: 'fb_mobile_rate',
};

const int _maxNameLength = 40;
const int _maxValueLength = 100;
const int _maxRating = 5;

/// GA4's name for [eventName]: lowercase snake_case, at most 40 characters,
/// no spaces ("Added To Cart" becomes `added_to_cart`).
String ga4NameFor(String eventName) =>
    _ga4Names[eventName] ?? _snake(eventName);

/// [eventName] as GA4 takes it, with its parameters cleaned: snake_case keys,
/// text cut to 100 characters, only text and numbers, no nulls. When the
/// event carries `value` or `amount`, GA4 also gets `value` and `currency`.
Ga4Event ga4EventFor(String eventName, Map<String, Object?>? properties) {
  final parameters = <String, Object>{};
  _scalars(properties).forEach((key, value) {
    final name = _snake(key);
    if (name.isEmpty) return;
    parameters[name] = value is String && value.length > _maxValueLength
        ? value.substring(0, _maxValueLength)
        : value;
  });
  final money = _moneyOf(properties);
  if (money != null) {
    parameters['value'] = money;
    parameters['currency'] = _currencyOf(properties);
  }
  return Ga4Event(ga4NameFor(eventName), parameters);
}

/// [eventName] as Meta takes it: its standard name where it has one, the
/// money as `valueToSum`, and the product and special-case parameters the
/// standard events ask for.
MetaEvent metaEventFor(String eventName, Map<String, Object?>? properties) {
  final standard = _metaStandardNames[eventName];
  final name = _clip(standard ?? eventName);
  final parameters = <String, Object>{..._scalars(properties)};
  final currency = _currencyOf(properties);
  double? valueToSum = _moneyOf(properties);

  if (valueToSum != null) parameters['fb_currency'] = currency;

  final itemId = properties?['item_id'];
  if (itemId is String || itemId is num) {
    parameters['fb_content_id'] = '$itemId';
    parameters['fb_content_type'] = 'product';
  }

  switch (eventName) {
    case AppEvents.productSearch:
      final term = properties?['search_term'];
      if (term is String) parameters['fb_search_string'] = term;
    case AppEvents.orderRated:
      parameters['fb_max_rating_value'] = _maxRating;
      final rating = properties?['rating'];
      if (rating is num) valueToSum = rating.toDouble();
      parameters['fb_content_type'] = 'order';
    case AppEvents.paymentStarted:
      parameters['fb_success'] = 1;
  }

  if (eventName == AppEvents.orderPlaced) {
    return MetaEvent(
      name,
      parameters,
      valueToSum: valueToSum ?? 0,
      isPurchase: true,
      currency: currency,
    );
  }
  return MetaEvent(
    name,
    parameters,
    valueToSum: valueToSum,
    currency: currency,
  );
}

/// The text and numbers in [properties]. Booleans become 1 and 0, a list of
/// them is joined with commas, and nulls and anything else are left out.
Map<String, Object> _scalars(Map<String, Object?>? properties) {
  final out = <String, Object>{};
  if (properties == null) return out;
  properties.forEach((key, value) {
    final scalar = _scalar(value);
    if (scalar != null) {
      out[key] = scalar;
    } else if (value is Iterable) {
      final parts = [for (final item in value) ?_scalar(item)];
      if (parts.isNotEmpty) out[key] = parts.join(',');
    }
  });
  return out;
}

Object? _scalar(Object? value) => switch (value) {
  String() || num() => value,
  bool() => value ? 1 : 0,
  _ => null,
};

double? _moneyOf(Map<String, Object?>? properties) {
  final raw = properties?['value'] ?? properties?['amount'];
  return raw is num ? raw.toDouble() : null;
}

String _currencyOf(Map<String, Object?>? properties) {
  final raw = properties?['currency'];
  return raw is String && raw.isNotEmpty ? raw : defaultCurrency;
}

String _snake(String text) => _clip(
  text
      .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp('^_+|_+\$'), ''),
);

String _clip(String text) =>
    text.length > _maxNameLength ? text.substring(0, _maxNameLength) : text;
