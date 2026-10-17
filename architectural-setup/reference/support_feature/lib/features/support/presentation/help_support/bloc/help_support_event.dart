abstract class HelpSupportEvent {}

/// The page opened: show the saved content, then ask the server.
class HelpSupportStarted extends HelpSupportEvent {}

/// Retry or pull-to-refresh: ask the server again behind what is shown.
class HelpSupportRefreshed extends HelpSupportEvent {}
