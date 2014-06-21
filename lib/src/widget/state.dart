part of widget;

/// StateMixin implements automatic dirty tracking for an object that
/// implements a state machine.
///
/// The strategy used is to clone the state each time the state machine prepares
/// to take a step. This happens automatically whenever [nextState] is accessed.
/// To complete a step, call [commitState].
abstract class StateMixin<S> {
  S _state, _nextState;

  /// Sets the state machine to the first state. This can only be done once.
  void initState() {
    assert(_state == null && _nextState == null);
    _state = createFirstState();
    if (_state == null) {
      throw "${this}: createFirstState() shouldn't return null.";
    }
  }

  /// Moves the state machine one step, clearing dirty tracking.
  /// (If the state isn't dirty, nothing happens.)
  void commitState() {
    if (_nextState != null) {
      _state = _nextState;
      _nextState = null;
    }
  }

  /// Subclass hook to create the first state.
  S createFirstState();

  /// Subclass hook to return a new copy of the state, given the previous version.
  /// A default implementation is provided for bool, num, and String.
  S cloneState(S prev) {
    assert(prev is bool || prev is num || prev is String);
    return prev;
  }

  /// Subclass hook that will be called whenever the state becomes dirty.
  void invalidate();

  /// Returns the currently rendered state. This should be treated as read-only.
  S get state => _state;

  /// Returns uncommitted state that will become current after a call to [commitState].
  /// The returned state object may safely be mutated.
  /// Accessing next automatically marks it as dirty and calls [invalidate].
  S get nextState {
    if (_nextState == null) {
      _nextState = cloneState(_state);
      assert(_nextState != null);
      invalidate();
    }
    return _nextState;
  }

  /// Sets the state to be rendered on the next update.
  /// Automatically marks the state as dirty and calls invalidate().
  void set nextState(S s) {
    _nextState = s;
    invalidate();
  }
}
