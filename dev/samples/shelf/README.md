# shelf

A small Flutter app used as a test fixture for architecture-restructuring
exercises. It is deliberately written in a flat Riverpod + Dio + go_router
style with hardcoded URLs, keys, colours and route strings.

`BEHAVIORS.md` is the manifest of every observable behaviour that a
restructuring must preserve. `flutter analyze` reports no issues and
`flutter test` passes.
