# Architectural setup skill

A Claude Code skill that restructures any Flutter app into the company's
standard architecture: the same folders, class and file names, services and
UI kit everywhere (the templates come from the MyMali app's `lib/core`).
**It keeps what the app does.** A feature that only
calls the network stays network-only. One that shows a saved copy first
keeps doing that, now with `LocalCache`. One whose data lives on the device
keeps that too, through `PrefUtils`. Nothing is added "for later".

## Install

Copy the `architectural-setup` folder into your Claude Code skills
folder:

| OS | Folder |
|---|---|
| Windows | `%USERPROFILE%\.claude\skills\` |
| macOS / Linux | `~/.claude/skills/` |

Restart Claude Code. Then, in the Flutter project you want to restructure:

> Use the architectural-setup skill to restructure this app.

## What is inside

| Path | What it is |
|---|---|
| `architectural-setup/SKILL.md` | The procedure Claude follows |
| `architectural-setup/audit.md` | How the app's current behaviour is recorded first (`BEHAVIORS.md`) |
| `architectural-setup/templates/` | MyMali's core code, split into modules (`base`, `prefs`, `secure-storage`, `local-cache`, `network-images`, `analytics`, …) |
| `architectural-setup/tool/install_core.dart` | Copies the chosen modules into a project (`dart tool/install_core.dart --list`) |
| `architectural-setup/rules/AGENTS.md` | The rulebook copied into the app, trimmed to its modules |
| `architectural-setup/reference/` | The app shell in the standard shape, and one whole feature with its tests |
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
dart ../../architectural-setup/tool/install_core.dart \
  --modules prefs,supabase-session,local-cache,network-images,commerce-widgets,payments-razorpay,ga4-meta,katyayani-core,app-logo \
  --hosts supabase,medusa
# add the packages it prints, give Endpoints a medusaBaseUrl, then:
flutter analyze && flutter test
```
