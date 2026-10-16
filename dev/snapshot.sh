#!/usr/bin/env bash
# Copies MyMali's shareable core files into the skill's templates, one folder
# per module. Re-run whenever MyMali's core changes, then re-apply the
# generic edits listed in dev/GENERIC_EDITS.md (files marked GENERIC below
# are NOT overwritten: they are hand-made generic versions).
#
# usage: bash dev/snapshot.sh [path-to-mymali]
set -euo pipefail

MYMALI="${1:-/c/Users/Katyayani/Documents/flutter/mymali}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$ROOT/applying-mymali-architecture/templates"

copy() { # module path...
  local module="$1"; shift
  for p in "$@"; do
    local dst="$T/$module/$p"
    if [ -f "$dst" ] && head -3 "$dst" | grep -q 'GENERIC'; then continue; fi
    mkdir -p "$(dirname "$dst")"
    cp "$MYMALI/$p" "$dst"
  done
}

W=lib/core/widgets
TW=test/core/widgets

# ---- base: every migrated app gets these -------------------------------
copy base \
  lib/core/app/api/api_response.dart \
  lib/core/app/exceptions/app_exceptions.dart \
  lib/core/app/exceptions/api_exceptions.dart \
  lib/core/app/failure.dart \
  lib/core/usecases/usecase.dart \
  lib/core/utils/json_readers.dart \
  lib/core/services/networking/curl_logger_interceptor.dart \
  lib/core/services/secure_storage/secure_storage.dart \
  lib/core/theme/app_tones.dart \
  $W/buttons/primary_button.dart $W/buttons/secondary_button.dart \
  $W/buttons/circle_icon_button.dart \
  $W/sheets/app_info_sheet.dart $W/sheets/app_picker_sheet.dart $W/sheets/option_tile.dart \
  $W/page_header.dart $W/app_card.dart $W/reload_widget.dart $W/progress_indecator.dart \
  $W/section_header.dart $W/section_label.dart $W/icon_list_tile.dart \
  $W/form_section_title.dart \
  $W/chips/info_chip.dart $W/chips/filter_chip_button.dart $W/chips/category_chip.dart \
  $W/search/app_search_bar.dart $W/search/search_trigger_bar.dart \
  test/helpers/fake_networking.dart \
  test/core/services/networking/curl_logger_interceptor_test.dart \
  $TW/buttons/primary_button_test.dart $TW/buttons/secondary_button_test.dart \
  $TW/sheets/app_info_sheet_test.dart $TW/sheets/app_picker_sheet_test.dart \
  $TW/page_header_test.dart $TW/app_card_test.dart $TW/section_label_test.dart \
  $TW/icon_list_tile_test.dart $TW/form_section_title_test.dart \
  $TW/chips/filter_chip_button_test.dart $TW/search/search_trigger_bar_test.dart \
  $TW/form_helper/universal_form_field_test.dart \
  $TW/form_helper/field_theme_colors_test.dart \
  $TW/form_helper/fields/rating_field_test.dart

# The whole form system.
( cd "$MYMALI" && find $W/form_helper -name '*.dart' ) | while read -r f; do copy base "$f"; done

# ---- optional modules: only when the app already does that thing --------
copy prefs lib/core/services/pref_utils.dart

copy secure-storage \
  lib/core/services/secure_storage/device_secure_storage.dart \
  test/helpers/fake_secure_storage.dart \
  test/core/services/secure_storage/device_secure_storage_test.dart

copy supabase-session \
  lib/core/services/secure_storage/secure_session_storage.dart \
  test/core/services/secure_storage/secure_session_storage_test.dart

copy local-cache \
  lib/core/services/local_cache/local_cache.dart \
  lib/core/services/local_cache/hive_local_cache.dart \
  lib/core/services/local_cache/cache_boxes.dart \
  lib/core/app/exceptions/cache_exceptions.dart \
  test/helpers/fake_local_cache.dart \
  test/core/services/local_cache/hive_local_cache_test.dart

copy network-images $W/app_network_image.dart $TW/app_network_image_test.dart

copy app-logo $W/app_logo.dart

copy analytics \
  lib/core/services/analytics/analytics_service.dart \
  lib/core/services/analytics/analytics_item.dart \
  lib/core/services/analytics/analytics_destination.dart

