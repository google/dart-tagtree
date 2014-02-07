part of viewlet;

/// A Widget is a View that acts as a template. Its render() method typically
/// returns elements to be rendered
abstract class Widget extends View {
  Map<Symbol, dynamic> _props;
  State _state, _nextState;
  View shadow;

  Widget(this._props);

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
    if (_nextState == null) {
      _nextState = _state.clone();
      _dirtyViews.add(this);
    }
    return _nextState;
  }

  /// Sets the state to be rendered on the next update.
  /// Setting the nextState automatically marks the Widget as dirty.
  void set nextState(State s) {
    _nextState = s;
    _dirtyViews.add(this);
  }

  void mount(StringBuffer out, String path, int depth) {
    super.mount(out, path, depth);
    _state = firstState;
    shadow = render();
    shadow.mount(out, path, depth);
  }

  void unmount() {
    if (shadow == null) {
      throw "not mounted: ${this.runtimeType}";
    }
    shadow.unmount();
    shadow = null;
  }

  /// Constructs another View to be rendered in place of this Widget.
  /// (This is somewhat similar to "shadow DOM".)
  View render();

  bool canUpdateTo(View other) => runtimeType == other.runtimeType;

  void update(Widget nextVersion) {
    assert(_mounted);

    print("refresh Widget: ${_path}");

    if (_nextState != null) {
      _state = _nextState;
      _nextState = null;
    }
    if (nextVersion != null) {
      _props = nextVersion._props;
    }

    View newShadow = render();
    if (shadow.canUpdateTo(newShadow)) {
      shadow.update(newShadow);
    } else {
      shadow.unmount();
      shadow = newShadow;
      StringBuffer out = new StringBuffer();
      shadow.mount(out, _path, _depth);
      Element before = getDom();
      Element after = _unsafeNewElement(out.toString());
      before.replaceWith(after);
    }
  }

  Map<Symbol, dynamic> get props => _props;
}

/// The internal state of a stateful Widget.
/// (Each stateful Widget will typically have a corresponding subclass of State.)
abstract class State {
  /// Returns a copy of the state, to be rendered on the next refresh.
  State clone();
}