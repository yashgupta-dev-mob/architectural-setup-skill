# Inventory — theme-and-widgets

Repo: `C:/Users/Katyayani/Documents/flutter/mymali` (package name `mymali`). Area: `lib/core/theme/**`, `lib/core/widgets/**`, plus the two files the widgets import from outside the area (`lib/core/utils/currency_format.dart`, `lib/core/assets/app_assets.dart`) and the text-scale clamp in `lib/app/app.dart`. Every file below was read in full; every test under `test/core/widgets/**` was read in full. `dart analyze lib/core/widgets lib/core/theme` reports 0 errors, 2 warnings (both in the legacy `rich_text.dart`) and 33 infos (listed under Gotchas).

Toolchain the code assumes (from `pubspec.yaml`): `environment: sdk: ^3.13.4`, `flutter_lints: ^6.0.0`, `include: package:flutter_lints/flutter.yaml` with no extra rules. The code uses `Color.withValues(alpha:)`, `Color.a`, `Row(spacing:)`, `Column(spacing:)`, null-aware collection elements (`[?clearButton, trailing]`), `if (icon case final icon?)`, `DropdownButtonFormField(initialValue:)`, `Switch.adaptive(activeThumbColor:)`, `MediaQuery.textScalerOf`, `MediaQuery.withClampedTextScaling`, `Visibility.maintain`, `Icon(weight:)`. A target app must be on a Flutter/Dart at least that new.

Classification key used below: **ALWAYS** = generic architecture, install in every app (placeholders listed); **CONDITIONAL(x)** = install only when the target app has capability x; **MYMALI-SPECIFIC** = MyMali business/legacy, do not install by default.

---

## 1. Files

| Path | Role (one line) | Class | Placeholders another app substitutes |
|---|---|---|---|
| `lib/core/theme/app_colors.dart` | `abstract final class AppColors`: every brand colour as `static const Color`; the only file allowed to hold hex values | ALWAYS | every hex value; the brand-flavoured member names (`forest*`, `mist`, `peach`, `coral`, `coinGold`, `sky`, `apricot`, `star`) may be kept (only `AppTheme`/`AppTones` reference them) |
| `lib/core/theme/app_theme.dart` | `abstract final class AppTheme`: `light`/`dark` `ThemeData` via `_build(AppTones, ColorScheme)`; `fontSizeFactor`, `displayFontFamily` | ALWAYS | the `ColorScheme.fromSeed` overrides, `fontSizeFactor = 0.88`, `displayFontFamily = 'Marcellus'` (+ `pubspec.yaml` font entry `assets/fonts/Marcellus-Regular.ttf`) |
| `lib/core/theme/app_tones.dart` | `AppTones extends ThemeExtension<AppTones>`: `success`, `info`, `warning`, `rating`; `AppTones.of(context)` | ALWAYS | the four values per theme (`light`/`dark` statics) |
| `lib/core/assets/app_assets.dart` (outside area, imported by `AppLogo`) | `abstract final class AppAssets`: every asset path | ALWAYS | `icon = 'assets/icon.png'`, `appLogo = 'assets/applogo.png'`; `coin = 'assets/coin.png'` is MYMALI-SPECIFIC |
| `lib/core/utils/currency_format.dart` (outside area, imported by `product_card`, `product_list_tile`, `order_line_tile`) | `String formatRupees(num amount)` over `NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)` | CONDITIONAL(app shows prices) | locale `en_IN`, symbol `₹`, 0 decimals; the function name itself encodes INR |
| `lib/app/app.dart` (outside area; theme wiring only) | `App.maxTextScaleFactor = 1.1`; `MaterialApp.router(theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: …, builder: MediaQuery.withClampedTextScaling(maxScaleFactor: …))` | ALWAYS (the three lines quoted in Patterns) | `1.1`; `title: 'MyMali'`; the `ThemeBloc` that supplies `themeMode` is a feature |
| `lib/core/widgets/app_card.dart` | `AppCard`: rounded outlined surface, optional header row, optional accent strip; `AppCard.radius`, `AppCard.divider(context)` | ALWAYS | none |
| `lib/core/widgets/app_logo.dart` | `AppLogo`: bundled brand image decoded at display size | ALWAYS | default `asset = AppAssets.icon`, `semanticLabel = 'My Mali'` |
| `lib/core/widgets/app_network_image.dart` | `AppNetworkImage`: the only `cached_network_image` import; themed placeholder; decodes at drawn size | CONDITIONAL(app shows network images) | default `placeholderIcon = Icons.image_outlined` |
| `lib/core/widgets/page_header.dart` | `PageHeader`: tinted round-bottomed page app bar; `contentHeightFor(context)` | ALWAYS | `backTooltip = 'Back'` |
| `lib/core/widgets/icon_list_tile.dart` | `IconListTile` + `enum IconListTileLeading`: tappable icon row for lists/menus | ALWAYS | none (doc comment mentions `orders@getmymali.com`) |
| `lib/core/widgets/form_section_title.dart` | `FormSectionTitle`: heading of one group of fields | ALWAYS | none |
| `lib/core/widgets/section_header.dart` | `SectionHeader`: serif section title + "View All →" pill | ALWAYS | none |
| `lib/core/widgets/section_label.dart` | `SectionLabel`: uppercase caption with accent bar | ALWAYS | none |
| `lib/core/widgets/reload_widget.dart` | `ReloadWidget`: centred error + retry `IconButton` (`Key('reload_button')`) | ALWAYS | tooltip `'Retry'` |
| `lib/core/widgets/progress_indecator.dart` | `ProgressIndecator` (sic): platform spinner (`dart:io Platform.isIOS` → Cupertino) | ALWAYS (mobile only: `dart:io`) | none; keep the misspelt name |
| `lib/core/widgets/rich_text.dart` | `RichMessageText`: markdown-ish chat text with tappable links (`url_launcher`) | MYMALI-SPECIFIC (legacy leftover, AGENTS §16; unused in `lib/`; analyzer warnings) | — |
| `lib/core/widgets/buttons/primary_button.dart` | `PrimaryButton`: the primary CTA; loading dots; `icon` badge; `warm` | ALWAYS | none |
| `lib/core/widgets/buttons/secondary_button.dart` | `SecondaryButton`: outline pill; `warm`, `destructive`, `leadingIcon` | ALWAYS | none |
| `lib/core/widgets/buttons/circle_icon_button.dart` | `CircleIconButton`: round icon button; `filled`, `accent`, `badgeCount` | ALWAYS | none |
| `lib/core/widgets/buttons/heart_toggle_button.dart` | `HeartToggleButton`: wishlist heart | CONDITIONAL(app has favourites/wishlist) | none |
| `lib/core/widgets/buttons/slide_action_button.dart` | `SlideActionButton` (stateful): drag-to-confirm pill with chevron hint; `completeAt` | CONDITIONAL(app has a confirm-by-slide action, e.g. checkout) | none |
| `lib/core/widgets/buttons/dashed_outline_button.dart` | `DashedOutlineButton`: dashed "+ Add new …" | ALWAYS | default `icon = Icons.add_rounded` |
| `lib/core/widgets/buttons/add_button.dart` | `AddButton`: small "ADD +" | CONDITIONAL(app has a cart) | `label = 'ADD'` |
| `lib/core/widgets/chips/info_chip.dart` | `InfoChip` + `enum InfoChipTone`; `InfoChip.heightFor(context)` | ALWAYS | none |
| `lib/core/widgets/chips/category_chip.dart` | `CategoryChip` (stateful): icon tile + caption; `defaultWidth`, `heightFor(context)` | CONDITIONAL(app has a category strip/rail) | none |
| `lib/core/widgets/chips/filter_chip_button.dart` | `FilterChipButton`: pill trigger / selectable chip / header tab | ALWAYS | none |
| `lib/core/widgets/sheets/app_info_sheet.dart` | `AppInfoSheet` + `enum AppInfoSheetTone`; `show`, `actionKey`, `closeKey`, `defaultActionLabel` | ALWAYS | `defaultActionLabel = 'Got it'`, close tooltip `'Close'` |
| `lib/core/widgets/sheets/app_picker_sheet.dart` | `AppPickerSheet`; `show<T>`, `closeKey` | ALWAYS | close tooltip `'Close'` |
| `lib/core/widgets/sheets/option_tile.dart` | `OptionTile`: pick-exactly-one row with radio mark | ALWAYS | none |
| `lib/core/widgets/search/app_search_bar.dart` | `AppSearchBar`: typed search built on `UniversalFormField(UFFType.search)` | CONDITIONAL(app has a search input) | `hintText = 'Search'`; hard-coded `label: 'products'` |
| `lib/core/widgets/search/search_trigger_bar.dart` | `SearchTriggerBar`: looks like a search field, only opens a screen; optional camera | CONDITIONAL(app opens a search screen from a bar) | `hintText = 'Search'`, `cameraTooltip = 'Search with a photo'` |
| `lib/core/widgets/cart/cart_summary_bar.dart` | `CartSummaryBar`: floating "View cart · N ITEMS" pill; `height`, `maxThumbnails` | CONDITIONAL(app has a cart) | `label = 'View cart'`, `'1 ITEM'`/`'N ITEMS'`, placeholder `Icons.eco_outlined` |
| `lib/core/widgets/product/product_card.dart` | `ProductCard`: grid/rail tile; `detailsHeightFor(context)`, `compactWidth` | CONDITIONAL(app lists products) | texts `'In Stock'`, `'Few left'`, `'Out of stock'`, `'Coming soon'`, `'$n% OFF'`, `'$n sold'`, `'MRP ₹…'`; `formatRupees` |
| `lib/core/widgets/product/product_list_tile.dart` | `ProductListTile` + `enum ProductListTileControl`; `thumbnailSize` | CONDITIONAL(app lists products / has a cart) | `addLabel = 'Add to cart'`, `'Out of stock'`, `'Coming soon'`, `addIcon = Icons.shopping_bag_outlined`, `keyPrefix = 'product'` |
| `lib/core/widgets/product/product_grid.dart` | `ProductGrid`, `SliverProductGrid`; `spacing`, `tileWidthFor`, `tileHeightFor` | CONDITIONAL(app lists products) | none |
| `lib/core/widgets/product/product_rail.dart` | `ProductRail`; `trailingWidthFactor` | CONDITIONAL(app lists products) | none |
| `lib/core/widgets/product/explore_more_card.dart` | `ExploreMoreCard`; `maxThumbnails` | CONDITIONAL(app lists products) | `label = 'Explore more'`, placeholder `Icons.eco_outlined` |
| `lib/core/widgets/product/order_line_tile.dart` | `OrderLineTile`: one line of a placed order | CONDITIONAL(app shows placed orders) | `'$quantity × ₹…'`, placeholder `Icons.eco_outlined` |
| `lib/core/widgets/product/quantity_stepper.dart` | `QuantityStepper`: "− n +"; `filled`, `removeAtOne`, `caption` | CONDITIONAL(app has line quantities / a cart) | semantics `'Remove'`, `'Decrease quantity'`, `'Increase quantity'` |
| `lib/core/widgets/form_helper/universal_form_field.dart` | `UniversalFormField` (plain class with `Widget build({…configs})`): the one entry point for every input | ALWAYS | phone default country `"IN"`; date/time hard-coded labels `'Birth Date'`/`'Select date'`, `'Meeting Time'`/`'Select time'` |
| `lib/core/widgets/form_helper/field_config.dart` | `enum UFFType` + every `*Config` class, `DropdownOption`, `ChoiceChipOption`, `TextInputFieldType`, `WidgetOrder`, `MessageType` | ALWAYS (whole file; several members are dead but hold the enum order) | none; `ChatTextBoxConfig`/`MessageType` are CRM leftovers (see Open questions) |
| `lib/core/widgets/form_helper/field_title.dart` | `FieldTitle`: uppercase caption shown by `withTitle` | ALWAYS | none |
| `lib/core/widgets/form_helper/decorator/field_decorator.dart` | `FieldDecorator extends InputDecoration`: the one look of text/phone/dropdown/chip fields; `iconTile` | ALWAYS | none |
| `lib/core/widgets/form_helper/fields/custom_text_form_field.dart` | `CustomTextFormField` (stateful): `UFFType.text` | ALWAYS | none |
| `lib/core/widgets/form_helper/fields/phone_text_form_field.dart` | `PhoneTextFormField` (stateful): `UFFType.phone`; `intl_phone_field` or locked dial-code prefix | CONDITIONAL(app takes phone numbers) | fallback country `'IN'` |
| `lib/core/widgets/form_helper/fields/otp_input_field.dart` | `OtpInputField` (stateful): `UFFType.otp` digit boxes over an invisible `TextField` | CONDITIONAL(app has OTP) | none |
| `lib/core/widgets/form_helper/fields/custom_search_field.dart` | `CustomSearchBar` (stateful): `UFFType.search`, debounced | CONDITIONAL(app has a search input) | hint fallback `'Search ${label}...'` |
| `lib/core/widgets/form_helper/fields/dropdown_fields.dart` | `DropdownField` (stateful): `UFFType.dropdown` | ALWAYS | none |
| `lib/core/widgets/form_helper/fields/choice_chips_field.dart` | `ChoiceChipsField`: `UFFType.choiceChips` over `FilterChipButton` | ALWAYS | none |
| `lib/core/widgets/form_helper/fields/rating_field.dart` | `RatingField`: `UFFType.rating`, stars in `AppTones.rating` | CONDITIONAL(app has ratings) | none |
| `lib/core/widgets/form_helper/fields/chip_input_field.dart` | `ChipInputField` (stateful): `UFFType.multiChipField` | ALWAYS (part of the system; unused by features) | texts `'Add value'`, `'Type and press done or +'`, validation messages |
| `lib/core/widgets/form_helper/fields/date_slector_field.dart` (sic) | `DateSelectorField`: `UFFType.date`, `DateFormat('MMM dd, yyyy')` | ALWAYS (unused by features) | date format, `'Select date'` |
| `lib/core/widgets/form_helper/fields/time_selector_field.dart` | `TimeSelectorField`: `UFFType.time` | ALWAYS (unused by features) | `'Select time'` |
| `lib/core/widgets/form_helper/fields/radio_toggle.dart` | `RadioToggle`: `UFFType.radio` (actually a `Switch.adaptive`) | ALWAYS (unused by features) | none |
| `lib/core/widgets/form_helper/fields/drop_down_multi_chip.dart` | `DropDownMultiChip` (stateful): dropdown that accumulates chips; **not reachable from `UniversalFormField`** (no `case UFFType.dropdownMultiChip`) and unused | ALWAYS-by-parity only (dead) | none |
| `lib/core/widgets/form_helper/chips/primary_chip.dart` | `PrimaryChip`: Material `Chip` used by `ChipInputField` and `DropDownMultiChip` | ALWAYS (dependency of two fields) | none |
| `lib/core/widgets/form_helper/chips/activity_chip.dart` | `ActivityChip`: count card (CRM leftover; uses `Colors.transparent`) | MYMALI-SPECIFIC (legacy, unused) | — |
| `lib/core/widgets/form_helper/chips/icon_labled_chip.dart` (sic) | `IconLabledChip`: icon + label pill | MYMALI-SPECIFIC (legacy, unused) | — |
| `lib/core/widgets/form_helper/chips/simple_info_chip.dart` | `SimpleInfoChip`: label pill | MYMALI-SPECIFIC (legacy, unused) | — |

Tests read (all under `test/core/widgets/`): `app_card_test.dart`, `app_network_image_test.dart`, `buttons/{add_button,dashed_outline_button,heart_toggle_button,primary_button,secondary_button,slide_action_button}_test.dart`, `cart/cart_summary_bar_test.dart`, `chips/filter_chip_button_test.dart`, `form_helper/fields/rating_field_test.dart`, `form_helper/field_theme_colors_test.dart`, `form_helper/universal_form_field_test.dart`, `form_section_title_test.dart`, `icon_list_tile_test.dart`, `page_header_test.dart`, `product/{explore_more_card,order_line_tile,product_card,product_list_tile,product_rail,quantity_stepper}_test.dart`, `search/search_trigger_bar_test.dart`, `section_label_test.dart`, `sheets/{app_info_sheet,app_picker_sheet}_test.dart`. There is no `test/core/theme/`.

Feature wrappers that AGENTS §21 names (read for the wrapper pattern, not part of the kit): `features/wishlist/presentation/widgets/wishlist_header.dart` (`WishlistHeader` → `PageHeader`), `features/catalog/presentation/widgets/catalog_product_card.dart` (`CatalogProductCard` → `ProductCard`), `features/cart/presentation/widgets/cart_bar_overlay.dart` (`CartBarOverlay` → `CartSummaryBar`, `static const double height = CartSummaryBar.height + _bottomGap + 8`), `features/mali_coins/presentation/widgets/mali_coin_icon.dart` (`MaliCoinIcon` → `AppLogo(asset: AppAssets.coin, semanticLabel: 'Mali coin')`), `features/cart/presentation/cart/widgets/cart_loading_skeleton.dart` (skeleton pattern).

