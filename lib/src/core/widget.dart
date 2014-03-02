part of core;

/// A Widget is a View that acts as a template. Its render() method typically
/// returns elements to be rendered
abstract class Widget extends View {
  Props _props;
  State _state, _nextState;
  View _shadow;
  ViewTree _tree;

  Widget(Map<Symbol, dynamic> props)
      : _props = new Props(props),
        super(props[#ref]);

  /// Constructs the initial state when the Widget is mounted.
  /// (Stateful widgets should override.)
  State get firstState => null;

  /// Returns the currently rendered state. This should be treated as read-only.
  /// (Subclasses may want to override to change the return type.)
  State get state => _state;

  /// Returns the state that will be rendered on the next update.
  /// This is typically used to update the state due to an event.
  /// Accessing nextState automatically marks the Widget as dirty.
  /// (Subclasses may want to override to change the return type.)
  State get nextState {
    assert(_mounted);
    if (_nextState == null) {
      _nextState = _state.clone();
      invalidate();
    }
    return _nextState;
  }

  /// Sets the state to be rendered on the next update.
  /// Setting the nextState automatically marks the Widget as dirty.
  void set nextState(State s) {
    _nextState = s;
    invalidate();
  }

  void doMount(StringBuffer out) {
    _state = firstState;
    _shadow = render();
    _shadow.mount(out, _path, _depth);
  }

  void traverse(callback) {
    _shadow.traverse(callback);
    callback(this);
  }

  void doUnmount(NextFrame frame) {
    if (_shadow == null) {
      throw "not mounted: ${this.runtimeType}";
    }
    _shadow.unmount(frame);
    _shadow = null;
  }

  /// Requests that this Widget be re-rendered during the next frame.
  void invalidate() {
    assert(_mounted);
    _tree._invalidate(this);
  }

  /// Constructs another View to be rendered in place of this Widget.
  /// (This is somewhat similar to "shadow DOM".)
  View render();

  bool canUpdateTo(View other) => runtimeType == other.runtimeType;

  void update(Widget nextVersion, ViewTree tree, NextFrame frame) {
    assert(_mounted);

    if (_nextState != null) {
      _state = _nextState;
      _nextState = null;
    }
    if (nextVersion != null) {
      _props = nextVersion._props;
    }

    View newShadow = render();
    if (_shadow.canUpdateTo(newShadow)) {
      _shadow.update(newShadow, tree, frame);
    } else {
      // Set the current element first because unmount clears the node cache
      frame.visit(_path);
      _shadow.unmount(frame);
      _shadow = newShadow;

      StringBuffer html = new StringBuffer();
      _shadow.mount(html, _path, _depth);
      frame.replaceElement(html.toString());
      tree._finishMount(_shadow, frame);
    }
    tree._updated.add(this);
  }

  Props get props => _props;
}

/// The internal state of a stateful Widget.
/// (Each stateful Widget will typically have a corresponding subclass of State.)
abstract class State {
  /// Returns a copy of the state, to be rendered on the next refresh.
  State clone();
}