copy katyayani-core \
  lib/core/services/katyayani_core/ko_engagement_service.dart \
  lib/core/services/katyayani_core/ko_engagement_service_impl.dart \
  lib/core/services/katyayani_core/kc_identity.dart \
  lib/core/services/analytics/ko_analytics_service.dart \
  lib/core/services/local_notifications/local_notification_service.dart \
  lib/core/services/local_notifications/local_notification_service_impl.dart \
  test/core/services/katyayani_core/kc_identity_test.dart \
  test/core/services/analytics/ko_analytics_service_test.dart \
  test/core/services/analytics/multi_destination_analytics_service_test.dart \
  test/helpers/fake_ko_engagement_service.dart

copy ga4-meta \
  lib/core/services/analytics/multi_destination_analytics_service.dart \
  lib/core/services/analytics/analytics_event_mapper.dart \
  lib/core/services/analytics/firebase_analytics_destination.dart \
  lib/core/services/analytics/meta_analytics_destination.dart \
  lib/core/services/analytics/app_events.dart \
  test/core/services/analytics/meta_analytics_destination_test.dart \
  test/core/services/analytics/analytics_event_mapper_test.dart

copy commerce-widgets \
  $W/product/product_card.dart $W/product/product_list_tile.dart \
  $W/product/product_grid.dart $W/product/product_rail.dart \
  $W/product/explore_more_card.dart $W/product/order_line_tile.dart \
  $W/product/quantity_stepper.dart $W/cart/cart_summary_bar.dart \
  $W/buttons/heart_toggle_button.dart $W/buttons/add_button.dart \
  $W/buttons/slide_action_button.dart $W/buttons/dashed_outline_button.dart \
  lib/core/utils/currency_format.dart \
  $TW/product/product_card_test.dart $TW/product/product_list_tile_test.dart \
  $TW/product/product_rail_test.dart $TW/product/explore_more_card_test.dart \
  $TW/product/order_line_tile_test.dart $TW/product/quantity_stepper_test.dart \
  $TW/cart/cart_summary_bar_test.dart $TW/buttons/heart_toggle_button_test.dart \
  $TW/buttons/add_button_test.dart $TW/buttons/slide_action_button_test.dart \
  $TW/buttons/dashed_outline_button_test.dart \
  test/core/utils/currency_format_test.dart

copy payments-razorpay \
  lib/core/services/payments/payment_gateway.dart \
  lib/core/services/payments/razorpay_payment_gateway.dart \
  test/helpers/fake_payment_gateway.dart \
  test/core/services/payments/razorpay_payment_gateway_test.dart

# MyMali's own analysis options tolerate these lints in a few legacy-shaped
# files. A migrated app must analyze clean, so silence them per file rather
# than renaming MyMali's members.
ignore() { # file rules
  local f="$T/$1"
  [ -f "$f" ] || return 0
  grep -q '^// ignore_for_file:' "$f" && return 0
  if head -1 "$f" | grep -q '^// GENERIC'; then
    sed -i "1a // ignore_for_file: $2" "$f"
  else
    sed -i "1i // ignore_for_file: $2" "$f"
  fi
}
ignore base/lib/core/widgets/form_helper/fields/radio_toggle.dart avoid_unnecessary_containers
ignore base/lib/core/widgets/form_helper/universal_form_field.dart avoid_unnecessary_containers
ignore base/lib/core/widgets/form_helper/field_config.dart constant_identifier_names
ignore base/lib/core/widgets/form_helper/decorator/field_decorator.dart use_super_parameters
ignore base/lib/core/app/exceptions/app_exceptions.dart "annotate_overrides, overridden_fields"
ignore base/lib/core/services/networking/curl_logger_interceptor.dart prefer_initializing_formals
ignore base/lib/core/services/networking/networking.dart "prefer_initializing_formals, use_null_aware_elements"
ignore prefs/lib/core/services/pref_utils.dart avoid_print
ignore local-cache/lib/core/services/local_cache/hive_local_cache.dart prefer_initializing_formals
ignore ga4-meta/lib/core/services/analytics/multi_destination_analytics_service.dart prefer_initializing_formals
ignore katyayani-core/lib/core/services/katyayani_core/ko_engagement_service_impl.dart prefer_initializing_formals

echo "snapshot done → $T"
