/// Holds UI-only state that does not belong in the data model:
/// animation flags, focus tracking, scroll direction hints, etc.
class ConnectionsPageUIState {
  // ── Input / search mode ───────────────────────────────────────────────────
  bool searching = false;
  bool searchingFrom = true;

  // ── Animations ────────────────────────────────────────────────────────────
  bool rotateSwitchButton = false;
  bool inJourneySearchAnimation = false;
  double rotatingSearchIconTurns = 0;

  // ── Scroll behaviour ──────────────────────────────────────────────────────
  /// When true the journey list auto-scrolls to the top after a rebuild.
  bool shouldAutoScrollToTop = true;
}