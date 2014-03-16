part of core;

/// A Widget is a View that acts as a template. Its render() method typically
/// returns elements to be rendered
abstract class Widget<S extends State> extends View implements _Redrawable {
  Props _props;
  State _state, _nextState;
  View _shadow;
  Root _root;
  final _didMount = new StreamController.broadcast();
  final _didUpdate = new StreamController.broadcast();
  final _willUnmount = new StreamController.broadcast();

  Widget(Map<Symbol, dynamic> props)
      : _props = new Props(props),
        super(props[#ref]);

  /// Constructs the initial state when the Widget is mounted.
  /// (Stateful widgets should override.)
  S get firstState => null;

  /// Returns the currently rendered state. This should be treated as read-only.
  S get state => _state;

  /// Returns the state that will be rendered on the next update.
  /// This is typically used to update the state due to an event.
  /// Accessing nextState automatically marks the Widget as dirty.
  S get nextState {
    assert(_mounted);
    if (_nextState == null) {
      _nextState = _state.clone();
      invalidate();
    }
    return _nextState;
  }

  /// Sets the state to be rendered on the next update.
  /// Setting the nextState automatically marks the Widget as dirty.
  void set nextState(S s) {
    _nextState = s;
    invalidate();
  }

  Stream get didMount => _didMount.stream;
  Stream get didUpdate => _didUpdate.stream;
  Stream get willUnmount => _willUnmount.stream;

  void doMount(Transaction tx, StringBuffer out) {
    _root = tx.root;
    _state = firstState;
    _shadow = render();
    _shadow.mount(tx, out, _path, _depth + 1);
    if (_didMount.hasListener) {
      tx._didMountStreams.add(_didMount.sink);
    }
  }

  void traverse(callback) {
    _shadow.traverse(callback);
    callback(this);
  }

  void doUnmount(NextFrame frame) {
    if (_shadow == null) {
      throw "not mounted: ${this.runtimeType}";
    }
    _willUnmount.add(true);
    _shadow.unmount(frame);
    _shadow = null;
  }

  /// Requests that this Widget be re-rendered during the next frame.
  void invalidate() {
    assert(_mounted);
    _root._invalidate(this);
  }

  /// Constructs another View to be rendered in place of this Widget.
  /// (This is somewhat similar to "shadow DOM".)
  View render();

  @override
  void _redraw(Transaction tx) => update(null, tx);

  bool canUpdateTo(View other) => runtimeType == other.runtimeType;

  void update(Widget nextVersion, Transaction tx) {
    assert(_mounted);
    assert(_root != null);

    if (_nextState != null) {
      _state = _nextState;
      _nextState = null;
    }
    if (nextVersion != null) {
      _props = nextVersion._props;
    }

    View newShadow = render();
    if (_shadow.canUpdateTo(newShadow)) {
      _shadow.update(newShadow, tx);
    } else {
      tx.mountShadow(this, newShadow);
      _shadow = newShadow;
    }
    if (_didUpdate.hasListener) {
      tx.root._didUpdateStreams.add(_didUpdate.sink);
    }
  }

  Props get props => _props;
}

/// The internal state of a stateful Widget.
/// (Each stateful Widget will typically have a corresponding subclass of State.)
abstract class State {
  /// Returns a copy of the state, to be rendered on the next refresh.
  State clone();
}
