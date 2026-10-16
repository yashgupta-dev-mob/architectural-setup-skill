/// The names of the events the app reports through `AnalyticsService.track`.
///
/// They are the React Native app's `AppEvents` (`services/analytics/events.ts`)
/// word for word, so both apps feed the same Katyayani Core dashboards. Add a
/// name here before using it; never type an event name at a call site.
abstract final class AppEvents {
  // Sign-in and profile.
  static const String loginStarted = 'Login Started';
  static const String login = 'Login';
  static const String otpSent = 'OTP Sent';
  static const String otpResent = 'OTP Resent';
  static const String otpError = 'OTP Error';
  static const String verified = 'Verified';
  static const String profileUpdate = 'Profile Update';
  static const String logout = 'Logout';

  // Navigation.
  static const String navBarIconTapped = 'Nav Bar Icon Tapped';
  static const String screenLoad = 'Screen Load';

  // Cart.
  static const String addToCart = 'Added To Cart';
  static const String removeFromCart = 'Removed From Cart';
  static const String cartVisit = 'Cart Visit';
  static const String productSavedForLater = 'Product Saved For Later';
  static const String productMovedToCart = 'Product Moved To Cart';

  // Wishlist.
  static const String addToFavorite = 'Added To Favorite';
  static const String removeFromFavorite = 'Removed From Favorite';

  // Catalog.
  static const String productView = 'Product View';
  static const String productQuantityChanged = 'Product Quantity Changed';
  static const String productVariantChanged = 'Product Variant Changed';
  static const String viewedAllProducts = 'Viewed All Products';
  static const String categoryIconTapped = 'Category Icon Tapped';
  static const String productSearch = 'Product Search';
  static const String searchResultTapped = 'Search Result Tapped';
  static const String searchNoResults = 'Search No Results';
  static const String cameraSearchTapped = 'Camera Search Tapped';
  static const String filterApplied = 'Filter Applied';
  static const String notifyMeTapped = 'Notify Me Tapped';
  static const String bannerClicked = 'Banner Clicked';

  // Coupons.
  static const String couponApplyTapped = 'Coupon Apply Tapped';
  static const String couponApplied = 'Coupon Applied';
  static const String couponRemoved = 'Coupon Removed';

  // Checkout.
  static const String checkoutStepViewed = 'Checkout Step Viewed';
  static const String checkoutStarted = 'Checkout Started';
  static const String paymentStarted = 'Payment Started';
  static const String paymentSuccessful = 'Payment Successful';
  static const String paymentUnsuccessful = 'Payment Unsuccessful';
  static const String paymentCancelled = 'Payment Cancelled';
  static const String processingOrder = 'Processing Order';
  static const String orderUnsuccessful = 'Order Unsuccessful';
  static const String orderPlaced = 'Order Placed';

  // Addresses.
  static const String changeAddressTapped = 'Change Address Tapped';
  static const String addressChanged = 'Address Changed';
  static const String editAddressTapped = 'Edit Address Tapped';
  static const String addAddressTapped = 'Add Address Tapped';
  static const String addressAdded = 'Address Added';

  // Garden.
  static const String gardenWaitlistJoined = 'Garden Waitlist Joined';

  // Referral.
  static const String referralCodeShared = 'Referral Code Shared';
  static const String referralCodeClaimed = 'Referral Code Claimed';
  static const String referralClaimFailed = 'Referral Claim Failed';

  // Support.
  static const String supportChannelTapped = 'Support Channel Tapped';
  static const String callButtonTapped = 'Call Button Tapped';

  // Orders.
  static const String orderOpened = 'Order Opened';
  static const String orderFilterChanged = 'Order Filter Changed';
  static const String buyAgainTapped = 'Buy Again Tapped';
  static const String invoiceDownloaded = 'Invoice Downloaded';
  static const String orderHelpTapped = 'Order Help Tapped';
  static const String orderRated = 'Order Rated';

  // Account.
  static const String accountMenuTapped = 'Account Menu Item Tapped';
  static const String avatarUpdated = 'Avatar Updated';
  static const String editProfileTapped = 'Edit Profile Tapped';
  static const String themeChanged = 'Theme Changed';
}
