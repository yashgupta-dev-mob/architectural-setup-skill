// Copies MyMali's core services and widgets into a Flutter project.
//
//   dart <skill>/tool/install_core.dart --list
//   dart <skill>/tool/install_core.dart --project . --modules base,prefs --hosts api
//
// Options:
//   --project <dir>    the Flutter project (default: current directory)
//   --modules <a,b>    modules to install; `base` is always included, and a
//                      module's dependencies are added for you
//   --hosts <a,b>      the ApiHost values, one per backend the app calls;
//                      the first is the default (default: supabase)
//   --dry-run          print what would be written, write nothing
//   --force            overwrite files that already exist in the project
//
// It never overwrites a file the project already has unless --force is given;
// such files are listed as conflicts. It prints the `flutter pub add` line for
// the packages the chosen modules need, and never edits pubspec.yaml itself.
import 'dart:io';

/// Every module, in install order, with what it needs.
const Map<String, ({List<String> deps, List<String> packages, String why})>
modules = {
  'base': (
    deps: [],
    packages: [
      'flutter_bloc',
      'bloc',
      'equatable',
      'fpdart',
      'get_it',
      'go_router',
      'dio',
      'flutter_dotenv',
      'loading_animation_widget',
      'intl',
      'intl_phone_field',
      'skeletonizer',
    ],
    why: 'always: networking, Failure/UseCase, theme, UI kit, form system',
  ),
  'prefs': (
    deps: [],
    packages: ['shared_preferences'],
    why: 'the app stores flags, settings or a device-first list',
  ),
  'secure-storage': (
    deps: ['prefs'],
    packages: ['flutter_secure_storage'],
    why: 'the app keeps an auth token or session',
  ),
  'supabase-session': (
    deps: ['secure-storage'],
    packages: ['supabase_flutter'],
    why: 'the app signs in with Supabase Auth',
  ),
  'local-cache': (
    deps: [],
    packages: ['hive_ce', 'hive_ce_flutter'],
    why: 'the app already saves server data and shows it before the network',
  ),
  'network-images': (
    deps: [],
    packages: ['cached_network_image'],
    why: 'the app shows images loaded from URLs',
  ),
  'app-logo': (
    deps: [],
    packages: [],
    why: 'the app shows a bundled logo (needs AppAssets.icon)',
  ),
  'analytics': (
    deps: [],
    packages: [],
    why: 'the app already reports analytics events',
  ),
  'katyayani-core': (
    deps: ['analytics'],
    packages: [
      'katyayani_core',
      'firebase_core',
      'flutter_local_notifications',
    ],
    why: 'the app already uses Katyayani Core push / events',
  ),
  'ga4-meta': (
    deps: ['analytics'],
    packages: [
      'firebase_analytics',
      'facebook_app_events',
      'app_tracking_transparency',
    ],
    why: 'the app already sends events to Google Analytics 4 or Meta',
  ),
  'commerce-widgets': (
    deps: ['network-images'],
    packages: [],
    why: 'the app sells products (cards, grids, rails, cart bar, stepper)',
  ),
  'payments-razorpay': (
    deps: [],
    packages: ['razorpay_flutter'],
    why: 'the app already takes payments with Razorpay',
  ),
};

