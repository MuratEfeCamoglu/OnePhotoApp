/// Returns the current local time; injected so "today" is testable.
typedef Clock = DateTime Function();

/// The only place in the app allowed to call [DateTime.now].
DateTime systemClock() => DateTime.now();
