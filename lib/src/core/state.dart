part of core;

/// A function that takes an old state and returns a new state.
typedef Step(input);

abstract class Cloneable<T> {
  T clone();
}

/// StateMachineMixin implements automatic dirty tracking for a state machine
/// that "ticks" according to an external schedule.
///
/// The strategy is to clone the state whenever it changes. This happens
/// automatically whenever [nextState] is accessed.
/// To complete a step, call [commitState].
abstract class StateMachineMixin<S> {

  S _state; // non-null when initialized
  S _nextState; // non-null when dirty

  /// Sets the state machine to the first state. This can only be done once.
  void initStateMachine(S firstState) {
    assert(_state == null && _nextState == null);
    _state = firstState;
    if (_state == null) {
      throw "${this}: getFirstState() shouldn't return null.";
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

  /// Subclass hook to return a new copy of the state, given the previous version.
  /// A default implementation is provided for bool, num, String, and Cloneable.
  S cloneState(S prev) {
    if (prev is Cloneable) {
      return _cast(prev).clone();
    } else if (prev is bool || prev is num || prev is String) {
      return prev;
    }
    throw "not cloneable: ${prev.runtimeType}";
  }

  _cast(x) => x;

  /// Subclass hook that will be called whenever the state becomes dirty.
  void step();

  /// Returns the currently rendered state. This should be treated as read-only.
  S get state => _state;

  /// Returns uncommitted state that will become current after a call to [commitState].
  /// The returned state object may safely be mutated.
  /// Accessing [nextState] automatically marks it as dirty and calls [step].
  S get nextState {
    if (_nextState == null) {
      _nextState = cloneState(_state);
      assert(_nextState != null);
      step();
    }
    return _nextState;
  }

  /// Sets the state to be rendered on the next update.
  /// Automatically marks the state as dirty and calls invalidate().
  void set nextState(S s) {
    _nextState = s;
    step();
  }
}
