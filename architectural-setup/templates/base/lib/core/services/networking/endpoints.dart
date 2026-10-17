// GENERIC: per app. Base URLs from Env; one class of relative paths per host.
import 'package:template_app/core/config/env.dart';

class Endpoints {
  // sample endpoint -
  //! "/login"
  //! if any path params - "/text/{userId}/{key}"

  static String baseUrlMain = Env.baseUrl;
}