void main(List<String> args) {
  final options = _parse(args);
  final skillDir = File.fromUri(Platform.script).parent.parent;
  final templates = Directory('${skillDir.path}/templates');

  if (options.containsKey('list')) {
    for (final entry in modules.entries) {
      final v = entry.value;
      stdout.writeln(
        '${entry.key.padRight(18)} ${v.why}'
        '${v.deps.isEmpty ? '' : '  [needs ${v.deps.join(', ')}]'}',
      );
    }
    return;
  }

  final project = Directory(options['project'] ?? '.');
  final pubspec = File('${project.path}/pubspec.yaml');
  if (!pubspec.existsSync()) {
    _fail('No pubspec.yaml in ${project.absolute.path}');
  }
  final name = RegExp(
    r'''^name:\s*["']?([A-Za-z0-9_]+)["']?''',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync())?.group(1);
  if (name == null) _fail('Cannot read the package name from pubspec.yaml');

  final wanted = {
    'base',
    ...?options['modules']?.split(',').map((m) => m.trim()),
  }..removeWhere((m) => m.isEmpty);
  for (final m in wanted) {
    if (!modules.containsKey(m)) _fail('Unknown module "$m". Try --list.');
  }
  // Add dependencies until nothing changes.
  var grew = true;
  while (grew) {
    grew = false;
    for (final m in wanted.toList()) {
      for (final d in modules[m]!.deps) {
        grew |= wanted.add(d);
      }
    }
  }
  final ordered = modules.keys.where(wanted.contains).toList();

  final hosts = (options['hosts'] ?? 'supabase')
      .split(',')
      .map((h) => h.trim())
      .where((h) => h.isNotEmpty)
      .toList();
  for (final h in hosts) {
    if (!RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(h)) {
      _fail('Host "$h" must be a lowerCamelCase Dart identifier.');
    }
  }
  final dryRun = options.containsKey('dry-run');
  final force = options.containsKey('force');

  // Later modules replace earlier ones' copy of a file (e.g. ga4-meta's
  // AppEvents over analytics' empty one).
  final planned = <String, File>{};
  for (final m in ordered) {
    final dir = Directory('${templates.path}/$m');
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      final rel = f.path.substring(dir.path.length + 1).replaceAll(r'\', '/');
      // Skip .DS_Store and other dotfiles a copy of the skill may carry.
      if (rel.split('/').any((part) => part.startsWith('.'))) continue;
      planned[rel] = f;
    }
  }

  final written = <String>[];
  final conflicts = <String>[];
  for (final entry in planned.entries) {
    final target = File('${project.path}/${entry.key}');
    if (target.existsSync() && !force) {
      conflicts.add(entry.key);
      continue;
    }
    final text = _adapt(entry.value.readAsStringSync(), name, hosts);
    if (!dryRun) {
      target.parent.createSync(recursive: true);
      target.writeAsStringSync(text);
    }
    written.add(entry.key);
  }

  // The rulebook, trimmed to the installed modules.
  final rules = _rulesFor(
    File('${skillDir.path}/rules/AGENTS.md')
        .readAsStringSync()
        .replaceAll('\r\n', '\n'),
    ordered.toSet(),
  );
  final agents = File('${project.path}/AGENTS.md');
  // A rulebook this installer wrote before may be replaced; the app's own
  // rules never are.
  final ours =
      agents.existsSync() && agents.readAsStringSync().startsWith(_rulesTitle);
  final rulesPath = agents.existsSync() && !ours && !force
      ? 'AGENTS.mymali.md'
      : 'AGENTS.md';
  final claude = File('${project.path}/CLAUDE.md');
  if (!dryRun) {
    File('${project.path}/$rulesPath').writeAsStringSync(rules);
    if (!claude.existsSync()) claude.writeAsStringSync('@AGENTS.md\n');
  }
  written.add(rulesPath);
  if (rulesPath != 'AGENTS.md') {
    conflicts.add('AGENTS.md (rules written to $rulesPath: merge them)');
  }
  if (claude.existsSync() &&
      !claude.readAsStringSync().contains('@AGENTS.md')) {
    conflicts.add('CLAUDE.md (add a line "@AGENTS.md")');
  }

  final packages = {for (final m in ordered) ...modules[m]!.packages}.toList()
    ..sort();
  stdout
    ..writeln('Modules: ${ordered.join(', ')}')
    ..writeln('Hosts: ${hosts.join(', ')} (default ${hosts.first})')
    ..writeln('${dryRun ? 'Would write' : 'Wrote'} ${written.length} files.');
  if (conflicts.isNotEmpty) {
    stdout.writeln(
      '\nNot written, the project already has them (merge by hand, '
      'keeping MyMali\'s names, or re-run with --force):',
    );
    for (final c in conflicts) {
      stdout.writeln('  $c');
    }
  }
  stdout
    ..writeln('\nAdd the packages (only those the project lacks):')
    ..writeln('  flutter pub add ${packages.join(' ')}')
    ..writeln(
      '\nThen fill in the per-app files (SKILL.md step 3): env.dart (+ .env, '
      '.env.example), endpoints.dart, base_api_repository.dart (timeouts), '
      'app_colors.dart, app_theme.dart, app_assets.dart, '
      'injection_container.dart, and write bootstrap.dart, app.dart, '
      'app_routes.dart, app_router.dart, navigator_keys.dart.',
    );
  if (hosts.length > 1) {
    stdout.writeln(
      'Each extra host needs its base URL before the project compiles: '
      '${hosts.skip(1).map((h) => 'Endpoints.${h}BaseUrl').join(', ')} '
      '(from an Env getter).',
    );
  }
}

/// The first line of rules/AGENTS.md, used to recognise our own rulebook.
const String _rulesTitle = '# Rules for AI agents and developers';

/// Rewrites a template for the target project.
String _adapt(String text, String package, List<String> hosts) {
  // Templates may have been checked out with CRLF; the patterns expect LF.
  var out = text.replaceAll('\r\n', '\n');
  out = out.replaceAll('package:mymali/', 'package:$package/');
  // The marker line is for the skill's maintainers only.
  out = out.replaceFirst(RegExp(r'^// GENERIC:[^\n]*\n'), '');
  out = out.replaceAll(
    RegExp(r'enum ApiHost \{\n  supabase,\n\}'),
    'enum ApiHost {\n${hosts.map((h) => '  $h,\n').join()}}',
  );
  out = out.replaceAll('ApiHost.supabase', 'ApiHost.${hosts.first}');
  // One Dio per host; every host after the first needs its own base URL.
  out = out.replaceAll(
    RegExp(
      r'ApiHost\.\w+: Dio\(BaseOptions\(baseUrl: Endpoints\.baseUrlMain\)\),',
    ),
    [
      'ApiHost.${hosts.first}: Dio(BaseOptions(baseUrl: Endpoints.baseUrlMain)),',
      for (final h in hosts.skip(1))
        'ApiHost.$h: Dio(BaseOptions(baseUrl: Endpoints.${h}BaseUrl)),',
    ].join('\n    '),
  );
  return out;
}

/// Keeps `<!-- module: x -->…<!-- /module -->` blocks only for installed
/// modules, and drops the markers themselves.
String _rulesFor(String text, Set<String> installed) {
  final block = RegExp(
    r'<!-- module: ([a-z-]+) -->\n(.*?)<!-- /module -->\n?',
    dotAll: true,
  );
  return text.replaceAllMapped(
    block,
    (m) => installed.contains(m.group(1)) ? m.group(2)! : '',
  );
}

Map<String, String?> _parse(List<String> args) {
  final out = <String, String?>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (!a.startsWith('--')) _fail('Unexpected argument "$a".');
    final key = a.substring(2);
    if (const {'list', 'dry-run', 'force'}.contains(key)) {
      out[key] = null;
    } else {
      if (i + 1 >= args.length) _fail('$a needs a value.');
      out[key] = args[++i];
    }
  }
  return out;
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(64);
}