---

## 2. Names

### 2a. Table of public names

| Name | Kind | File | Exact signature or shape |
|---|---|---|---|
| `AppColors` | `abstract final class` | theme/app_colors.dart | 28 `static const Color` members: `primary 0xFF225542`, `onPrimary Colors.white`, `accent 0xFFC7E97F`, `background 0xFFF5F7F2`, `forest 0xFF12291F`, `mist 0xFFCFDDD4`, `forestDeep 0xFF0B1B14`, `forestSurface 0xFF0F2419`, `forestLow 0xFF14291F`, `forestMid 0xFF1A3329`, `forestHigh 0xFF21402F`, `forestHighest 0xFF2A4D3B`, `forestOutline 0xFF3C5C4C`, `forestOutlineVariant 0xFF2A4538`, `primaryOnDark 0xFF2F7A57`, `primaryContainerDark 0xFF1C4A38`, `onForest 0xFFECF3EE`, `peach 0xFFF3C7B1`, `onPeach 0xFF4A2A1A`, `coral 0xFFF56C76`, `coinGold 0xFFF4B942`, `star 0xFFF5C518`, `success 0xFF1B5E20`, `successOnDark 0xFF7CC79A`, `sky 0xFF91C7D8`, `apricot 0xFFD98B65`, `apricotOnDark 0xFFE0A57E`, `black Colors.black`, `darkGray 0xFF4A4A4A` |
| `AppTheme` | `abstract final class` | theme/app_theme.dart | `static ThemeData get light`, `static ThemeData get dark`, `static const double fontSizeFactor = 0.88`, `static const String displayFontFamily = 'Marcellus'`, private `static ThemeData _build(AppTones tones, ColorScheme colorScheme)` |
| `AppTones` | `@immutable class … extends ThemeExtension<AppTones>` | theme/app_tones.dart | `const AppTones({required this.success, required this.info, required this.warning, this.rating = AppColors.star})`; `static const AppTones light`, `static const AppTones dark`; `final Color success, info, warning, rating`; `static AppTones of(BuildContext context)`; `copyWith({Color? success, Color? info, Color? warning, Color? rating})`; `lerp(ThemeExtension<AppTones>? other, double t)` |
| `AppAssets` | `abstract final class` | assets/app_assets.dart | `static const String icon = 'assets/icon.png'; appLogo = 'assets/applogo.png'; coin = 'assets/coin.png'` |
| `formatRupees` | top-level function | utils/currency_format.dart | `String formatRupees(num amount) => _rupees.format(amount);` with `final NumberFormat _rupees = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);` |
| `App.maxTextScaleFactor` | `static const double` | app/app.dart | `= 1.1` |
| `AppCard` | `StatelessWidget` | widgets/app_card.dart | `const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.title, this.icon, this.trailing, this.onHeaderTap, this.headerKey, this.accent})`; `static const double radius = 22`; `static Widget divider(BuildContext context)` |
| `AppLogo` | `StatelessWidget` | widgets/app_logo.dart | `const AppLogo({super.key, required this.size, this.color, this.asset = AppAssets.icon, this.semanticLabel = 'My Mali'})` |
| `AppNetworkImage` | `StatelessWidget` | widgets/app_network_image.dart | `const AppNetworkImage({super.key, required this.url, this.fit = BoxFit.cover, this.placeholderIcon = Icons.image_outlined, this.width, this.height})`; `final String? url` |
| `PageHeader` | `StatelessWidget` | widgets/page_header.dart | `const PageHeader({super.key, required this.title, required this.onBack, this.subtitle, this.subtitleKey, this.backKey, this.backTooltip = 'Back', this.trailing, this.bottom})`; `final VoidCallback? onBack`; `static double contentHeightFor(BuildContext context)` |
| `IconListTileLeading` | `enum` | widgets/icon_list_tile.dart | `{ plain, tile, circle }` |
| `IconListTile` | `StatelessWidget` | widgets/icon_list_tile.dart | `const IconListTile({super.key, required this.icon, required this.title, required this.onTap, this.subtitle, this.overline, this.leading = IconListTileLeading.tile, this.showChevron = false, this.isLoading = false, this.filled = false, this.badgeLabel, this.dense = false})`; `final VoidCallback? onTap` |
| `FormSectionTitle` | `StatelessWidget` | widgets/form_section_title.dart | `const FormSectionTitle({super.key, required this.title, this.icon, this.description, this.topPadding = 24})` |
| `SectionHeader` | `StatelessWidget` | widgets/section_header.dart | `const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction, this.actionKey})` |
| `SectionLabel` | `StatelessWidget` | widgets/section_label.dart | `const SectionLabel({super.key, required this.title, this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 8)})` |
| `ReloadWidget` | `StatelessWidget` | widgets/reload_widget.dart | `const ReloadWidget({super.key, required this.errorMessage, required this.onReload, this.color})`; retry `IconButton(key: const Key('reload_button'), tooltip: 'Retry', icon: Icon(Icons.refresh))` |
| `ProgressIndecator` | `StatelessWidget` | widgets/progress_indecator.dart | `const ProgressIndecator({super.key, this.color, this.strokeWidth})` |
| `RichMessageText` | `StatelessWidget` (legacy) | widgets/rich_text.dart | `const RichMessageText({super.key, required this.text, required this.baseStyle, this.linkColor = const Color(0xFF1A8CFF)})` |
| `PrimaryButton` | `StatelessWidget` | widgets/buttons/primary_button.dart | `const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.leadingIcon, this.isLoading = false, this.height = 56, this.expand = true, this.warm = false})` |
| `SecondaryButton` | `StatelessWidget` | widgets/buttons/secondary_button.dart | `const SecondaryButton({super.key, required this.label, required this.onPressed, this.isLoading = false, this.height = 56, this.expand = true, this.warm = false, this.destructive = false, this.leadingIcon})` |
| `CircleIconButton` | `StatelessWidget` | widgets/buttons/circle_icon_button.dart | `const CircleIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.size = 34, this.filled = false, this.accent = false, this.isLoading = false, this.badgeCount = 0})` |
| `HeartToggleButton` | `StatelessWidget` | widgets/buttons/heart_toggle_button.dart | `const HeartToggleButton({super.key, required this.isActive, required this.onPressed, this.size = 34, this.overImage = true, this.isLoading = false, this.tooltip})` |
| `SlideActionButton` | `StatefulWidget` | widgets/buttons/slide_action_button.dart | `const SlideActionButton({super.key, required this.label, required this.onPressed, this.prefixLabel, this.icon = Icons.arrow_forward_rounded, this.isLoading = false, this.height = 56})`; `static const double completeAt = 0.8` |
| `DashedOutlineButton` | `StatelessWidget` | widgets/buttons/dashed_outline_button.dart | `const DashedOutlineButton({super.key, required this.label, required this.onPressed, this.icon = Icons.add_rounded, this.isLoading = false, this.height = 64})`; `final IconData? icon` |
| `AddButton` | `StatelessWidget` | widgets/buttons/add_button.dart | `const AddButton({super.key, required this.onPressed, this.label = 'ADD', this.compact = false})` |
| `InfoChipTone` | `enum` | widgets/chips/info_chip.dart | `{ outline, accent, highlight, dark }` |
| `InfoChip` | `StatelessWidget` | widgets/chips/info_chip.dart | `const InfoChip({super.key, required this.label, this.icon, this.tone = InfoChipTone.outline})`; `static double heightFor(BuildContext context)` |
| `CategoryChip` | `StatefulWidget` | widgets/chips/category_chip.dart | `const CategoryChip({super.key, required this.label, required this.icon, required this.onTap, this.selected = false, this.width = defaultWidth})`; `final VoidCallback onTap` (non-null); `static const double defaultWidth = 80`; `static double heightFor(BuildContext context)` |
| `FilterChipButton` | `StatelessWidget` | widgets/chips/filter_chip_button.dart | `const FilterChipButton({super.key, this.label, this.icon, this.showDropdownArrow = true, this.selected = false, this.fillWhenSelected = false, this.onHeader = false, required this.onPressed})` |
| `AppInfoSheetTone` | `enum` | widgets/sheets/app_info_sheet.dart | `{ info, success, error }` |
| `AppInfoSheet` | `StatelessWidget` | widgets/sheets/app_info_sheet.dart | `const AppInfoSheet({super.key, required this.title, required this.message, required this.onAction, required this.onClose, this.tone = AppInfoSheetTone.info, this.icon, this.actionLabel = defaultActionLabel})`; `static const String defaultActionLabel = 'Got it'`; `static const Key actionKey = Key('appInfoSheet_actionButton')`; `static const Key closeKey = Key('appInfoSheet_closeButton')`; `static Future<bool> show(BuildContext context, {required String title, required String message, AppInfoSheetTone tone = AppInfoSheetTone.info, IconData? icon, String actionLabel = defaultActionLabel, Key? key})` |
| `AppPickerSheet` | `StatelessWidget` | widgets/sheets/app_picker_sheet.dart | `const AppPickerSheet({super.key, required this.title, this.icon, required this.child, this.footer, this.onClose})`; `static const Key closeKey = Key('appPickerSheet_closeButton')`; `static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder})` |
| `OptionTile` | `StatelessWidget` | widgets/sheets/option_tile.dart | `const OptionTile({super.key, required this.label, required this.selected, required this.onTap, this.icon, this.subtitle})` |
| `AppSearchBar` | `StatelessWidget` | widgets/search/app_search_bar.dart | `const AppSearchBar({super.key, required this.onChanged, this.hintText = 'Search', this.initialValue = '', this.autofocus = false, this.onSubmitted, this.trailingIcon, this.onTrailingPressed, this.trailingTooltip})` |
| `SearchTriggerBar` | `StatelessWidget` | widgets/search/search_trigger_bar.dart | `const SearchTriggerBar({super.key, required this.onTap, this.onCameraTap, this.hintText = 'Search', this.cameraTooltip = 'Search with a photo'})` |
| `CartSummaryBar` | `StatelessWidget` | widgets/cart/cart_summary_bar.dart | `const CartSummaryBar({super.key, required this.itemCount, required this.onPressed, this.thumbnailUrls = const [], this.label = 'View cart'})`; `static const int maxThumbnails = 2`; `static const double height = _thumbSize + 2 * _verticalPadding` (= 44) |
| `ProductCard` | `StatelessWidget` | widgets/product/product_card.dart | see 2b; `static double detailsHeightFor(BuildContext context)`; `static const double compactWidth = 160` |
| `ProductListTileControl` | `enum` | widgets/product/product_list_tile.dart | `{ below, besidePrice, trailing }` |
| `ProductListTile` | `StatelessWidget` | widgets/product/product_list_tile.dart | see 2b; `static const double thumbnailSize = 92` |
| `ProductGrid` | `StatelessWidget` | widgets/product/product_grid.dart | `const ProductGrid({super.key, required this.itemCount, required this.itemBuilder})`; `static const double spacing = 14`; `static double tileWidthFor(double width)`; `static double tileHeightFor(BuildContext context, double width)` |
| `SliverProductGrid` | `StatelessWidget` | widgets/product/product_grid.dart | `const SliverProductGrid({super.key, required this.itemCount, required this.itemBuilder})` |
| `ProductRail` | `StatelessWidget` | widgets/product/product_rail.dart | `const ProductRail({super.key, required this.itemCount, required this.itemBuilder, this.trailing, this.horizontalPadding = 16})`; `static const double trailingWidthFactor = 0.86` |
| `ExploreMoreCard` | `StatelessWidget` | widgets/product/explore_more_card.dart | `const ExploreMoreCard({super.key, required this.countLabel, required this.onTap, this.label = 'Explore more', this.imageUrls = const [], this.semanticLabel})`; `static const int maxThumbnails = 3` |
| `OrderLineTile` | `StatelessWidget` | widgets/product/order_line_tile.dart | `const OrderLineTile({super.key, required this.title, required this.quantity, required this.unitPrice, required this.total, this.imageUrl})` |
| `QuantityStepper` | `StatelessWidget` | widgets/product/quantity_stepper.dart | `const QuantityStepper({super.key, required this.quantity, required this.onIncrement, required this.onDecrement, this.incrementKey, this.decrementKey, this.height = 40, this.buttonWidth = 34, this.filled = false, this.removeAtOne = false, this.caption})` |
| `UniversalFormField` | plain class (not a Widget) | widgets/form_helper/universal_form_field.dart | see 2c (full source) |
| `UFFType` | `enum` (27 values, order matters) | widgets/form_helper/field_config.dart | `text, phone, date, time, year, address, radio, switchBtn, multiSelect, dropdown, multiText, slider, search, checkbox, upload, singleCheckbox, incDec, dateTimePicker, locationWithTextSearch, multiChipField, richTextEditor, multiDocumentSelect, chatTextBox, dropdownMultiChip, otp, choiceChips, rating` |
| `WrapperConfig`, `TextInputConfig`, `TextInputFieldType`, `OtpConfig`, `DatePickerConfig`, `TimePickerConfig`, `RadioConfig`, `DropdownConfig`, `ChoiceChipOption`, `ChoiceChipsConfig`, `RatingConfig`, `MultiChipDropdownConfig`, `DropdownOption`, `WidgetOrder`, `SingleCheckboxConfig`, `SwitchConfig`, `CheckboxConfig`, `MultiSelectConfig`, `MultiTextConfig`, `SliderConfig`, `SearchConfig`, `FileUploadConfig`, `IncDecConfig`, `MultiChipConfig`, `UploadConfig`, `ChatTextBoxConfig`, `MessageType` | config classes / enums | widgets/form_helper/field_config.dart | see 2c (full source) |
| `FieldTitle` | `StatelessWidget` | widgets/form_helper/field_title.dart | `const FieldTitle(this.text, {super.key, this.style, this.textAlign})` |
| `FieldDecorator` | `class … extends InputDecoration` | widgets/form_helper/decorator/field_decorator.dart | `factory FieldDecorator(BuildContext context, {required String label, String? hintText, IconData? prefixIcon, bool showCounter = true, EdgeInsets? contentPadding, bool isDropdown = false, bool enabled = false, Widget? suffixIcon, FloatingLabelBehavior? floatingLabelBehavior})`; `static Widget iconTile(ColorScheme colors, IconData icon)` |
| `CustomTextFormField` | `StatefulWidget` | widgets/form_helper/fields/custom_text_form_field.dart | see 2b; also `CustomTextFormField copyWith({…})` |
| `PhoneTextFormField` | `StatefulWidget` | widgets/form_helper/fields/phone_text_form_field.dart | see 2b |
| `OtpInputField` | `StatefulWidget` | widgets/form_helper/fields/otp_input_field.dart | `const OtpInputField({super.key, this.length = 4, this.initialValue, this.onChanged, this.onCompleted, this.validator, this.errorText, this.autofocus = false, this.enabled = true, this.obscureText = false})` |
| `CustomSearchBar` | `StatefulWidget` | widgets/form_helper/fields/custom_search_field.dart | `const CustomSearchBar({super.key, required this.label, this.initialValue, required this.onChanged, this.validator, this.readOnly = false, this.autofocus = false, this.controller, this.focusNode, this.hintText, this.debounceDuration = const Duration(milliseconds: 300), this.onSubmitted, this.trailing, this.borderRadius = 16})` |
| `DropdownField` | `StatefulWidget` | widgets/form_helper/fields/dropdown_fields.dart | `const DropdownField({super.key, this.value, this.items, this.showLabel = true, required this.label, this.validator, required this.onChanged, this.hintText, this.prefixIcon, this.errorText})`; `final dynamic value; final List<DropdownMenuItem>? items; final String? label; final String? Function(dynamic)? validator; final void Function(dynamic)? onChanged` |
| `DropDownMultiChip` | `StatefulWidget` (unreachable) | widgets/form_helper/fields/drop_down_multi_chip.dart | `const DropDownMultiChip({super.key, required this.label, this.initialValue, this.validator, this.isLoading = false, this.dropdownOptions = const []})` |
| `ChoiceChipsField` | `StatelessWidget` | widgets/form_helper/fields/choice_chips_field.dart | `const ChoiceChipsField({super.key, required this.options, required this.value, required this.onChanged, this.keyPrefix, this.enabled = true, this.errorText, this.validator})`; `final Object? value; final ValueChanged<Object> onChanged` |
| `RatingField` | `StatelessWidget` | widgets/form_helper/fields/rating_field.dart | `const RatingField({super.key, required this.value, required this.onChanged, this.maxRating = 5, this.starSize = 32, this.keyPrefix, this.enabled = true, this.errorText, this.validator})`; `final int value; final ValueChanged<int> onChanged` |
| `ChipInputField` | `StatefulWidget` | widgets/form_helper/fields/chip_input_field.dart | `const ChipInputField({super.key, this.initialChips = const [], this.onChanged, this.labelText, this.hintText, this.minChips, this.maxChips, this.validator})` |
| `DateSelectorField` | `StatelessWidget` | widgets/form_helper/fields/date_slector_field.dart | `const DateSelectorField({super.key, this.selectedDate, this.onDateSelected, this.label, this.hint, this.firstDate, this.lastDate, this.enabled = true, this.validator, this.prefixIcon = Icons.calendar_today_rounded, this.showClearButton = true, this.contentPadding})` |
| `TimeSelectorField` | `StatelessWidget` | widgets/form_helper/fields/time_selector_field.dart | `const TimeSelectorField({super.key, this.selectedTime, this.onTimeSelected, this.label, this.hint, this.enabled = true, this.validator, this.prefixIcon = Icons.access_time_rounded, this.showClearButton = true, this.contentPadding, this.use24HourFormat = false})` |
| `RadioToggle` | `StatelessWidget` | widgets/form_helper/fields/radio_toggle.dart | `const RadioToggle({super.key, required this.initialValue, required this.onChanged, this.radioColor})`; `final Function(bool)? onChanged; final bool initialValue` |
| `PrimaryChip` | `StatelessWidget` | widgets/form_helper/chips/primary_chip.dart | `const PrimaryChip({super.key, required this.label, this.onDeleted, this.padding, this.deleteIcon = Icons.close})` |
| `ActivityChip` | `StatelessWidget` (legacy) | widgets/form_helper/chips/activity_chip.dart | `const ActivityChip({super.key, required this.name, required this.count, required this.icon, this.onTap, required this.color})` |
| `IconLabledChip` | `StatelessWidget` (legacy) | widgets/form_helper/chips/icon_labled_chip.dart | `const IconLabledChip({super.key, required this.label, required this.icon, this.textColor, this.color})`; `final Icon icon` |
| `SimpleInfoChip` | `StatelessWidget` (legacy) | widgets/form_helper/chips/simple_info_chip.dart | `const SimpleInfoChip({super.key, required this.label})` |

