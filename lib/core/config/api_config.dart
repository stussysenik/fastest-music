/// Configuration for the Elixir backend API connection.
///
/// ## How it works (educational)
///
/// This config can be overridden at build time using --dart-define:
///   flutter run --dart-define=BACKEND_URL=http://192.168.1.100:4000
///
/// In production, you'd point this to your deployed Elixir server.
/// In development, localhost:4000 is the default Phoenix port.
class ApiConfig {
  /// Base URL for the Elixir/Phoenix backend.
  /// Override with --dart-define=BACKEND_URL=http://your-server:4000
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://fastest-music-api.fly.dev',
  );

  /// How long to wait for backend responses before falling back to MusicKit.
  /// 500ms is aggressive — if the backend can't respond that fast, MusicKit
  /// is probably faster anyway (since it's on-device).
  static const Duration searchTimeout = Duration(milliseconds: 3000);

  /// Artwork batch requests can take longer since they may hit external APIs.
  static const Duration artworkTimeout = Duration(milliseconds: 5000);

  /// Health check timeout — should be fast since it's just reading local state.
  static const Duration healthTimeout = Duration(milliseconds: 2000);
}
