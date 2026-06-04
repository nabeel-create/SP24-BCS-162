/// ─── App Configuration ────────────────────────────────────────────────────────
/// Either edit the defaultValue strings below OR pass --dart-define at build:
///
///   flutter build apk \
///     --dart-define=API_BASE_URL=https://<your-domain>/api \
///     --dart-define=FACE_API_URL=https://<your-domain>/face-api \
///     --dart-define=SUPABASE_URL=https://<project>.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=<anon-key>
///
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZobXVuemttaW5qY2pzZ3J6amNjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODQyNzM2NCwiZXhwIjoyMDk0MDAzMzY0fQ.AEQZZdNL57n9w7UC_n_yoBU6_UaXDfwB342YzY0QKcA',
  );

  // ── Python ArcFace recognition service (runs at /face-api on Replit) ──────
  static const String faceApiUrl = String.fromEnvironment(
    'FACE_API_URL',
    defaultValue: 'http://localhost:8000',
  );

  // ── Supabase (for authentication only) ────────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fhmunzkminjcjsgrzjcc.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_NTbGQWqKe9Qos5Zgx-62jQ_PwnowCqr',
  );
}
