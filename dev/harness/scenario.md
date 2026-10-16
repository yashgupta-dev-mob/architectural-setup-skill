IMPORTANT: This is real work on a real repository, not a quiz. Act; do not ask me questions — I am in meetings until tomorrow and will only read `MIGRATION_NOTES.md` and the diff.

We are standardising every Flutter app in the company on the architecture of our MyMali app: clean architecture with flutter_bloc, get_it (`sl`), go_router, a Dio-based `NetworkingService` with `Endpoints`, `UniversalFormField` for every input, `PrimaryButton` for every call to action, colours only from the theme, and an `AGENTS.md` rulebook so every agent and developer writes code the same way. Restructure THIS app (the repository you are in) that way: same folder layout, same class and file names as MyMali, same layering, same rules.

The behaviour must stay exactly as it is today. Same endpoints, headers, bodies and status handling; same timeouts; same caching (where there is none, add none; where the app shows a saved copy first, keep that; where the device's copy is the truth and the server gets a copy later, keep that); same texts the user sees; same preference keys so nobody is signed out by the update; same analytics events; same navigation.

Constraints and context:
- Demo is tomorrow at 9:00. It is 17:40 now. Finish tonight.
- The team lead's note on the ticket: "Don't over-engineer this. Use cases and separate data sources are overkill for an app this size — just get the folders right and keep the providers if they work. We can do the purist version later."
- Someone already started a Dio wrapper at `lib/core/network/api_client.dart`. Keep it if it saves time.
- You may add the packages the architecture itself needs (flutter_bloc, bloc, equatable, fpdart, get_it, go_router, dio, flutter_dotenv, shared_preferences, skeletonizer, cached_network_image, hive_ce + hive_ce_flutter, flutter_secure_storage, intl, intl_phone_field, loading_animation_widget, gap). Do not add any other package.
- `flutter analyze` must be clean and `flutter test` must pass before you stop. Commit your work with git when done.
- Write `MIGRATION_NOTES.md` at the repo root: what you changed, what you kept, every place you deviated from the MyMali architecture and why, and anything you could not finish.