Test keys that are part of the contract: `appInfoSheet_actionButton`, `appInfoSheet_closeButton`, `appPickerSheet_closeButton`, `reload_button`, `product_<testId>_add` / `_increment` / `_decrement` / `_wishlist` (`ProductCard`), `<keyPrefix>_<testId>_add` / `_increment` / `_decrement` / `_wishlist` with `keyPrefix` default `'product'` (`ProductListTile`), `<keyPrefix>_<keyId>` (`ChoiceChipsField`), `<keyPrefix>_<n>` with n from 1 (`RatingField`). Tooltips tests find: `'Back'`, `'Close'`, `'Retry'`.

### 2b. Complete constructor signatures of the product/cart widgets and the two stateful text fields (verbatim)

```dart
// product_card.dart
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.testId,
    required this.title,
    required this.price,
    this.subtitle,
    this.imageUrl,
    this.mrp,
    this.discountPercent = 0,
    this.soldCount,
    this.variantLabel,
    this.inStock = true,
    this.isLowStock = false,
    this.isComingSoon = false,
    this.isWishlisted = false,
    this.quantity = 0,
    this.onTap,
    this.onAdd,
    this.onIncrement,
    this.onDecrement,
    this.onWishlistPressed,
  });

  final String testId;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final double price;          // Selling price in rupees.
  final double? mrp;           // Struck-through "MRP" price, shown only when above [price].
  final int discountPercent;
  final int? soldCount;
  final String? variantLabel;
  final bool inStock;
  final bool isLowStock;
  final bool isComingSoon;     // Browsable but not buyable: no add control.
  final bool isWishlisted;
  final int quantity;          // Units already in the cart; above zero shows the stepper.
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onWishlistPressed;   // null hides the heart

  static double detailsHeightFor(BuildContext context) { … }   // see Patterns
  static const double compactWidth = 160;
  static const double _padding = 12;
  static const double _variantGap = 8;
  static const double _gap = 6;
  static const double _controlHeight = 40;
  static const double _slack = 2;
}
```

```dart
// product_list_tile.dart
enum ProductListTileControl { below, besidePrice, trailing }

class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.testId,
    required this.title,
    required this.price,
    this.caption,
    this.imageUrl,
    this.mrp,
    this.discountPercent = 0,
    this.inStock = true,
    this.isComingSoon = false,
    this.isWishlisted = false,
    this.quantity = 0,
    this.addLabel = 'Add to cart',
    this.wishlistKey,
    this.onTap,
    this.onLongPress,
    this.onAdd,
    this.onIncrement,
    this.onDecrement,
    this.onWishlistPressed,
    this.keyPrefix = 'product',
    this.imageSize = thumbnailSize,
    this.framed = true,
    this.variantLabel,
    this.priceNote,
    this.controlPlacement = ProductListTileControl.below,
    this.addIcon = Icons.shopping_bag_outlined,
    this.tonalAdd = false,
    this.addKey,
    this.actionLabel,
    this.actionIcon,
    this.actionKey,
    this.onAction,
  });

  static const double thumbnailSize = 92;
  static const double _padding = 11;
  static const double _unframedPadding = 16;
  static const double _controlHeight = 28;
  static const double _trailingShare = 0.55;
}
```

```dart
// custom_text_form_field.dart
class CustomTextFormField extends StatefulWidget {
  final String label;
  final Widget? prefix;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController? controller;
  final String? initialValue;
  final EdgeInsets? padding;
  final int maxLines;
  final bool? obscureText;
  final Function(bool)? obscureChange;
  final AutovalidateMode autovalidateMode;
  final String? Function(String? value) validator;
  final void Function(String value) onChanged;
  final void Function(String value)? onFieldSubmitted;
  final void Function()? onTap;
  final bool? readOnly;
  final TextInputType? textInputType;
  final bool isDateField;
  final bool isTimeField;
  final bool isYearField;
  final FocusNode? focusNode;
  final Function()? onEditingComplete;
  final bool? enabled;
  final TextInputType? keyboardType;
  final int? maxLength;
  final InputDecoration? decorator;
  final bool autofocus;
  final TextAlign textAlign;
  final TextInputFieldType? textInputFieldType;
  final String? errorText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool showCounter;
  const CustomTextFormField({
    this.errorText,
    this.hintText,
    this.prefixIcon,
    this.showCounter = true,
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.padding,
    this.maxLines = 1,
    this.obscureText,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    required this.validator,
    this.onFieldSubmitted,
    required this.onChanged,
    this.onTap,
    this.prefix,
    this.suffix,
    this.readOnly,
    this.textInputType,
    this.isDateField = false,
    this.isTimeField = false,
    this.isYearField = false,
    this.focusNode,
    this.onEditingComplete,
    this.enabled = true,
    this.inputFormatters,
    this.keyboardType,
    this.maxLength,
    this.decorator,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.textInputFieldType,
    this.obscureChange,
  });
}
```

```dart
// phone_text_form_field.dart
class PhoneTextFormField extends StatefulWidget {
  final String? label;
  final String? initialCountryCode;
  final String? initialValue;
  final void Function(String)? onChanged;
  final Function(String)? onCountryChanged;
  final String? Function(String?)? validator;
  final bool readOnly;
  final TextEditingController? controller;
  final String? errorText;
  final String? hintText;
  final bool showCounter;
  final bool lockCountryCode;                 // fixed dial code instead of a picker
  final IconData? prefixIcon;                 // only when lockCountryCode
  final List<TextInputFormatter>? inputFormatters;   // only when lockCountryCode; default digits only
  final Iterable<String>? autofillHints;      // only when lockCountryCode

  const PhoneTextFormField({
    this.lockCountryCode = false,
    this.prefixIcon,
    this.inputFormatters,
    this.autofillHints,
    this.errorText,
    this.hintText,
    this.showCounter = true,
    super.key,
    required this.label,
    this.readOnly = false,
    this.initialCountryCode,
    this.initialValue,
    this.onChanged,
    this.onCountryChanged,
    this.validator,
    this.controller,
  });
}
```

### 2c. Theme and form-system files, verbatim (another app reproduces these character for character, then substitutes placeholders)

