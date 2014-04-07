part of core;

/// An object that contains a state machine.
/// (A mixin implementing dirty tracking for an object that has state.)
abstract class StateMixin<S> {
  S _state, _nextState;

  initState() {
    assert(_state == null && _nextState == null);
    _state = createFirstState();
    assert(_state != null);
  }

  // Moves nextState to state. (Clears dirty tracking.)
  updateState() {
    if (_nextState != null) {
      _state = _nextState;
      _nextState = null;
    }
  }

  /// Creates the first state.
  S createFirstState();

  /// Returns a new copy of the state, given the previous version.
  /// A default implementation is provided for bool, num, and String.
  /// For anything else, the subclass must override this method.
  S cloneState(S prev) {
    assert(prev is bool || prev is num || prev is String);
    return prev;
  }

  /// A callback indicating that the state has probably changed.
  invalidate();

  /// Returns the currently rendered state. This should be treated as read-only.
  S get state => _state;

  /// Returns the state that will be rendered on the next update.
  /// This is typically used to update the state due to an event.
  /// Accessing nextState automatically calls invalidate().
  S get nextState {
    if (_nextState == null) {
      _nextState = cloneState(_state);
      assert(_nextState != null);
      invalidate();
    }
    return _nextState;
  }

  /// Sets the state to be rendered on the next update.
  /// Automatically calls invalidate().
  void set nextState(S s) {
    _nextState = s;
    invalidate();
  }
}
