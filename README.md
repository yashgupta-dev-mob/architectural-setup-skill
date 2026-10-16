# MyMali architecture skill

A Claude Code skill that restructures any Flutter app into the MyMali
architecture: the same folders, class and file names, services and UI kit
as the MyMali app. **It keeps what the app does.** A feature that only
calls the network stays network-only. One that shows a saved copy first
keeps doing that, now with `LocalCache`. One whose data lives on the device
keeps that too, through `PrefUtils`. Nothing is added "for later".

## Install

Copy the `applying-mymali-architecture` folder into your Claude Code skills
folder:

| OS | Folder |
|---|---|
| Windows | `%USERPROFILE%\.claude\skills\` |
| macOS / Linux | `~/.claude/skills/` |

Restart Claude Code. Then, in the Flutter project you want to restructure:

> Use the applying-mymali-architecture skill to restructure this app.

## What is inside

| Path | What it is |
|---|---|
| `applying-mymali-architecture/SKILL.md` | The procedure Claude follows |
| `applying-mymali-architecture/audit.md` | How the app's current behaviour is recorded first (`BEHAVIORS.md`) |
| `applying-mymali-architecture/templates/` | MyMali's core code, split into modules (`base`, `prefs`, `secure-storage`, `local-cache`, `network-images`, `analytics`, …) |
| `applying-mymali-architecture/tool/install_core.dart` | Copies the chosen modules into a project (`dart tool/install_core.dart --list`) |
| `applying-mymali-architecture/rules/AGENTS.md` | The rulebook copied into the app, trimmed to its modules |
| `applying-mymali-architecture/reference/` | The app shell in MyMali's shape, and one whole MyMali feature with its tests |
| `dev/` | For maintainers: test harness, sample apps, snapshot script |

## Keeping it in step with MyMali

When MyMali's `lib/core` changes, refresh the templates:

```bash
bash dev/snapshot.sh /path/to/mymali
```

Files whose first line starts with `// GENERIC:` are hand-made generic
versions and are not overwritten; update them by hand if the MyMali file
they mirror changed. Then check every module still builds:

```bash
cd dev && flutter create compilecheck && cd compilecheck
dart ../../applying-mymali-architecture/tool/install_core.dart \
  --modules prefs,supabase-session,local-cache,network-images,commerce-widgets,payments-razorpay,ga4-meta,katyayani-core,app-logo \
  --hosts supabase,medusa
# add the packages it prints, give Endpoints a medusaBaseUrl, then:
flutter analyze && flutter test
```