`lib/core/theme/app_colors.dart`:

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF225542);
  static const Color onPrimary = Colors.white;

  /// Lime highlight used for accents such as underlines and button badges.
  static const Color accent = Color(0xFFC7E97F);

  /// Soft off-white page background.
  static const Color background = Color(0xFFF5F7F2);

  /// Deep forest green for dark floating surfaces such as the bottom bar.
  static const Color forest = Color(0xFF12291F);

  /// Muted mint for icons and text on [forest].
  static const Color mist = Color(0xFFCFDDD4);

  // Dark theme surfaces, from the page background up to raised cards.
  static const Color forestDeep = Color(0xFF0B1B14);
  static const Color forestSurface = Color(0xFF0F2419);
  static const Color forestLow = Color(0xFF14291F);
  static const Color forestMid = Color(0xFF1A3329);
  static const Color forestHigh = Color(0xFF21402F);
  static const Color forestHighest = Color(0xFF2A4D3B);
  static const Color forestOutline = Color(0xFF3C5C4C);
  static const Color forestOutlineVariant = Color(0xFF2A4538);

  /// Brand green that stays readable on [forestSurface].
  static const Color primaryOnDark = Color(0xFF2F7A57);

  /// Header and tinted panels on the dark theme.
  static const Color primaryContainerDark = Color(0xFF1C4A38);

  /// Near-white text on the dark theme.
  static const Color onForest = Color(0xFFECF3EE);

  /// Peach used for discount badges.
  static const Color peach = Color(0xFFF3C7B1);
  static const Color onPeach = Color(0xFF4A2A1A);

  /// Coral used for wishlist hearts, count badges and discount ribbons on
  /// the dark theme.
  static const Color coral = Color(0xFFF56C76);

  /// Gold used for the Mali coins pill.
  static const Color coinGold = Color(0xFFF4B942);

  /// Golden yellow for rating stars, on both themes.
  static const Color star = Color(0xFFF5C518);

  // Tones that say why something happened (see `AppTones`): a coin earned,
  // spent or gifted. Each has a light and a dark value.
  static const Color success = Color(0xFF1B5E20);
  static const Color successOnDark = Color(0xFF7CC79A);

  /// Calm blue for a good kind of spending, e.g. coins redeemed.
  static const Color sky = Color(0xFF91C7D8);

  /// Warm orange for a gift or a bonus.
  static const Color apricot = Color(0xFFD98B65);
  static const Color apricotOnDark = Color(0xFFE0A57E);

  static const Color black = Colors.black;
  static const Color darkGray = Color(0xFF4A4A4A);
}
```

`lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tones.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
    AppTones.light,
    ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      // `secondary` is the accent for text and icons on a surface: brand
      // green on light, lime on dark.
      secondary: AppColors.primary,
      secondaryContainer: AppColors.accent,
      onSecondaryContainer: AppColors.primary,
      tertiary: AppColors.coinGold,
      onTertiary: AppColors.forest,
      tertiaryContainer: AppColors.peach,
      onTertiaryContainer: AppColors.onPeach,
      surface: AppColors.background,
      inverseSurface: AppColors.forest,
      onInverseSurface: AppColors.mist,
    ),
  );

  /// Forest-green dark theme. Widgets read every colour from the
  /// [ColorScheme], so they need no brightness checks of their own.
  static ThemeData get dark => _build(
    AppTones.dark,
    ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryOnDark,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: AppColors.onForest,
      secondary: AppColors.accent,
      secondaryContainer: AppColors.accent,
      onSecondaryContainer: AppColors.forest,
      tertiary: AppColors.coinGold,
      onTertiary: AppColors.forest,
      tertiaryContainer: AppColors.peach,
      onTertiaryContainer: AppColors.onPeach,
      // `error` doubles as the "love / alert" accent: hearts, badges and
      // discount ribbons.
      error: AppColors.coral,
      onError: AppColors.onPrimary,
      surface: AppColors.forestSurface,
      onSurface: AppColors.onForest,
      onSurfaceVariant: AppColors.mist,
      surfaceContainerLowest: AppColors.forestDeep,
      surfaceContainerLow: AppColors.forestLow,
      surfaceContainer: AppColors.forestMid,
      surfaceContainerHigh: AppColors.forestHigh,
      surfaceContainerHighest: AppColors.forestHighest,
      outline: AppColors.forestOutline,
      outlineVariant: AppColors.forestOutlineVariant,
      inverseSurface: AppColors.forestDeep,
      onInverseSurface: AppColors.mist,
      shadow: AppColors.black,
    ),
  );

  /// Shrinks Material's default type scale, which reads too large on
  /// phone-width tiles. Every `textTheme` style is this much smaller.
  static const double fontSizeFactor = 0.88;

  /// Serif used for section titles, as registered in `pubspec.yaml`. It
  /// ships in one weight, so pair it with [FontWeight.w400].
  static const String displayFontFamily = 'Marcellus';

  static ThemeData _build(AppTones tones, ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      extensions: [tones],
      scaffoldBackgroundColor: colorScheme.surface,
      // Material's own sizes, scaled. These styles do not inherit, so
      // ThemeData cannot add the colours: without them a style has no
      // colour at all, and a plain text field types in the engine's default
      // instead of the theme's.
      textTheme: Typography.englishLike2021.apply(
        fontSizeFactor: fontSizeFactor,
        displayColor: colorScheme.onSurface,
        bodyColor: colorScheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
```

Component themes present in `_build`: **only** `textTheme`, `inputDecorationTheme`, `filledButtonTheme`, `scaffoldBackgroundColor`, `extensions`. No `appBarTheme`, `cardTheme`, `chipTheme`, `bottomSheetTheme` etc.; `useMaterial3` is left at its default (true). The font family of the text theme is `null` (platform default); `Typography.englishLike2021` gives Material-2021 geometry, each size × 0.88 (e.g. `titleLarge` 22 → 19.36, `titleMedium` 16 → 14.08, `bodyMedium` 14 → 12.32, `labelMedium` 12 → 10.56, `headlineSmall` 24 → 21.12).

`pubspec.yaml` font registration the theme relies on:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/icon.png
    - assets/applogo.png
    - assets/coin.png
    - .env
  fonts:
    - family: Marcellus
      fonts:
        - asset: assets/fonts/Marcellus-Regular.ttf
```

`lib/core/theme/app_tones.dart`:

```dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colours that say *why* something happened, beyond what the
/// [ColorScheme] offers: a success, a calm note and a warm gift. The
/// alert red stays `colorScheme.error`.
///
/// Read them with `AppTones.of(context)`. The values live in [AppColors]
/// and are registered on both themes by `AppTheme`, so widgets need no
/// brightness checks of their own.
@immutable
class AppTones extends ThemeExtension<AppTones> {
  const AppTones({
    required this.success,
    required this.info,
    required this.warning,
    this.rating = AppColors.star,
  });

  static const AppTones light = AppTones(
    success: AppColors.success,
    info: AppColors.sky,
    warning: AppColors.apricot,
    rating: AppColors.star,
  );

  static const AppTones dark = AppTones(
    success: AppColors.successOnDark,
    info: AppColors.sky,
    warning: AppColors.apricotOnDark,
    rating: AppColors.star,
  );

  /// Something good: coins earned, an order delivered.
  final Color success;

  /// A calm note: coins spent on purpose.
  final Color info;

  /// Warm attention: a gift, a bonus.
  final Color warning;

  /// A filled rating star and the bars of a rating summary.
  final Color rating;

  /// The tones of the current theme.
  static AppTones of(BuildContext context) =>
      Theme.of(context).extension<AppTones>() ?? light;

  @override
  AppTones copyWith({
    Color? success,
    Color? info,
    Color? warning,
    Color? rating,
  }) => AppTones(
    success: success ?? this.success,
    info: info ?? this.info,
    warning: warning ?? this.warning,
    rating: rating ?? this.rating,
  );

  @override
  AppTones lerp(ThemeExtension<AppTones>? other, double t) {
    if (other is! AppTones) return this;
    return AppTones(
      success: Color.lerp(success, other.success, t) ?? success,
      info: Color.lerp(info, other.info, t) ?? info,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      rating: Color.lerp(rating, other.rating, t) ?? rating,
    );
  }
}
```

`lib/core/widgets/form_helper/field_config.dart` (whole file; the `UFFType` order and every default are contract):

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum UFFType {
  text,
  phone,
  date,
  time,
  year,
  address,
  radio,
  switchBtn,
  multiSelect,
  dropdown,
  multiText,
  slider,
  search,
  checkbox,
  upload,
  singleCheckbox,
  incDec,
  dateTimePicker,
  locationWithTextSearch,
  multiChipField,
  richTextEditor,
  multiDocumentSelect,
  chatTextBox,
  dropdownMultiChip,
  otp,
  choiceChips,
  rating,
}

class WrapperConfig {
  final double widthX5;
  final double widthX4;
  final double widthX3;
  final double? fixedWidth;
  const WrapperConfig({
    this.widthX5 = 350,
    this.widthX4 = 325,
    this.widthX3 = 300,
    this.fixedWidth,
  });

  WrapperConfig copyWith({
    double? widthX5,
    double? widthX4,
    double? widthX3,
    double? fixedWidth,
  }) {
    return WrapperConfig(
      widthX5: widthX5 ?? this.widthX5,
      widthX4: widthX4 ?? this.widthX4,
      widthX3: widthX3 ?? this.widthX3,
      fixedWidth: fixedWidth ?? this.fixedWidth,
    );
  }
}

class TextInputConfig {
  final TextInputType? textInputType;
  final TextInputFieldType? textInputFieldType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final Widget? prefix;

  /// Shown at the end of a text field, e.g. a "Locked" chip on a field
  /// the user cannot change.
  final Widget? suffix;
  final bool obscureText;
  final Function(bool)? obscureChange;
  final Function(String)? onFieldSubmitted;
  final AutovalidateMode autovalidateMode;
  final dynamic Function(String)? onCountryChanged;
  final Iterable<String>? autofillHints;
  final MouseCursor? mouseCursor;
  final InputDecoration? decorator;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool? enabled;
  final Function()? onEditingComplete;
  final TextAlign? textAlign;
  final String? initialCountryCode;

  /// Error shown on the field without running a Form validation, e.g. an
  /// error held in a BLoC state.
  final String? errorText;

  /// Placeholder shown inside the field.
  final String? hintText;

  /// Icon shown in a tinted tile at the start of the field.
  final IconData? prefixIcon;

  /// Whether to show the character counter when [maxLength] is set.
  final bool showCounter;

  /// Phone fields only: fix the country to [initialCountryCode] and hide
  /// the country picker.
  final bool lockCountryCode;
  const TextInputConfig({
    this.lockCountryCode = false,
    this.errorText,
    this.hintText,
    this.prefixIcon,
    this.showCounter = true,
    this.textInputType,
    this.inputFormatters,
    this.initialCountryCode,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.textInputFieldType,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.obscureChange,
    this.onFieldSubmitted,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.autofillHints,
    this.mouseCursor,
    this.decorator,
    this.focusNode,
    this.enabled,
    this.onEditingComplete,
    this.textAlign,
    this.autofocus = false,
    this.onCountryChanged,
  });
}

enum TextInputFieldType { email, password }

class OtpConfig {
  /// Number of digit boxes.
  final int length;

  /// Called once every box is filled.
  final void Function(String)? onCompleted;

  /// Error shown without running a Form validation, e.g. from a BLoC state.
  final String? errorText;
  final bool autofocus;
  final bool enabled;
  final bool obscureText;
  const OtpConfig({
    this.length = 4,
    this.onCompleted,
    this.errorText,
    this.autofocus = false,
    this.enabled = true,
    this.obscureText = false,
  });
}

class DatePickerConfig {
  final String? Function(DateTime?)? dateValidator;
  final bool showClearButton;
  final bool enabled;
  const DatePickerConfig({
    this.dateValidator,
    this.showClearButton = false,
    this.enabled = true,
  });
}

class TimePickerConfig {
  final String? Function(TimeOfDay?)? timeValidator;
  final bool showClearButton;
  final bool enabled;
  final bool use24HourFormat;
  const TimePickerConfig({
    this.timeValidator,
    this.showClearButton = false,
    this.enabled = true,
    this.use24HourFormat = false,
  });
}

class RadioConfig {
  final Color? radioColor;
  const RadioConfig({this.radioColor});
}

class DropdownConfig {
  final List<DropdownOption> dropdownOptions;
  final String? Function(dynamic)? dropdownValidator;
  final bool isLoading;

  /// Shown while nothing is chosen; defaults to the field's label.
  final String? hintText;

  /// Icon shown in a tinted tile at the start of the field.
  final IconData? prefixIcon;

  /// Error shown without running a Form validation, e.g. an error held in
  /// a BLoC state.
  final String? errorText;
  const DropdownConfig({
    this.dropdownOptions = const [],
    this.dropdownValidator,
    this.isLoading = false,
    this.hintText,
    this.prefixIcon,
    this.errorText,
  });
}

/// One choice of a [UFFType.choiceChips] field.
class ChoiceChipOption {
  /// What `onChanged` receives when this choice is picked.
  final Object value;
  final String label;
  final IconData? icon;

  /// Seeds the chip's key, `<keyPrefix>_<keyId>`, for tests.
  final String? keyId;
  const ChoiceChipOption({
    required this.value,
    required this.label,
    this.icon,
    this.keyId,
  });
}

/// Options of a [UFFType.choiceChips] field: a row of pills of which
/// exactly one is picked. The field's `initialValue` is the picked value.
class ChoiceChipsConfig {
  final List<ChoiceChipOption> options;

  /// Each chip gets the key `<keyPrefix>_<keyId>` when both are set.
  final String? keyPrefix;
  final bool enabled;

  /// Error shown under the chips, e.g. an error held in a BLoC state.
  final String? errorText;
  const ChoiceChipsConfig({
    this.options = const [],
    this.keyPrefix,
    this.enabled = true,
    this.errorText,
  });
}

/// Options of a [UFFType.rating] field: a row of stars, of which the
/// first n are filled. The field's `initialValue` is the rating (0 = none).
class RatingConfig {
  /// How many stars there are.
  final int maxRating;

  /// Size of each star.
  final double starSize;

  /// Each star gets the key `<keyPrefix>_<n>` (n from 1) when set.
  final String? keyPrefix;
  final bool enabled;

  /// Error shown under the stars, e.g. an error held in a BLoC state.
  final String? errorText;
  const RatingConfig({
    this.maxRating = 5,
    this.starSize = 32,
    this.keyPrefix,
    this.enabled = true,
    this.errorText,
  });
}

class MultiChipDropdownConfig {
  final List<DropdownOption> dropDownOptions;
  final String? Function(List<String>?)? validator;
  final bool isLoading;
  const MultiChipDropdownConfig({
    this.dropDownOptions = const [],
    this.isLoading = false,
    this.validator,
  });
}

// for dropdown option
class DropdownOption {
  final dynamic key;
  final String value;
  final Color? color;
  const DropdownOption({required this.key, required this.value, this.color});
}

enum WidgetOrder { NORMAL, REVERSED }

class SingleCheckboxConfig {
  final bool checkboxValue;
  final WidgetOrder widgetOrder;
  const SingleCheckboxConfig({
    this.checkboxValue = false,
    this.widgetOrder = WidgetOrder.NORMAL,
  });
}

class SwitchConfig {
  final bool value;

  const SwitchConfig({this.value = false});
}

class CheckboxConfig {
  final List<String>? options;
  final List<String>? selectedItems;
  const CheckboxConfig({this.options, this.selectedItems});
}

class MultiSelectConfig {
  final Map<dynamic, dynamic> options;
  final List<dynamic>? selectedItems;
  final void Function(List<dynamic> selectedItems)? onChanged;
  final String? Function(List<dynamic>?)? validator;
  const MultiSelectConfig({
    this.options = const {},
    this.selectedItems,
    this.onChanged,
    this.validator,
  });
}

class MultiTextConfig {
  final List<String>? editableStringItems;
  final void Function(List<String>)? updateListInState;
  const MultiTextConfig({this.editableStringItems, this.updateListInState});
}

class SliderConfig {
  final double? minVal;
  final double? maxVal;

  const SliderConfig({this.minVal, this.maxVal});
}

class SearchConfig {
  final FutureOr<Iterable<Object>> Function(String)? optionsBuilder;
  final void Function(Object)? onSuggestionSelected;
  final Widget Function(BuildContext, Object)? itemBuilder;

  /// Placeholder; defaults to "Search <label>...".
  final String? hintText;

  /// Called, undebounced, on the keyboard's search action.
  final void Function(String)? onSubmitted;

  /// Widget shown at the trailing edge, e.g. an accent camera button.
  final Widget? trailing;

  /// Corner radius; 28 gives a pill at the default height.
  final double borderRadius;

  /// How long typing must pause before `onChanged` fires.
  final Duration debounceDuration;

  const SearchConfig({
    this.optionsBuilder,
    this.onSuggestionSelected,
    this.itemBuilder,
    this.hintText,
    this.onSubmitted,
    this.trailing,
    this.borderRadius = 16,
    this.debounceDuration = const Duration(milliseconds: 300),
  });
}

class FileUploadConfig {
  final String? url;

  const FileUploadConfig({this.url});
}

class IncDecConfig {
  final void Function()? onIncrement;
  final void Function()? onDecrement;

  const IncDecConfig({this.onIncrement, this.onDecrement});
}

class MultiChipConfig {
  final List<String>? initialValue;
  final int? maxChips;
  final int? minChips;
  final String? Function(List<String>?)? onSumbitValidator;
  const MultiChipConfig({
    this.onSumbitValidator,
    this.initialValue,
    this.maxChips,
    this.minChips,
  });
}

class UploadConfig {
  final dynamic value;
  final bool? isReadOnly;
  final bool? enableCopy;
  final bool? allowMultiple;
  final int? limit;
  final List<String>? docTypes;
  final String? Function()? validate;
  final double? maximumDocumentSize;
  final bool? enablePreview;
  const UploadConfig({
    this.value,
    this.isReadOnly,
    this.enableCopy,
    this.allowMultiple,
    this.limit,
    this.docTypes,
    this.validate,
    this.maximumDocumentSize,
    this.enablePreview,
  });
}

class ChatTextBoxConfig {
  // final Function(
  //         String message, MessageType type, List<PlatformFile> attachments)?
  //     onSendMessage;
  final Function()? onCallNow;
  final Function()? onCallLater;
  final Function()? onFeedbackSale;
  final Function()? onSalesComplete;
  final Function()? onWhatsAppTemplate;
  final Function()? onStatus;
  final Function()? onType;
  final Function()? onHandOver;
  final Function()? onRelease;

  final bool showNoteButton;
  final bool showCallButtons;
  final bool showFeedbackButton;
  final bool showUploadButton;
  final bool showTemplateButton;
  final String? placeholder;
  final bool showSendMailButton;
  final bool showSendWhatsappButton;
  final int maxLines;
  final bool isSendingMsg;
  final bool showAddNoteButton;

  const ChatTextBoxConfig({
    // this.onSendMessage,
    this.onCallNow,
    this.showSendMailButton = false,
    this.isSendingMsg = false,
    this.onCallLater,
    this.onFeedbackSale,
    this.onStatus,
    this.onType,
    this.onSalesComplete,
    this.onWhatsAppTemplate,
    this.onHandOver,
    this.onRelease,
    this.showAddNoteButton = true,
    this.showNoteButton = true,
    this.showSendWhatsappButton = false,
    this.showCallButtons = true,
    this.showFeedbackButton = true,
    this.showUploadButton = true,
    this.showTemplateButton = true,
    this.placeholder,
    this.maxLines = 4,
  });
}

enum MessageType {
  none,
  ai_chat,
  live_chat,
  text_message,
  live_message,
  whatsapp_message,
  video_call,
  audio_call,
  video_message,
  voice_message,
  feedback_form,
  agent_feedback_form,
  note,
  video_feedback,
  audio_feedback,
  text_feedback,
  bot_response,
  chat_response,
  chat_request,
  request_handover,
  schedule_meeting,
  image,
  document,
  url,
  outbound_call,
  payment,
  meeting_snap,
  lead_config_status_change,
  lead_config_type_change,
  lead_purchase_status_change,
  handover_message,
  lead_owner_changed,
}
```

`lib/core/widgets/form_helper/universal_form_field.dart` (whole file; note it is **not** a `Widget`, and that the imports mix `package:mymali/...` absolute and relative paths — another app replaces `mymali` with its own package name):

```dart
import 'package:flutter/material.dart';
import 'package:mymali/core/widgets/form_helper/fields/chip_input_field.dart';
import 'package:mymali/core/widgets/form_helper/fields/date_slector_field.dart';
import 'package:mymali/core/widgets/form_helper/fields/radio_toggle.dart';
import 'package:mymali/core/widgets/form_helper/fields/time_selector_field.dart';
import 'package:mymali/core/widgets/progress_indecator.dart';

import 'field_config.dart';
import 'field_title.dart';
import 'fields/choice_chips_field.dart';
import 'fields/custom_search_field.dart';
import 'fields/custom_text_form_field.dart';
import 'fields/dropdown_fields.dart';
import 'fields/otp_input_field.dart';
import 'fields/phone_text_form_field.dart';
import 'fields/rating_field.dart';

class UniversalFormField {
  final Key? key;
  final bool updateKey;
  final UFFType fieldType;
  final String label;
  final dynamic initialValue;
  final void Function(dynamic val) onChanged;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final bool hide;
  final bool fullWidth;
  final bool useController;
  final bool withTitle;
  final TextStyle? labelStyle;

  UniversalFormField({
    this.key,
    this.updateKey = false,
    required this.fieldType,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.validator,
    this.controller,
    this.hide = false,
    this.fullWidth = false,
    this.useController = false,
    this.withTitle = false,
    this.labelStyle,
  });

  TextEditingController textEditingController = TextEditingController();

  Widget build({
    TextInputConfig textInputConfig = const TextInputConfig(),
    DropdownConfig dropdownConfig = const DropdownConfig(),
    MultiChipDropdownConfig multiChipDropdownConfig =
        const MultiChipDropdownConfig(),
    // MultiTextConfig multiTextConfig = const MultiTextConfig(),
    // MultiSelectConfig multiSelectConfig = const MultiSelectConfig(),
    DatePickerConfig datePickerConfig = const DatePickerConfig(),
    TimePickerConfig timePickerConfig = const TimePickerConfig(),
    SearchConfig searchConfig = const SearchConfig(),
    RadioConfig radioConfig = const RadioConfig(),
    SingleCheckboxConfig singleCheckboxConfig = const SingleCheckboxConfig(),
    CheckboxConfig checkboxConfig = const CheckboxConfig(),
    // SliderConfig sliderConfig = const SliderConfig(),
    SwitchConfig switchConfig = const SwitchConfig(),
    WrapperConfig wrapperConfig = const WrapperConfig(),
    // IncDecConfig incDecConfig = const IncDecConfig(),
    MultiChipConfig multiChipConfig = const MultiChipConfig(),
    UploadConfig uploadConfig = const UploadConfig(),
    ChatTextBoxConfig chatTextBoxConfig = const ChatTextBoxConfig(),
    OtpConfig otpConfig = const OtpConfig(),
    ChoiceChipsConfig choiceChipsConfig = const ChoiceChipsConfig(),
    RatingConfig ratingConfig = const RatingConfig(),
  }) {
    Widget returningWidget = const SizedBox();
    if (controller != null) {
      textEditingController = controller!;
    } else {
      textEditingController.text = initialValue?.toString() ?? '';
      textEditingController.selection = TextSelection.collapsed(
        offset: initialValue?.toString().length ?? 0,
      );
    }

    var formField = CustomTextFormField(
      key: updateKey ? Key(initialValue ?? '') : null,
      textInputFieldType: textInputConfig.textInputFieldType,
      label: withTitle ? "" : label,
      autofocus: textInputConfig.autofocus,
      textAlign: textInputConfig.textAlign ?? TextAlign.start,
      autovalidateMode: textInputConfig.autovalidateMode,
      controller: useController
          ? textEditingController
          : initialValue == null
          ? textEditingController
          : null,
      initialValue: !useController ? initialValue?.toString() : null,
      decorator: textInputConfig.decorator,
      enabled: textInputConfig.enabled,
      focusNode: textInputConfig.focusNode,
      inputFormatters: textInputConfig.inputFormatters,
      maxLength: textInputConfig.maxLength,
      maxLines: textInputConfig.maxLines,
      onFieldSubmitted: textInputConfig.onFieldSubmitted,
      onEditingComplete: textInputConfig.onEditingComplete,
      obscureText: textInputConfig.obscureText,
      obscureChange: textInputConfig.obscureChange,
      prefix: textInputConfig.prefix,
      suffix: textInputConfig.suffix,
      readOnly: textInputConfig.readOnly,
      textInputType: textInputConfig.textInputType,
      errorText: textInputConfig.errorText,
      hintText: textInputConfig.hintText,
      prefixIcon: textInputConfig.prefixIcon,
      showCounter: textInputConfig.showCounter,
      validator:
          validator ??
          (_) {
            return null;
          },
      onChanged: onChanged,
    );

    switch (fieldType) {
      case UFFType.text:
        returningWidget = formField;
        break;

      case UFFType.phone:
        returningWidget = PhoneTextFormField(
          label: withTitle ? '' : label,
          hintText: textInputConfig.hintText,
          showCounter: textInputConfig.showCounter,
          onChanged: onChanged,
          onCountryChanged: textInputConfig.onCountryChanged,
          initialCountryCode: textInputConfig.initialCountryCode ?? "IN",
          lockCountryCode: textInputConfig.lockCountryCode,
          inputFormatters: textInputConfig.inputFormatters,
          autofillHints: textInputConfig.autofillHints,
          prefixIcon: textInputConfig.prefixIcon,
          initialValue: initialValue,
          validator: validator,
          readOnly: textInputConfig.readOnly,
          controller: controller,
          errorText: textInputConfig.errorText,
        );
        break;

      case UFFType.search:
        returningWidget = CustomSearchBar(
          label: label,
          initialValue: initialValue?.toString(),
          onChanged: (value) => onChanged(value),
          validator: validator,
          readOnly: textInputConfig.readOnly,
          autofocus: textInputConfig.autofocus,
          controller: useController ? textEditingController : null,
          focusNode: textInputConfig.focusNode,
          hintText: searchConfig.hintText ?? textInputConfig.hintText,
          onSubmitted: searchConfig.onSubmitted,
          trailing: searchConfig.trailing,
          borderRadius: searchConfig.borderRadius,
          debounceDuration: searchConfig.debounceDuration,
        );
        break;
      case UFFType.dropdown:
        returningWidget = Stack(
          alignment: Alignment.centerRight,
          children: [
            IgnorePointer(
              ignoring: dropdownConfig.isLoading,
              child: DropdownField(
                key: key,
                items: dropdownConfig.dropdownOptions.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Row(
                      spacing: 16,
                      children: [
                        if (e.color != null)
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: e.color,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: dropdownConfig.isLoading ? (_) {} : onChanged,
                validator: dropdownConfig.dropdownValidator,
                label: withTitle ? '' : label,
                hintText: dropdownConfig.hintText,
                prefixIcon: dropdownConfig.prefixIcon,
                errorText: dropdownConfig.errorText,
                value: initialValue,
              ),
            ),
            if (dropdownConfig.isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 40),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: ProgressIndecator(strokeWidth: 2),
                ),
              ),
          ],
        );
      case UFFType.multiChipField:
        returningWidget = Container(
          child: ChipInputField(
            labelText: label,
            maxChips: multiChipConfig.maxChips,
            minChips: multiChipConfig.minChips,
            validator: multiChipConfig.onSumbitValidator,
            initialChips: initialValue != null
                ? List<String>.from(initialValue)
                : <String>[],
            onChanged: (chips) => onChanged(chips),
          ),
        );
      case UFFType.radio:
        returningWidget = RadioToggle(
          initialValue: initialValue ?? false,
          onChanged: onChanged,
          radioColor: radioConfig.radioColor,
        );
      case UFFType.date:
        returningWidget = DateSelectorField(
          label: 'Birth Date',
          hint: 'Select date',
          selectedDate: initialValue,
          onDateSelected: (date) => onChanged(date),
          validator: datePickerConfig.dateValidator,
          enabled: datePickerConfig.enabled,
          showClearButton: datePickerConfig.showClearButton,
        );
      case UFFType.time:
        returningWidget = TimeSelectorField(
          label: 'Meeting Time',
          hint: 'Select time',
          selectedTime: initialValue,
          onTimeSelected: onChanged,
          validator: timePickerConfig.timeValidator,
          use24HourFormat: timePickerConfig.use24HourFormat,
          enabled: timePickerConfig.enabled,
          showClearButton: timePickerConfig.showClearButton,
        );
      case UFFType.otp:
        returningWidget = OtpInputField(
          length: otpConfig.length,
          initialValue: initialValue?.toString(),
          onChanged: onChanged,
          onCompleted: otpConfig.onCompleted,
          validator: validator,
          errorText: otpConfig.errorText,
          autofocus: otpConfig.autofocus,
          enabled: otpConfig.enabled,
          obscureText: otpConfig.obscureText,
        );
      case UFFType.choiceChips:
        returningWidget = ChoiceChipsField(
          options: choiceChipsConfig.options,
          value: initialValue,
          onChanged: onChanged,
          keyPrefix: choiceChipsConfig.keyPrefix,
          enabled: choiceChipsConfig.enabled,
          errorText: choiceChipsConfig.errorText,
          validator: validator,
        );
      case UFFType.rating:
        returningWidget = RatingField(
          value: initialValue is int ? initialValue as int : 0,
          onChanged: onChanged,
          maxRating: ratingConfig.maxRating,
          starSize: ratingConfig.starSize,
          keyPrefix: ratingConfig.keyPrefix,
          enabled: ratingConfig.enabled,
          errorText: ratingConfig.errorText,
          validator: validator,
        );
      default:
        returningWidget = SizedBox.shrink();
    }

    if (withTitle) {
      returningWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldTitle(
            label,
            style: labelStyle,
            // The OTP boxes are centred, so centre their title too.
            textAlign: fieldType == UFFType.otp ? TextAlign.center : null,
          ),
          const SizedBox(height: 8),
          returningWidget,
        ],
      );
    }

    return hide
        ? const SizedBox.shrink()
        : wrapperConfig.fixedWidth != null
        ? SizedBox(
            width: wrapperConfig.fixedWidth,
            child: SizedBox(child: returningWidget),
          )
        : SizedBox(child: returningWidget);
  }
}
```

`UFFType` → widget mapping as wired: `text → CustomTextFormField`; `phone → PhoneTextFormField`; `search → CustomSearchBar`; `dropdown → Stack(IgnorePointer(DropdownField), [ProgressIndecator while isLoading])`; `multiChipField → ChipInputField`; `radio → RadioToggle` (a `Switch.adaptive`); `date → DateSelectorField`; `time → TimeSelectorField`; `otp → OtpInputField`; `choiceChips → ChoiceChipsField`; `rating → RatingField`; **everything else** (`year, address, switchBtn, multiSelect, multiText, slider, checkbox, upload, singleCheckbox, incDec, dateTimePicker, locationWithTextSearch, richTextEditor, multiDocumentSelect, chatTextBox, dropdownMultiChip`) → `SizedBox.shrink()`. Build parameters that are accepted but never read: `multiChipDropdownConfig`, `singleCheckboxConfig`, `checkboxConfig`, `switchConfig`, `uploadConfig`, `chatTextBoxConfig`. Instance fields never read: `fullWidth`. `WrapperConfig.widthX5/X4/X3` never read; only `fixedWidth` is.

How `withTitle`, `hide`, `wrapperConfig` work: `withTitle: true` passes `''` as the field's own label for text/phone/dropdown (so `FieldDecorator` reserves no floating-label space) and wraps the result in `Column(stretch, min)[FieldTitle(label, style: labelStyle, textAlign: otp ? center : null), SizedBox(height: 8), field]`; `hide: true` returns `const SizedBox.shrink()` after everything was built; `wrapperConfig.fixedWidth != null` wraps in `SizedBox(width: fixedWidth, child: SizedBox(child: field))`, otherwise `SizedBox(child: field)`.

`lib/core/widgets/form_helper/field_title.dart`:

```dart
import 'package:flutter/material.dart';

