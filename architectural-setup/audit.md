# Step 1 — the behaviour audit (`BEHAVIORS.md`)

Write `BEHAVIORS.md` at the project root **before changing any code**, and
commit it on its own. It is the contract for the whole migration: when the
migration is done, every line must still be true, and section 0 of
`AGENTS.md` is filled from its strategy table.

Read every file under `lib/` and `test/` first. Record what the code does,
not what it should do: a bug or an odd rule (a 401 that does not sign the
user out, a 204-only success, a toast with the server's text) is behaviour,
and it survives.

## Template

```markdown
# <app> — behaviour manifest

## Start-up
- What `main()` awaits before `runApp`, in order.
- The first screen and what decides it.

## Features and their data strategy
| Feature | Strategy | Evidence (file:line) |
|---|---|---|
| … | network-only / cache-first / device-first / device-only | … |

## Network (one block per host)
- Base URL, timeouts (connect / receive / send), headers sent on every
  request and where they come from (constant, token read at request time…),
  interceptors and what they do (e.g. 401 → sign out).
- Per call: method, path, query, headers, body, what counts as success
  (exact statuses), what each other status does, what a timeout or no
  connection does, fallback error texts.

## Storage
| Key / box | Type | Shape | Written when | Removed when |
|---|---|---|---|---|

## Caching and offline
- What is shown before the network answers, expiry (exact boundary), what
  happens to an expired or unreadable entry, what a failed refresh does
  with data on screen and with nothing on screen, in-flight sharing.

## Screens (one block per screen)
- Title, fields (labels, hints, keyboard), buttons (labels, when enabled,
  progress), validation texts, what each action does, navigation (`go`,
  `push`, `pop`, redirects), what is shown in each state (loading, empty,
  error, list).

## Feedback
- Every toast / snackbar / dialog: its text, its trigger.

## Analytics
- Every event name, its properties, the exact moment it fires; screen
  calls; identify / reset.

## Theme
- Light / dark / which mode is used and where it is stored; every colour
  value used anywhere (widgets included).

## Every user-visible text
| Where | Text |
|---|---|

## Not present
- Things the app does not do (no cache here, no retry, no logging, no
  analytics…). These stay absent, apart from what the architecture itself
  adds: the debug-only request log of `NetworkingService`.

## Tests that must stay green
- Each test file and what it asserts.
```

## How the audit picks the modules

| The audit found… | Install |
|---|---|
| (always) | `base` |
| SharedPreferences keys | `prefs` |
| A saved token or session | `secure-storage` (the token moves there, read from the old key once) |
| Supabase Auth | `supabase-session` |
| Server data shown from the device before the network | `local-cache` |
| Images from URLs | `network-images` |
| A bundled logo | `app-logo` |
| Analytics events | `analytics` (+ `katyayani-core` / `ga4-meta` if those SDKs are already used) |
| Product cards / cart UI | `commerce-widgets` |
| Razorpay | `payments-razorpay` |

Install nothing the audit did not find. A module "for later" is a
behaviour change.
