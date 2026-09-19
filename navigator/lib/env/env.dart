abstract final class Env {
  static const String apiUrl = String.fromEnvironment('API_URL');

  /// The configured API base URL. Throws with a clear message when `API_URL`
  /// was not provided at build time instead of failing with an obscure `Uri`
  /// error on the first request.
  static String get requiredApiUrl {
    if (apiUrl.isEmpty) {
      throw StateError(
        'API_URL is not set. Run Flutter with '
        '--dart-define-from-file=.env or --dart-define=API_URL=<base url>.',
      );
    }
    return apiUrl;
  }
}