/// Small uppercase caption shown above a field when
/// `UniversalFormField.withTitle` is true.
class FieldTitle extends StatelessWidget {
  const FieldTitle(this.text, {super.key, this.style, this.textAlign});

  final String text;

  /// Overrides the default caption style.
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text.toUpperCase(),
      textAlign: textAlign,
      style:
          style ??
          theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
    );
  }
}
```

`lib/core/widgets/form_helper/decorator/field_decorator.dart` (how every text/phone/dropdown/chip field is styled):

```dart
import 'package:flutter/material.dart';

class FieldDecorator extends InputDecoration {
  factory FieldDecorator(
    BuildContext context, {
    required String label,
    String? hintText,
    IconData? prefixIcon,
    bool showCounter = true,
    EdgeInsets? contentPadding,
    bool isDropdown = false,
    bool enabled = false,
    Widget? suffixIcon,
    FloatingLabelBehavior? floatingLabelBehavior,
  }) {
    return FieldDecorator._(
      Theme.of(context).colorScheme,
      label: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      showCounter: showCounter,
      contentPadding: contentPadding,
      isDropdown: isDropdown,
      enabled: enabled,
      suffixIcon: suffixIcon,
      floatingLabelBehavior: floatingLabelBehavior,
    );
  }

  static const double _radius = 14;

  static OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Icon shown inside a small tinted, rounded tile, as used for
  /// `prefixIcon`.
  static Widget iconTile(ColorScheme colors, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: colors.primary),
      ),
    );
  }

  FieldDecorator._(
    ColorScheme colors, {
    required String label,
    String? hintText,
    IconData? prefixIcon,
    bool showCounter = true,
    EdgeInsets? contentPadding,
    bool isDropdown = false,
    bool enabled = false,
    Widget? suffixIcon,
    FloatingLabelBehavior? floatingLabelBehavior,
  }) : super(
         // An empty label (e.g. when a title is shown above the field)
         // would still reserve floating-label space, so omit it.
         label: isDropdown || label.isEmpty
             ? null
             : Text(
                 label,
                 maxLines: 1,
                 overflow: TextOverflow.fade,
                 softWrap: false,
                 textAlign: TextAlign.start,
               ),
         labelText: isDropdown && label.isNotEmpty ? label : null,
         hintText: hintText,
         hintStyle: TextStyle(
           color: colors.onSurfaceVariant.withValues(alpha: 0.7),
           fontSize: 16,
           fontWeight: FontWeight.normal,
         ),
         labelStyle: TextStyle(
           color: colors.onSurfaceVariant,
           fontSize: 16,
           fontWeight: FontWeight.normal,
         ),
         hintMaxLines: 1,
         alignLabelWithHint: true,
         floatingLabelBehavior: FloatingLabelBehavior.auto,
         filled: true,
         fillColor: colors.surfaceContainerLowest,
         prefixIcon: prefixIcon == null ? null : iconTile(colors, prefixIcon),
         prefixIconConstraints: prefixIcon == null
             ? null
             : const BoxConstraints(minWidth: 54, minHeight: 34),
         counterText: showCounter ? null : '',
         contentPadding:
             contentPadding ?? const EdgeInsets.fromLTRB(16, 16, 16, 16),
         disabledBorder: _border(colors.outlineVariant.withValues(alpha: 0.5)),
         enabledBorder: _border(colors.outlineVariant),
         focusedBorder: _border(colors.primary, 1.6),
         errorBorder: _border(colors.error, enabled ? 0.8 : 1.2),
         focusedErrorBorder: _border(colors.error, 1.6),
         hintTextDirection: TextDirection.ltr,
         suffixIcon:
             suffixIcon ??
             (isDropdown
                 ? Icon(
                     Icons.keyboard_arrow_down,
                     size: 28,
                     weight: 20,
                     color: colors.onSurface,
                   )
                 : null),
       );
}
```

Who uses `FieldDecorator`: `CustomTextFormField` (`_baseDecoration` → `FieldDecorator(context, label, hintText, prefixIcon, showCounter, contentPadding: padding, suffixIcon: suffix)` then `.copyWith(errorText:)`; the `floatingLabelBehavior` parameter passed by the factory is ignored by `_` — it always sets `FloatingLabelBehavior.auto`), `PhoneTextFormField` (both modes; locked mode replaces `prefixIcon` with a `Row[iconTile|SizedBox(16), '+<dialCode>', 1×22 divider]` and `prefixIconConstraints: BoxConstraints(minHeight: 34)`), `DropdownField` (`isDropdown: true`, `floatingLabelBehavior` never/always — also ignored, see Gotchas), `ChipInputField` (`suffixIcon: IconButton(Icons.add)`). **Not** used by `CustomSearchBar`, `OtpInputField`, `DateSelectorField`, `TimeSelectorField`, which build their own `InputDecoration`.

### 2d. Theme roles each widget reads (so a port keeps the same look under a different palette)

| Widget | ColorScheme roles | TextTheme styles | Shape / sizes |
|---|---|---|---|
| `AppCard` | `surfaceContainerLow` fill; `outlineVariant`α0.6 border 1 (or `accent`α0.4 width 1.5 + 4px `accent` strip); header `surfaceContainer`, `onSurface` | `titleMedium` | radius 22; header padding h16 v12; divider `outlineVariant`α0.5 h1 |
| `AppLogo` | none (`color` tint optional, `BlendMode.srcIn`) | — | `cacheWidth = (size × dpr).round()` |
| `AppNetworkImage` | placeholder `surfaceContainerHigh` + `onSurfaceVariant`α0.5 icon 36 | — | fade in 200ms / out 100ms; `memCacheWidth = ceil(longest finite side × dpr)` |
| `PageHeader` | `primaryContainer` bg; `onPrimaryContainer` title, α0.7 subtitle | `titleLarge` (displayFontFamily, w400), `bodyMedium` | bottom radius 28; padding LTRB(16,2,16,8); back `CircleIconButton` 36 `Icons.arrow_back_rounded`; gap 12; `bottom` gap 12 |
| `IconListTile` | plain: `onSurface`/`onSurfaceVariant`, tint `secondary`α0.12; filled: `primary` bg, `onPrimary` (α0.8 muted), tint `onPrimary`α0.16; badge `secondaryContainer`/`onSecondaryContainer`; spinner `secondary` or `onPrimary`; disabled title α0.4 | `titleMedium` w700 (dense `bodyLarge` w600); `bodyMedium` (dense `bodySmall`); `labelMedium` overline ls0.3 / badge w700 | frame 44 (dense 36) radius 12 (dense 10) or circle; icon 22 (dense 18; plain 24); padding h16 v10 (dense v7; filled h14 v14); chevron 22; filled radius 18 |
| `FormSectionTitle` | `primary` icon; `onSurface`; `onSurfaceVariant` | `titleMedium` w700; `bodyMedium` | icon 22; padding top `topPadding` bottom 12 |
| `SectionHeader` | `onSurface`; pill `surfaceContainerHigh`; `secondary` label+arrow | `headlineSmall` (displayFontFamily, w400, ls −0.2); `labelLarge` w700 | StadiumBorder pill, padding h14 v8, arrow 16 |
| `SectionLabel` | bar `secondaryContainer`; `onSurface` | `labelLarge` w700 ls1, uppercase | bar 3×13 radius 2; gap 8 |
| `ReloadWidget` | `color ?? onSurface` | `bodyMedium` | padding 24 |
| `ProgressIndecator` | `color ?? primary` | — | Cupertino radius 15 on iOS |
| `PrimaryButton` | `primary`/`onPrimary` (warm: `tertiaryContainer`/`onTertiaryContainer`); disabled fill α0.55; badge `secondaryContainer`/`onSecondaryContainer` | bare `TextStyle(fontSize: 16, w600, ls 0.2)` | StadiumBorder; height 56; badge `height−12` circle at right 6; dots 28; leading icon 20 |
| `SecondaryButton` | tone `error` (destructive) / `tertiaryContainer` (warm) / `primary`; disabled α0.55; destructive fill tone α0.08 | `titleMedium` w600 ls0.2 | StadiumBorder side 1.4; height 56 |
| `CircleIconButton` | accent `secondaryContainer`/`onSecondaryContainer`; filled `primary`/`onPrimary`; default `onSurface`α0.08 / `onSurface`; disabled bg α0.5, icon α0.6 | `Badge` default | size 34; icon size×0.5; spinner size×0.4 stroke 2; `'99+'` cap |
| `HeartToggleButton` | overImage `inverseSurface`α0.55 / `onInverseSurface`; plain `onSurface`α0.08 / `onSurfaceVariant`; active `error` (plain bg `error`α0.18) | — | size 34; icon size×0.53; `Icons.favorite_rounded` / `favorite_border_rounded` |
| `SlideActionButton` | `primary` track (α0.55 disabled), `onPrimary` text (α0.7 disabled), `shadow` (gradient α0.28, drop α0.18 blur 12 (0,4)), `secondaryContainer` thumb/chevrons/covered track α0.2, `onSecondaryContainer` thumb icon | `titleMedium` w600 ls0.2; prefix w800; compact `labelLarge` w600 | height 56; thumb `height−10`; inset 5; chevrons `thumb×0.5 × thumb×0.3`; `completeAt 0.8`; fling 700 px/s; nudge 0.16; hint 3 sweeps × 1100ms |
| `DashedOutlineButton` | `primary` (α0.55 disabled) | `titleMedium` w700 | radius 18; height 64; dash 7 gap 5 stroke 1.6; icon 22 |
| `AddButton` | `primary` (α0.45 disabled) / `onPrimary` | `labelLarge` w800 ls0.6 | radius 12; padding h14 v10 (compact h10 v8); `Icons.add_rounded` 18/16 |
| `InfoChip` | outline: `secondary` text, border `secondary`α0.45; accent: `secondary`α0.14 bg; highlight: `tertiaryContainer`/`onTertiaryContainer`; dark: `inverseSurface`α0.78/`onInverseSurface` | `labelMedium` w700 | radius 10; padding h9 v4; icon 13 |
| `CategoryChip` | tile selected `primary` / pressed `surfaceContainerHighest` / `surfaceContainerHigh`; border `primary` or `outlineVariant`α0.35; icon `secondaryContainer` (selected) / `onSurface`; label `secondary` w700 / `onSurface` w600; overlay `primary`α0.06 | `labelMedium` height 1.2 | width 80; tile 46 radius 18; icon 26; gap 8; v-padding 6; 2 lines; scale 0.92 pressed 160ms |
| `FilterChipButton` | default: `surfaceContainerHigh` fill (selected+fillWhenSelected `primaryContainer`), border `primary`/`outlineVariant`, text `onSurface`; onHeader: `onPrimaryContainer` tint (fill α0.12 / solid, border α0.22 / solid, text α0.85 / `primaryContainer`); disabled α0.4 | `labelLarge` w600 (w800 onHeader+selected) | StadiumBorder width 1.4 selected (1 onHeader); padding h14 (12 icon-only) v10; icon 18; arrow `Icons.expand_more_rounded` 18 |
| `AppInfoSheet` | tone `secondary` (info, success) / `error`; tile tone α0.14; `onSurface`; `onSurfaceVariant`; `outlineVariant` divider | `titleLarge` w800; `bodyLarge` height 1.45 | tile 44 radius 14 icon 24; close `CircleIconButton` 40; paddings LTRB(20,0,16,16) / (20,20,20,24) / (20,0,20,16) |
| `AppPickerSheet` | tile `secondary`α0.14 / `secondary`; `onSurface` | `headlineSmall` (displayFontFamily, w400, ls −0.2) | tile 44 radius 14; close 40; keyboard inset padding |
| `OptionTile` | selected `primaryContainer` + `primary` border 1.4; else `surfaceContainerHigh` + `outlineVariant` 1; icon tile `secondary`α0.12/`secondary`; ring `primary`/`outline`; `onSurface` (α0.4 disabled); `onSurfaceVariant` | `titleMedium` w700/w500; `bodyMedium` | radius 16; padding h18 v16; icon frame 44 radius 12 icon 22; ring 22 (width 2/1.4), dot 10 |
| `AppSearchBar` | via `CustomSearchBar` + `CircleIconButton(accent)` | — | `borderRadius: 28`, trailing button 40, right padding 6 |
| `SearchTriggerBar` | `surfaceContainerLowest` fill; `outline`α0.3 border; `onSurfaceVariant` icon/text | `bodyLarge` fontSize 15 | radius 28; min height 52; icon 22; camera `CircleIconButton(accent, 40)` padding 6 |
| `CartSummaryBar` | `secondaryContainer` bg; `onSecondaryContainer` text/arrow bg/thumb border (count α0.75); `shadow`α0.5 elevation 8 | `titleSmall` w800; `labelSmall` w700 ls1 | StadiumBorder; thumbs 32 overlap 12 border 1.5; arrow 28; padding h8 v6 |
| `ProductCard` | `surfaceContainerLow`; `outlineVariant`α0.6; `onSurface`; `onSurfaceVariant` | `titleMedium` w700 title; `bodySmall` subtitle/MRP(lineThrough); `titleLarge` w800 price | radius 22; square image; padding 12; heart top/right 10; badges inset 10; stepper 40/34 (compact 36/28) |
| `ProductListTile` | framed `surfaceContainerLow` + `outlineVariant`α0.6; caption `primary`; `onSurface`; `onSurfaceVariant`; ribbon `error`/`onError`; add pill `primary`/`onPrimary` (tonal `primaryContainer`/`onPrimaryContainer`), disabled α0.45 | `labelSmall` w700 ls1.2 caption; `titleMedium` w500 h1.3 title; `labelMedium` w600 priceNote; `titleLarge` w800 price; `bodyMedium` lineThrough mrp; `labelSmall` w800 ls0.4 ribbon; `labelLarge` w800 pill; `labelMedium` w600 action | radius 20; padding LTRB(11,11,11,13) or 16; thumb 92 radius 14; ribbon padding LTRB(8,1,9,1) bottom-right radius 10; control height 28; trailing ≤ 55% width |
| `ProductGrid` | — | — | 2 columns; spacing 14; `mainAxisExtent = tileHeightFor` |
| `ProductRail` | — | — | height `tileHeightFor(gridWidth)`; separator 14; trailing × 0.86 |
| `ExploreMoreCard` | `surfaceContainer`; `outlineVariant`α0.6; `primary` (bleed circle α0.08, arrow bg + shadow α0.3, count pill); `onPrimary`; `secondary` label; `surface` thumb ring | `titleSmall` w800; `labelMedium` w700 | radius 22; thumbs 42 step 26 border 2; arrow 46/22; circle 132 at (−44,−44) |
| `OrderLineTile` | `onSurface`; `onSurfaceVariant` | `bodyMedium` w600; `bodySmall` | thumb 44 radius 10; padding v10 |
| `QuantityStepper` | filled: `primary` bg, `onPrimary`; else `surfaceContainerHigh` bg, `secondary` buttons, `onSurface` number, count box `surfaceContainerLowest`; disabled α0.38; divider fg α0.3 | `titleMedium` w700 (h1.1 with caption); `labelSmall` w600 ls0.6 α0.8 caption | height 40, button 34; StadiumBorder (filled) / radius 12; count min width 30 radius 8; icon `min(20, height×0.6)` |
| `FieldTitle` | `onSurfaceVariant` | `labelMedium` w600 ls1.1 uppercase | — |
| `FieldDecorator` | fill `surfaceContainerLowest`; borders `outlineVariant` (α0.5 disabled) / `primary` 1.6 focused / `error`; hint `onSurfaceVariant`α0.7; label `onSurfaceVariant`; icon tile `primary`α0.07 / `primary`; dropdown arrow `onSurface` | bare `TextStyle(fontSize: 16)` | radius 14; content padding 16; icon tile 34 radius 10 icon 18 |
| `CustomTextFormField` | text `onSurface`, cursor `primary` (also `textSelectionTheme.cursorColor`); email/password icons `onSurfaceVariant` | bare `TextStyle(fontSize: 16)` | — |
| `PhoneTextFormField` | cursor `primary`; text `onSurface`; locked divider `outlineVariant` | bare 16 w600 dial code | `IntlPhoneField(showCountryFlag: false, dropdownIconPosition: IconPosition.trailing, flagsButtonPadding: EdgeInsets.only(left: 8))` |
| `OtpInputField` | box `surfaceContainerLowest` (disabled `surfaceContainerHighest`); border `error` / `primary` (active) / `outlineVariant`; glow `primary`α0.12; digit `onSurface`; caret `primary`; error `error` | bare 22 w600 digit; `bodySmall` error | box width `min(58, (w − 12×(n−1))/n)`, height ×1.08, radius 14, border 1.8 active/error else 1; spacing 12; `AutofillHints.oneTimeCode` |
| `CustomSearchBar` | `surfaceContainerLowest`; border `primary` 1.5 focused / `outline`α0.3; glow `primary`α0.18 blur 14; icon `primary`/`onSurfaceVariant`; text `onSurface`; cursor `primary` | `bodyLarge` fontSize 15 w400 | radius 16 (28 via AppSearchBar); `textInputAction: search`; debounce 300ms; clear `Icons.clear_rounded` 20 |
| `DropdownField` | hint `onSurfaceVariant`; text `onSurface`; `focusColor surfaceContainerLowest`; `dropdownColor surfaceContainer`; item accent `primary`/`Colors.transparent`; check `primary`/`onPrimary` | bare 16 / 15 | elevation 12; `menuMaxHeight 320`; radius 12; item padding v12 h8 |
| `ChoiceChipsField` | via `FilterChipButton(showDropdownArrow: false, fillWhenSelected: true)`; error `error` | `bodySmall` error | Wrap spacing 10 run 10; error padding h12 |
| `RatingField` | filled `AppTones.of(context).rating`; empty `onSurfaceVariant`; error `error` | `bodySmall` error | star 32; `InkResponse radius starSize×0.7`; padding 3 |
| `DateSelectorField` / `TimeSelectorField` | fill `surface`; borders `primaryContainer` 1.25 / `primary` 2 focused / `error`; icon `primary` (value) / `onSurfaceVariant`; disabled `onSurface`α0.38; picker theme: `primary`/`onPrimary` header, `surface` bg | bare 16 / 14 | radius 10.58; content padding LTRB(12,12,12,16) |
| `RadioToggle` | `radioColor ?? primary` as `activeThumbColor` | — | `Switch.adaptive` |
| `PrimaryChip` | `primaryContainer` bg; `onPrimaryContainer` text/delete icon; `primary` side 1 | bare 14 w500 | elevation 4; padding h12 v8 |

---

## 3. Patterns

### P1. A custom button: `Material` + `InkWell` + `Semantics`, the enabled/loading contract, theme-only colours

Verbatim reference, `lib/core/widgets/buttons/primary_button.dart` (copy the shape for every new button):

```dart
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// Pill-shaped call-to-action button in the brand style. Full width by
/// default; set [expand] to false to make it only as wide as its label.
///
/// Pass [icon] to show it in an accent-coloured badge at the trailing
/// edge, or [leadingIcon] to show a plain icon before the label. A null
/// [onPressed] disables the button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leadingIcon,
    this.isLoading = false,
    this.height = 56,
    this.expand = true,
    this.warm = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Plain icon shown before the label.
  final IconData? leadingIcon;
  final bool isLoading;
  final double height;

  /// Whether the button fills the width it is given.
  final bool expand;

  /// Whether the button is the warm (peach) one that confirms a choice in
  /// a sheet, e.g. "Apply", instead of the brand colour.
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !isLoading;
    final fill = warm ? colors.tertiaryContainer : colors.primary;
    final foreground = warm ? colors.onTertiaryContainer : colors.onPrimary;
    final background = enabled ? fill : fill.withValues(alpha: 0.55);

    final Widget text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: foreground,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
    final Widget content = Padding(
      // A full-width button keeps its label clear of the trailing badge.
      padding: EdgeInsets.symmetric(horizontal: expand ? height : height / 2),
      child: leadingIcon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(leadingIcon, size: 20, color: foreground),
                const SizedBox(width: 8),
                Flexible(child: text),
              ],
            ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: height,
            width: expand ? double.infinity : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isLoading)
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: foreground,
                    size: 28,
                  ),
                if (!isLoading)
                  content
                // A content-width button keeps its width while loading.
                else if (!expand)
                  Visibility.maintain(visible: false, child: content),
                if (icon != null && !isLoading)
                  Positioned(
                    right: 6,
                    child: Container(
                      width: height - 12,
                      height: height - 12,
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

Rule encoded (what to copy): `final enabled = onPressed != null && !isLoading;` → `InkWell(onTap: enabled ? onPressed : null)`; disabled look = same colour at `withValues(alpha: 0.55)` (0.45 on `AddButton`, 0.5 on the round buttons); loading = `LoadingAnimationWidget.staggeredDotsWave(color: foreground, size: 28)` replacing the label (a non-expanding button keeps its width with `Visibility.maintain`); `Semantics(button: true, enabled: enabled, label: label, excludeSemantics: true)` around the whole thing; `Material(shape: const StadiumBorder(), clipBehavior: Clip.antiAlias)`; never `ElevatedButton`/`FilledButton`/`OutlinedButton`. What varies: the colour roles (`primary`, `tertiaryContainer`, `error`) and the shape (`StadiumBorder`, `CircleBorder`, `RoundedRectangleBorder`).

### P2. Reading the theme, and promoting nullable fields to locals

Every widget's `build` opens with one of:

```dart
final theme = Theme.of(context);
final colors = theme.colorScheme;
```
or, when no text style is needed, `final colors = Theme.of(context).colorScheme;`. Nullable fields are copied to locals so Dart promotes them: `final subtitle = this.subtitle; … if (subtitle != null && subtitle.isNotEmpty) …` (PageHeader, IconListTile, AppCard, ProductListTile, OptionTile, FormSectionTitle, AppPickerSheet uses `if (icon case final icon?)`). Translucency is always `color.withValues(alpha: x)` (never `withOpacity`, never `Color(0x…)`). Text is always `theme.textTheme.<style>?.copyWith(color: …, fontWeight: …)`; the serif is `fontFamily: AppTheme.displayFontFamily, fontWeight: FontWeight.w400` (SectionHeader, PageHeader, AppPickerSheet). Tones outside the scheme: `AppTones.of(context).rating`.

### P3. A fixed-height parent reserves room with a `heightFor` that mirrors `build`

Verbatim, `product_card.dart`:

```dart
  /// Height the card needs below its square image: the details block at
  /// its fullest (subtitle, variant chip, stock chip, price with MRP), in
  /// the current theme and text scale. It mirrors the layout in [build],
  /// so keep the two in step.
  static double detailsHeightFor(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle? style) =>
        scaler.scale(style?.fontSize ?? 14) * (style?.height ?? 1.3);

    final chip = InfoChip.heightFor(context);
    final priceRow = math.max(
      line(text.titleLarge) + line(text.bodySmall),
      _controlHeight,
    );
    return 2 * _padding +
        line(text.titleMedium) +
        line(text.bodySmall) +
        _variantGap +
        chip +
        _gap +
        chip +
        _gap +
        priceRow +
        _slack;
  }
```

Siblings, verbatim: `InfoChip.heightFor` → `textHeight + 2 * _verticalPadding + 2` where `textHeight = MediaQuery.textScalerOf(context).scale(style?.fontSize ?? 12) * (style?.height ?? 1.33)` over `labelMedium`; `CategoryChip.heightFor` → `(_verticalPadding * 2 + _tileSize + _gap + lineHeight * _maxLines).ceilToDouble()` with `lineHeight = scaler.scale(fontSize ?? 12) * 1.2`; `PageHeader.contentHeightFor` → `math.max(_backButtonSize, line(text.titleLarge) + _subtitleGap + line(text.bodyMedium))` with `line` rounded `.ceilToDouble()`; `ProductGrid.tileWidthFor(width) = (width - spacing * (_columns - 1)) / _columns` and `tileHeightFor(context, width) = tileWidthFor(width) + ProductCard.detailsHeightFor(context)`. Rule: the helper is `static`, takes `BuildContext`, uses `MediaQuery.textScalerOf`, and the tests pump at `textScale` 1.0 and 1.1 and assert `tester.takeException() == null` and no empty band (`card.bottom - contentBottom` in `[12, 24]`).

### P4. Stable test keys seeded by `testId` / `keyPrefix`

Verbatim, `product_card.dart`: `HeartToggleButton(key: Key('product_${testId}_wishlist'), …)`, `QuantityStepper(incrementKey: Key('product_${testId}_increment'), decrementKey: Key('product_${testId}_decrement'), …)`, `AddButton(key: Key('product_${testId}_add'), …)`. `product_list_tile.dart`: `Key('${keyPrefix}_${testId}_increment')` etc., overridable with `wishlistKey ?? …`, `addKey ?? …`, `actionKey`. Sheets expose `static const Key actionKey = Key('appInfoSheet_actionButton'); static const Key closeKey = Key('appInfoSheet_closeButton');` / `Key('appPickerSheet_closeButton')`. Form fields: `Key('${keyPrefix}_${option.keyId}')`, `Key('${keyPrefix}_$star')`. Rule: `<lowerCamelWidget>_<part>` for fixed keys; `<prefix>_<id>_<part>` for repeated items; every key is a `static const` or derived from constructor input, never typed in a page.

### P5. A sheet opened by a `static show` on the root navigator

Verbatim, `app_info_sheet.dart`:

```dart
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    AppInfoSheetTone tone = AppInfoSheetTone.info,
    IconData? icon,
    String actionLabel = defaultActionLabel,
    Key? key,
  }) async {
    final acted = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      // Lets a long message take the height it needs.
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => AppInfoSheet(
        key: key,
        title: title,
        message: message,
        tone: tone,
        icon: icon,
        actionLabel: actionLabel,
        onAction: () => Navigator.of(sheetContext).pop(true),
        onClose: () => Navigator.of(sheetContext).pop(false),
      ),
    );
    return acted ?? false;
  }
```

and `app_picker_sheet.dart`:

```dart
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      // Lets the sheet take the height its choices need.
      isScrollControlled: true,
      showDragHandle: true,
      builder: builder,
    );
  }
```

Rule: the four flags are always `useRootNavigator: true, useSafeArea: true, isScrollControlled: true, showDragHandle: true`; the sheet body is `SafeArea(top: false, child: Column(mainAxisSize: min, crossAxisAlignment: stretch, [header Row, (Divider), Flexible(SingleChildScrollView(body)), footer]))`; the picker also pads `EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)`; choices close with `Navigator.of(sheetContext).pop(value)`; the close button is `CircleIconButton(key: closeKey, icon: Icons.close_rounded, tooltip: 'Close', size: 40, onPressed: onClose ?? () => Navigator.of(context).pop())`. Tone → (icon, colour) is a `switch` expression returning a record: `final (IconData toneIcon, Color toneColor) = switch (tone) { … };` (same record-switch idiom in `InfoChip`: `final (Color background, Color foreground, Color? border) = switch (tone) { … };`).

### P6. Private sub-widgets in the same file

Every composite widget splits its parts into file-private `StatelessWidget`s named `_Part` with `const` constructors and `required` fields: `_Header` (AppCard), `_Placeholder` (AppNetworkImage), `_Thumb` (CartSummaryBar), `_Thumbnail` (ExploreMoreCard, ProductListTile), `_ImageBadges`/`_PriceBlock`/`_StockChip` (ProductCard), `_AddButton`/`_TextAction` (ProductListTile), `_StepButton`/`_QuantityLabel`/`_Divider` (QuantityStepper), `_DigitBox` (OtpInputField), `_Thumb` + `_ChevronsPainter` + `enum _LabelLayout` (SlideActionButton), `_DashedBorderPainter` (DashedOutlineButton). Private layout constants are `static const double _name = n;` on the public class and read by the helpers (`CartSummaryBar._thumbSize` is read by its `_Thumb`).

### P7. A feature widget wraps a generic one; the generic one takes plain values

Verbatim, `features/wishlist/presentation/widgets/wishlist_header.dart`:

```dart
class WishlistHeader extends StatelessWidget {
  const WishlistHeader({
    super.key,
    required this.itemCount,
    required this.onBack,
  });

  /// Saved products on screen; zero shows the invitation line instead.
  final int itemCount;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: 'My Wishlist',
      subtitle: itemCount == 0
          ? 'Save the plants you love'
          : '$itemCount ${itemCount == 1 ? 'item' : 'items'} saved'
                ' · hold a card to remove',
      subtitleKey: const Key('wishlist_subtitle'),
      backKey: const Key('wishlist_backButton'),
      onBack: onBack,
      trailing: const _HeartBadge(),
    );
  }
}
```

and the bloc-reading wrapper `CatalogProductCard` (`features/catalog/presentation/widgets/catalog_product_card.dart`) selects `context.select((CartBloc bloc) => …quantityOf(variant.id))` and `context.select((WishlistBloc bloc) => bloc.state.contains(product.id))`, then returns `ProductCard(testId: product.id, …, onAdd: …, onIncrement: variant == null || (stock != null && quantity >= stock) ? null : () => …)`. Rule: nothing under `lib/core/widgets/` imports a bloc, an entity or a feature; feature text, keys and bloc wiring live in the wrapper; a `null` callback is how the wrapper disables a control (the "+" at stock).

### P8. Loading skeletons are the real widgets inside `Skeletonizer`

Verbatim, `features/cart/presentation/cart/widgets/cart_loading_skeleton.dart`:

```dart
    return Skeletonizer.sliver(
      // Follow the app theme, not the platform brightness, so the shimmer
      // stays right when the user toggles dark mode in the app.
      effect: ShimmerEffect(
        baseColor: colors.surfaceContainerHighest,
        highlightColor: colors.surfaceContainerLow,
      ),
      child: SliverPadding(
        padding: padding,
        sliver: SliverToBoxAdapter(
          child: CartSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < _lineCount; index++) ...[
                  if (index > 0) const CartRowDivider(),
                  ProductListTile(
                    testId: 'skeleton_$index',
                    title: 'Product name here',
                    imageSize: CartLineTile.imageSize,
                    framed: false,
                    variantLabel: '250 ml',
                    price: 999,
                    mrp: 1299,
                    quantity: 1,
                    controlPlacement: ProductListTileControl.besidePrice,
                    actionLabel: 'Save for later',
                    onIncrement: () {},
                    onDecrement: () {},
                    onAction: () {},
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
```

Rule: no `Bone.*`, no grey boxes; placeholder values in the real components; `ShimmerEffect(baseColor: colorScheme.surfaceContainerHighest, highlightColor: colorScheme.surfaceContainerLow)`; the skeleton lives in the feature, not in `core/widgets`.

### P9. A form field through `UniversalFormField`

Verbatim call shape from the tests (`universal_form_field_test.dart`):

```dart
UniversalFormField(
  fieldType: UFFType.dropdown,
  label: 'State *',
  withTitle: true,
  onChanged: (_) {},
).build(
  dropdownConfig: const DropdownConfig(
    hintText: 'Select state',
    prefixIcon: Icons.location_on_outlined,
    errorText: 'Choose the state',
    dropdownOptions: [
      DropdownOption(key: 'Goa', value: 'Goa'),
      DropdownOption(key: 'Kerala', value: 'Kerala'),
    ],
  ),
)
```

and `AppSearchBar`'s use (`app_search_bar.dart`):

```dart
    return UniversalFormField(
      fieldType: UFFType.search,
      label: 'products',
      initialValue: initialValue,
      onChanged: (value) => onChanged(value as String),
    ).build(
      textInputConfig: TextInputConfig(autofocus: autofocus),
      searchConfig: SearchConfig(
        hintText: hintText,
        borderRadius: 28,
        onSubmitted: onSubmitted,
        trailing: trailingIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 6),
                child: CircleIconButton(
                  icon: trailingIcon!,
                  size: 40,
                  accent: true,
                  tooltip: trailingTooltip,
                  onPressed: onTrailingPressed,
                ),
              ),
      ),
    );
```

Rule: construct `UniversalFormField(...)` and immediately call `.build(<matching config>: …)`; `onChanged` receives `dynamic` and the caller casts (`value as String`, `value as int`); bloc-held errors go in the config's `errorText`; `withTitle: true` shows `FieldTitle` and suppresses the floating label.

### P10. A field that supports both `errorText` (bloc) and `validator` (Form)

Verbatim, `choice_chips_field.dart` body:

```dart
    return FormField<Object>(
      initialValue: value,
      validator: validator == null
          ? null
          : (picked) => validator!(picked?.toString()),
      builder: (field) {
        final error = field.errorText ?? errorText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final option in options)
                  FilterChipButton(
                    key: keyPrefix != null && option.keyId != null
                        ? Key('${keyPrefix}_${option.keyId}')
                        : null,
                    label: option.label,
                    icon: option.icon,
                    showDropdownArrow: false,
                    fillWhenSelected: true,
                    selected: option.value == value,
                    onPressed: enabled
                        ? () {
                            field.didChange(option.value);
                            onChanged(option.value);
                          }
                        : null,
                  ),
              ],
            ),
            if (error != null && error.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
```

Rule (also `RatingField`, `OtpInputField`, `PhoneTextFormField`): wrap in `FormField<T>`; `final error = field.errorText ?? errorText;`; on change call `field.didChange(v)` **then** `onChanged(v)`; `validator` adapts the typed value to the `String? Function(String?)` the system uses; the error line is `bodySmall` in `colorScheme.error` under the control.

### P11. Component widget tests

Every test pumps the bare widget under the real theme, not the app:

```dart
  Future<void> pumpButton(WidgetTester tester, PrimaryButton button) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: button)),
      ),
    );
  }
```

Variants: `theme: AppTheme.dark` (most), `Scaffold(body: Column(children: [tile]))` for full-width rows, `MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(textScale)), child: …)` for the 1.0/1.1 loops, phone size with `tester.view.physicalSize = const Size(1170, 2532); tester.view.devicePixelRatio = 3; addTearDown(tester.view.reset);`. Assertions reach into the tree: `tester.widget<Material>(find.descendant(of: find.byType(X), matching: find.byType(Material))).color`, `(material.shape! as StadiumBorder).side.color`, `tester.widget<InkWell>(find.byType(InkWell)).onTap == null` for disabled, `tester.takeException() == null` for overflow, `tester.renderObject<RenderParagraph>(find.text(t)).didExceedMaxLines` for truncation, `find.byTooltip('Back')`, `tester.getSemantics(...)` with `isSemantics(label:, isButton:, isEnabled:, hasTapAction:)`. Default test surface is 800×600, so "fills the width" asserts `width == 800`. `AppNetworkImage` tests assert on `CachedNetworkImage.imageUrl` and `memCacheWidth` (120×80 box at dpr 3 → 360).

### P12. Theme wiring in `App` (outside the area, but the theme contract)

Verbatim, `lib/app/app.dart`:

```dart
  /// Largest system font scale the app follows. Larger settings overflow
  /// fixed-height layouts such as the product tiles.
  static const double maxTextScaleFactor = 1.1;
  …
            return MaterialApp.router(
              title: 'MyMali',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: router,
              builder: (context, child) => MediaQuery.withClampedTextScaling(
                maxScaleFactor: maxTextScaleFactor,
                child: child ?? const SizedBox.shrink(),
              ),
            );
```

---

## 4. Rules observed in code (not in AGENTS.md, or stated differently)

1. **`withValues(alpha:)` everywhere.** Every translucent colour in `core/widgets` is `role.withValues(alpha: x)`; `withOpacity` appears only in the legacy `rich_text.dart` (deprecated). `HeartToggleButton` scales relative to the existing alpha: `background.withValues(alpha: 0.5 * background.a)`. AGENTS never names the method.
2. **`Semantics` on every tappable component**: `Semantics(button: true, enabled: enabled, label: …, excludeSemantics: true)`; `HeartToggleButton` adds `toggled: isActive`; `OptionTile` adds `inMutuallyExclusiveGroup: true, checked: selected`; `CategoryChip` adds `selected:`; `SlideActionButton` adds `onTap: enabled ? _complete : null` so screen readers activate without the drag; `QuantityStepper._StepButton` adds `label: 'Remove' | 'Decrease quantity' | 'Increase quantity'`; `RatingField` labels `'$star star(s)'`. AGENTS §10/§21 never mention semantics.
3. **Hard-coded `fontSize` is widespread** despite AGENTS §11 ("Change sizes there, never with a hardcoded `fontSize` in a widget"): `PrimaryButton` (bare `TextStyle(fontSize: 16)`), `SearchTriggerBar`/`CustomSearchBar` (15), `FieldDecorator` (16), `CustomTextFormField` (16), `DropdownField` (16/15), `UniversalFormField` dropdown item (16), `OtpInputField` (22), `PhoneTextFormField` (16), `DateSelectorField`/`TimeSelectorField` (16/14), `PrimaryChip` (14), `IconLabledChip` (12), `ActivityChip` (25/10), `DropDownMultiChip` (12), `RichMessageText`. Field text therefore does **not** shrink with `fontSizeFactor`.
4. **Bare `TextStyle` on the primary CTA** contradicts AGENTS §11's own warning ("a bare `TextStyle` drops the font"); harmless today because the body font is the platform default.
5. **`Colors.*` in two non-legacy core files** (AGENTS §11 bans it in widgets): `dropdown_fields.dart` (`Colors.transparent` for the unselected accent bar) and `activity_chip.dart` (`Colors.transparent` surface tint). `app_colors.dart` itself uses `Colors.white`/`Colors.black` (the palette, allowed).
6. **`AppTones` has four tones, not three.** AGENTS §11 lists `success`, `info`, `warning`; code adds `rating` (`AppColors.star`, same on both themes; `const AppTones({…, this.rating = AppColors.star})`), read by `RatingField` and the product detail's star widgets.
7. **`UFFType.rating` / `RatingConfig` / `RatingField` are missing from AGENTS §13's config table**, while `MultiChipDropdownConfig` is listed although `UFFType.dropdownMultiChip` has **no `case`** and falls to `SizedBox.shrink()`; `DropDownMultiChip` is unreachable through the system.
8. **`FieldDecorator` is not the look of every field** (AGENTS §13: "The look … comes from `FieldDecorator` and the theme … To change the look for every field, change `FieldDecorator`"): `CustomSearchBar`, `OtpInputField`, `DateSelectorField` and `TimeSelectorField` build their own decorations (date/time: radius 10.58, `primaryContainer` borders 1.25, `fillColor: colors.surface`, focused `primary` width 2).
9. **`UFFType.date` / `UFFType.time` ignore the field's `label`**: `build()` passes `label: 'Birth Date', hint: 'Select date'` and `label: 'Meeting Time', hint: 'Select time'` regardless.
10. **The button contract is not universal**: `AddButton`, `FilterChipButton`, `OptionTile`, `CategoryChip`, `SectionHeader`'s pill have no `isLoading`; `CategoryChip.onTap` is a required non-null `VoidCallback` (cannot be disabled); `FilterChipButton`/`OptionTile` disable only by dimming the foreground (α0.4) and passing `onTap: null`.
11. **AGENTS §21 catalogue vs code**: `ProductCard` row omits `subtitle` and `imageUrl`; `QuantityStepper` row omits `caption`; statics not catalogued: `ProductCard.compactWidth`, `ProductListTile.thumbnailSize`, `ProductRail.trailingWidthFactor`, `ExploreMoreCard.maxThumbnails`, `CartSummaryBar.height`/`maxThumbnails`, `CategoryChip.defaultWidth`, `AppInfoSheet.defaultActionLabel`; `FieldTitle`, `FieldDecorator.iconTile`, `PrimaryChip` and the three legacy form chips are not in the catalogue; `RichMessageText` is only in §16. Nothing in the catalogue is missing from code.
12. **AGENTS §21 says every component has a test under `test/core/widgets/`**; none exist for `app_logo`, `circle_icon_button`, `info_chip`, `category_chip`, `section_header`, `reload_widget`, `progress_indecator`, `app_search_bar`, `option_tile` (covered inside `app_picker_sheet_test`), `product_grid` (covered inside `product_rail_test`), nor for `otp_input_field`, `custom_search_field`, `dropdown_fields` (only colours), `date_slector_field`, `time_selector_field`, `radio_toggle`, `chip_input_field` (only colours), `drop_down_multi_chip`, `phone_text_form_field` (only locked mode, colours), the form chips.
13. **Component tests pump a bare `MaterialApp(theme: AppTheme.x, home: Scaffold(...))`**, not `App(router: AppRouter().router)` as AGENTS §14's widget-test setup describes (that setup is for pages).
14. **AGENTS §1's stack table omits packages the kit needs**: `loading_animation_widget` (the loading dots of every button), `intl` (`formatRupees`, `DateFormat`), `intl_phone_field` (phone field), and `gap`/`url_launcher` used by features/legacy.
15. **Stock chip wording is fixed in the generic widget**: `'In Stock'`, `'Few left'`, `'Out of stock'`, `'Coming soon'`, `'$discountPercent% OFF'`, `'$soldCount sold'`, `'MRP ₹…'`, `'Add to cart'`, `'View cart'`, `'1 ITEM'/'N ITEMS'`, `'Explore more'`, `'ADD'`, `'Got it'`. AGENTS says generic components carry "no feature text", but these shop strings are inside `core/widgets`.
16. **`QuantityStepper` swallows taps on a disabled step button** so a tappable row behind it is not triggered: `GestureDetector(behavior: HitTestBehavior.opaque, onTap: enabled ? null : () {}, child: InkWell(onTap: onTap, …))`.
17. **`ProductListTile._AddButton` changes its label, not only its state, when out of stock**: `label: inStock ? addLabel : 'Out of stock'`.
18. **Image placeholders in shop widgets use `Icons.eco_outlined`** (a leaf) rather than `AppNetworkImage`'s default `Icons.image_outlined`: `CartSummaryBar._Thumb`, `ExploreMoreCard._Thumbnail`, `OrderLineTile`.
19. **`SlideActionButton` honours `MediaQuery.disableAnimationsOf(context)`** (no hint sweep) and plays its hint once in `didChangeDependencies`, again on enable or label change; `HapticFeedback.mediumImpact()` on completion.
20. **`AppLogo`/`AppNetworkImage` decode at display size**: `cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round()` and `memCacheWidth: ceil(longest side × dpr)`.
21. **`PageHeader` keeps one height via `BoxConstraints(minHeight: contentHeightFor(context) + _padding.vertical)`** and centres a lone title; with `bottom` it becomes `Column[ConstrainedBox(minHeight: rowHeight, row), SizedBox(12), bottom]`.
22. **`AppCard` padding semantics**: a *plain* card (`title == null && accent == null`) pads the container; a titled/accented one pads the body under the header/beside the strip.
23. **Light theme leaves `error`, `primaryContainer`, `onPrimaryContainer`, the `surfaceContainer*` tiers and `outline*` to `ColorScheme.fromSeed`**; only the dark theme pins them. `PageHeader` (`primaryContainer`), `FilterChipButton(onHeader:)`, `OptionTile`, `PrimaryChip` therefore use seed-derived greens on light.
24. **`secondary` means "accent for text/icons on a surface"**: brand green on light, lime on dark; `secondaryContainer` is lime on both. `InfoChip`, `IconListTile` tints, `QuantityStepper` buttons, `SectionHeader` pill text, `ExploreMoreCard` label, `AppInfoSheet` info/success and `AppPickerSheet` tiles all read `secondary`.
25. **`tertiary` = coin gold, `tertiaryContainer` = peach** are the "warm" roles: `PrimaryButton(warm:)`, `SecondaryButton(warm:)`, `InfoChipTone.highlight` (discount, "Few left", "Coming soon").
26. **`inverseSurface`/`onInverseSurface`** = dark scrim roles: `InfoChipTone.dark` ("16 sold", "Out of stock"), `HeartToggleButton(overImage: true)`.
27. **Only `AppNetworkImage` imports `cached_network_image`; only `PhoneTextFormField` imports `intl_phone_field`; only the four pill buttons import `loading_animation_widget`; only `RichMessageText` imports `url_launcher` in core/widgets.** No core widget imports `skeletonizer`, `gap`, a bloc, `get_it` or a feature.

---

## 5. Packages

| Package (pubspec constraint) | Files that import it (this area) | ALWAYS / CONDITIONAL |
|---|---|---|
| `flutter` (`material.dart`; also `services.dart` in `slide_action_button`, `custom_text_form_field`, `phone_text_form_field`, `otp_input_field`, `activity_chip`, `rich_text`, `field_config`; `cupertino.dart` in `progress_indecator`; `gestures.dart` unused import in `rich_text`; `dart:io` in `progress_indecator`; `dart:math` in `page_header`, `slide_action_button`, `product_card`, `quantity_stepper`, `otp_input_field`; `dart:async` in `custom_search_field`, `field_config`) | all | ALWAYS |
| `loading_animation_widget: ^1.3.0` | `buttons/primary_button.dart`, `buttons/secondary_button.dart`, `buttons/dashed_outline_button.dart`, `buttons/slide_action_button.dart` (also `features/auth/.../splash_page.dart`) | ALWAYS (the `isLoading` contract uses `LoadingAnimationWidget.staggeredDotsWave`) |
| `cached_network_image: ^4.0.4` | `app_network_image.dart` only (tests: `app_network_image_test`, `order_line_tile_test`, `product_list_tile_test` import it to assert) | CONDITIONAL(app shows network images) |
| `intl: ^0.20.2` | `lib/core/utils/currency_format.dart` (→ `product_card`, `product_list_tile`, `order_line_tile`), `form_helper/fields/date_slector_field.dart` (also several feature `utils`) | CONDITIONAL(app shows prices or uses `UFFType.date`); in practice ALWAYS with the form system |
| `intl_phone_field: ^3.2.0` | `form_helper/fields/phone_text_form_field.dart` (`intl_phone_field.dart`, `countries.dart show countries`) | CONDITIONAL(app takes phone numbers) |
| `url_launcher: ^6.2.5` | `rich_text.dart` (legacy) | not needed by the kit (features use it independently) |
| `skeletonizer: ^3.0.0` | no core widget; feature skeletons (`cart_loading_skeleton.dart`, `home_loading_skeleton.dart`, `wishlist_loading_skeleton.dart`, `product_detail_skeleton.dart`, …) | CONDITIONAL(app shows loading skeletons) — AGENTS §21 mandates it for every loading state |
| `gap: ^3.0.1` | no core widget; only `features/auth/presentation/login/widgets/login_details_step.dart`, `login_otp_step.dart` | not needed by the kit |
| `cupertino_icons: ^1.0.8` | none in this area | not needed by the kit |
| Font asset `assets/fonts/Marcellus-Regular.ttf` (family `Marcellus`) | `AppTheme.displayFontFamily` → `PageHeader`, `SectionHeader`, `AppPickerSheet` | ALWAYS (substitute the family and file) |
| Image assets `assets/icon.png`, `assets/applogo.png`, `assets/coin.png` | `AppAssets` → `AppLogo` | ALWAYS for `icon`; `coin` is MyMali |

---

## 6. What varies per app

| Thing | Where it appears |
|---|---|
| Every colour value | `AppColors` (28 consts); the `ColorScheme.fromSeed` override lists in `AppTheme.light`/`dark`; `AppTones.light`/`dark` |
| Which `ColorScheme` roles are pinned vs seed-derived | `AppTheme` (light pins 13 roles, dark pins 25) |
| `fontSizeFactor` (0.88) | `AppTheme.fontSizeFactor`; every `heightFor` depends on it |
| Display font (`'Marcellus'`, one weight, `FontWeight.w400`) | `AppTheme.displayFontFamily`; `pubspec.yaml` `fonts:`; `PageHeader`, `SectionHeader`, `AppPickerSheet` |
| Text scale cap (1.1) and app title | `App.maxTextScaleFactor`, `MaterialApp.router(title: 'MyMali')` in `lib/app/app.dart` |
| Asset paths and files | `AppAssets.icon/appLogo/coin`; `pubspec.yaml` `assets:`; `AppLogo(asset:)` default |
| Logo semantics | `AppLogo.semanticLabel = 'My Mali'` |
| Currency, locale, wording | `formatRupees`, `NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)`; `'MRP '` prefix in `ProductCard._PriceBlock`; `'$quantity × ₹'` in `OrderLineTile` |
| Default country | `UniversalFormField.build` phone `initialCountryCode ?? "IN"`; `PhoneTextFormField._buildLocked` fallback `'IN'` |
| Default user-facing strings | `'Back'` (PageHeader), `'Close'` (sheets), `'Got it'` (`AppInfoSheet.defaultActionLabel`), `'Retry'` (ReloadWidget), `'Search'` (`AppSearchBar`, `SearchTriggerBar`), `'Search with a photo'`, `'products'` label inside `AppSearchBar`, `'View cart'`, `'1 ITEM'`/`'N ITEMS'`, `'Explore more'`, `'ADD'`, `'Add to cart'`, `'In Stock'`, `'Few left'`, `'Out of stock'`, `'Coming soon'`, `'% OFF'`, `' sold'`, `'Remove'`/`'Decrease quantity'`/`'Increase quantity'`, `'Birth Date'`/`'Select date'`, `'Meeting Time'`/`'Select time'`, `'Add value'`/`'Type and press done or +'`/`'Please add at least …'`, `'Search ${label}...'` |
| Placeholder icons | `Icons.image_outlined` (`AppNetworkImage` default), `Icons.eco_outlined` (cart/explore/order thumbnails), `Icons.shopping_bag_outlined` (`ProductListTile.addIcon`, sold badge), `Icons.photo_camera_outlined` (search camera), `Icons.arrow_forward_rounded` (slide thumb, section header, explore), `Icons.add_rounded` (dashed button, add button, stepper), `Icons.delete_outline_rounded` (stepper at one), `Icons.favorite_rounded`/`favorite_border_rounded`, `Icons.info_outline_rounded`/`task_alt_rounded`/`error_outline_rounded` (sheet tones), `Icons.close_rounded`, `Icons.chevron_right_rounded`, `Icons.expand_more_rounded`, `Icons.keyboard_arrow_down(_rounded)`, `Icons.star_rounded`/`star_outline_rounded`, `Icons.calendar_today_rounded`, `Icons.access_time_rounded`, `Icons.search_rounded`, `Icons.clear_rounded`, `Icons.refresh` |
| Package name in absolute imports | `package:mymali/core/widgets/...` in `universal_form_field.dart`, `drop_down_multi_chip.dart`, `chip_input_field.dart` (every other file uses relative imports) |
| Layout constants (keep unless the brand needs otherwise) | heights 56/64/34/40/44; radii 22 (card, product card, explore), 20 (list tile), 18 (dashed, category tile, filled list tile), 16 (option tile), 14 (fields, info sheet tile, thumb), 12 (add button, stepper, icon frames), 10 (info chip), 28 (page header bottom, search pill); `ProductGrid.spacing 14`; `ProductCard.compactWidth 160`; `CartSummaryBar.height 44`; `SlideActionButton.completeAt 0.8` |
| `UFFType` members that stay dead for parity | `year, address, switchBtn, multiSelect, multiText, slider, checkbox, upload, singleCheckbox, incDec, dateTimePicker, locationWithTextSearch, richTextEditor, multiDocumentSelect, chatTextBox, dropdownMultiChip` and their configs; `ChatTextBoxConfig`/`MessageType` are CRM leftovers |
| Which CONDITIONAL groups to install | `product/*`, `cart/*`, `buttons/add_button`, `buttons/heart_toggle_button`, `buttons/slide_action_button`, `chips/category_chip`, `search/*`, `app_network_image`, `form_helper/fields/{phone_text_form_field, otp_input_field, rating_field, custom_search_field}` |

---

## 7. Gotchas

1. **Misspelt names are part of the contract**: `progress_indecator.dart` / `ProgressIndecator`, `date_slector_field.dart`, `icon_labled_chip.dart` / `IconLabledChip`, `MultiChipConfig.onSumbitValidator`, `WidgetOrder.NORMAL`/`REVERSED` (uppercase), `MessageType.*` snake_case. Renaming them makes a second spelling.
2. **`UniversalFormField` is not a `Widget`.** It is a plain class whose `build({…})` returns a `Widget`; it is re-instantiated on every parent rebuild. Its `textEditingController = TextEditingController()` field is therefore new each rebuild. Consequence (the rule AGENTS §13 states): with `initialValue == null` and no `useController`, the text field gets that throwaway controller and typing breaks; with `initialValue: ''` (non-null) the `TextFormField` gets `initialValue` and `controller: null` and keeps its own state. With `useController: true` pass your own `controller`.
3. **`UniversalFormField.key` only reaches the dropdown** (`DropdownField(key: key)`); `updateKey: true` only affects the text field (`Key(initialValue ?? '')`, a dynamic-to-String cast that throws if `initialValue` is not a `String`). To reset any other field, change the `ValueKey` of the `KeyedSubtree` around it.
4. **`build()` constructs a `CustomTextFormField` eagerly for every `fieldType`**, then discards it unless `text`. Harmless but surprising when debugging.
5. **`UFFType.dropdownMultiChip` has no `case`** → `SizedBox.shrink()`; `multiChipDropdownConfig` and five other `build` parameters are accepted and ignored. `DropDownMultiChip` is only reachable by constructing it directly.
6. **`UFFType.date`/`time` hard-code `'Birth Date'`/`'Meeting Time'`** and their hints; the `label` you pass is only used by `withTitle`.
7. **`FieldDecorator`'s `enabled` defaults to `false` and only changes the error border width** (0.8 enabled, 1.2 otherwise); the factory's `floatingLabelBehavior` parameter is accepted but the private constructor always sets `FloatingLabelBehavior.auto`; `label` is a `Text` widget via `label:` for text fields but `labelText:` for dropdowns; an empty `label` yields no label at all (so `withTitle` reserves no floating space).
8. **`CustomTextFormField.autovalidateMode` defaults to `onUserInteraction`, but through `TextInputConfig` the default is `disabled`.** `onTap` is a no-op unless `isTimeField`. Email/password variants (`TextInputFieldType`) add their own prefix/suffix icons and drop the caller's `prefix`.
9. **`CustomSearchBar` debounces `onChanged` (300 ms) but not `onSubmitted`**; the clear button fires `onChanged('')` immediately and refocuses. `AppSearchBar` hard-codes `label: 'products'` and `borderRadius: 28`.
10. **`PhoneTextFormField` has two different looks**: `lockCountryCode: false` renders `IntlPhoneField` (no flag, trailing dropdown icon) and reports `phone.number` only; `true` renders a plain `TextField` with `'+<dialCode>'` prefix, `maxLength: country.maxLength`, digits-only formatter by default, and `keyboardType: TextInputType.phone`.
11. **`OtpInputField`**: the visible boxes never receive focus; a `Positioned.fill(Opacity(0, TextField(...)))` does (`showCursor: false`, `enableInteractiveSelection: false`, `maxLength: length`, `autofillHints: [AutofillHints.oneTimeCode]`, `FilteringTextInputFormatter.digitsOnly`). `onCompleted` fires when `value.length == length`.
12. **`DropdownField` uses `DropdownButtonFormField(initialValue: widget.value)`** and `selectedItemBuilder`; the field's `floatingLabelBehavior` is computed (`never` with no value, `always` with one) but ignored by `FieldDecorator._` (see 7). `UniversalFormField` wraps it in `IgnorePointer(ignoring: isLoading)` with a 18×18 `ProgressIndecator(strokeWidth: 2)` at `right: 40`.
13. **`RadioToggle` is a `Switch.adaptive`**, not a radio; `UFFType.radio` therefore yields a boolean toggle (`initialValue ?? false`).
14. **`ProgressIndecator` imports `dart:io`** (`Platform.isIOS`): it does not compile for web. Fine for this portrait, mobile-only app.
15. **`ProductCard.detailsHeightFor` must mirror `build`** (`2 * _padding + titleMedium + bodySmall + _variantGap + chip + _gap + chip + _gap + max(titleLarge + bodySmall, 40) + 2`); `ProductGrid.tileHeightFor` and `ProductRail` depend on it. The stepper is 36/28 on a compact tile (`constraints.maxWidth < 160 − 24 = 136`), else 40/34, and `_controlHeight` (40) is what the height helper reserves.
16. **`PageHeader.contentHeightFor` mirrors `build`** with `_padding = EdgeInsets.fromLTRB(16, 2, 16, 8)`, back button 36, subtitle gap 2; `onBack == null` disables the back button but still draws it.
17. **`AppInfoSheet.show` returns `acted ?? false`** (dismissal = `false`); `AppPickerSheet.show<T>` returns `null` on dismissal. Both open on the root navigator (above the bottom bar) with `useSafeArea`, `isScrollControlled`, `showDragHandle`. The picker's `onClose` default pops with no value.
18. **Light theme `error` is Material's default red, not coral**; only the dark theme overrides `error: AppColors.coral`. Light `primaryContainer`/`onPrimaryContainer` come from the seed algorithm, so the exact header tint on light depends on the Flutter version's `ColorScheme.fromSeed`.
19. **`secondary` differs between themes** (brand green on light, lime on dark) while `secondaryContainer` is lime on both — do not "simplify" one into the other; `InfoChipTone.outline`/`accent`, `QuantityStepper` buttons and `IconListTile` tints rely on the difference for contrast.
20. **`SlideActionButton` tests rely on the hint stopping by itself** (`pumpAndSettle` works) and on `isLoading` dots never settling (`pump(const Duration(milliseconds: 500))`). `completeAt` is 0.8 of the travel, or a fling > 700 px/s past 0.5.
21. **`HeartToggleButton` disabled alpha is relative** (`0.5 * background.a`) because the over-image scrim is already translucent; `CircleIconButton` uses a flat `withValues(alpha: 0.5)`.
22. **`CategoryChip.onTap` is non-nullable**; wrap in `IgnorePointer`/pass a no-op if you need an inert chip (AGENTS §12 forbids `IgnorePointer` for buttons, but this chip has no disabled state).
23. **`QuantityStepper` disabled buttons eat the tap** (opaque `GestureDetector`) so a parent `InkWell` (a cart row) does not open the product page.
24. **`ProductListTile.framed: false`** changes padding from `LTRB(11, 11, 11, 13)` to `all(16)` and removes the card; `controlPlacement: trailing` caps the control column at 55 % of the row width and centres the row vertically.
25. **Cart/explore/order thumbnails use `Icons.eco_outlined`**; a non-garden app substitutes the placeholder in `CartSummaryBar._Thumb`, `ExploreMoreCard._Thumbnail`, `OrderLineTile`.
26. **`formatRupees` is INR-only** (`en_IN`, `₹`, no paise): tests assert `'₹1,249'`, `'2 × ₹1,249'`, `'MRP ₹595'`. A different currency changes test expectations and the `'MRP '` wording.
27. **The three `package:mymali/...` absolute imports** (`universal_form_field.dart`, `drop_down_multi_chip.dart`, `chip_input_field.dart`) must be rewritten to the target package name; every other core widget uses relative imports.
28. **Analyzer baseline for this area** (so a port knows which infos are expected): `rich_text.dart` — `unused_import` (`gestures.dart`), `unused_element` (`_showSnackBar`), `deprecated_member_use` ×2 (`withOpacity`); `field_config.dart` — `constant_identifier_names` ×30 (`WidgetOrder`, `MessageType`); `field_decorator.dart:56` — `use_super_parameters` (`hintText`); `radio_toggle.dart:16` and `universal_form_field.dart:220` — `avoid_unnecessary_containers`. No errors or warnings elsewhere.
29. **Minimum toolchain**: `sdk: ^3.13.4`; `withValues`/`.a`, `Row(spacing:)`, `[?x]`, `DropdownButtonFormField(initialValue:)`, `Switch.adaptive(activeThumbColor:)`, `MediaQuery.withClampedTextScaling`, `textScalerOf`. An older Flutter fails to compile `dropdown_fields.dart`, `radio_toggle.dart`, `custom_search_field.dart` and every `withValues` call.
30. **`AppTones.of(context)` falls back to `AppTones.light`** when the extension is missing (e.g. a bare `MaterialApp()` in a test), so star colours still render.
31. **`IconListTile` pads itself** (16 h, 10 v; dense 7 v; filled 14/14) and `SectionLabel` pads itself (`LTRB(16, 20, 16, 8)`); `FormSectionTitle` pads only above (`topPadding`, default 24) plus 12 below; `OrderLineTile` pads 10 vertically; `AppCard` pads 20 all round by default. Do not add outer padding at call sites that these already provide.
