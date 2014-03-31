part of core;

abstract class WidgetEnv {
  void requestWidgetUpdate(WidgetView  view);
}

/// A Widget is a View that acts as a template. Its render() method typically
/// returns elements to be rendered
abstract class Widget<S extends State> {
  WidgetView _view;
  Props _props;
  State _state, _nextState;
  View _shadow;
  WidgetEnv _widgetEnv;
  final _didMount = new StreamController.broadcast();
  final _didUpdate = new StreamController.broadcast();
  final _willUnmount = new StreamController.broadcast();

  Widget(Map<Symbol, dynamic> props)
      : _props = new Props(props);

  bool get isMounted => _view._mounted;

  /// Constructs the initial state when the Widget is mounted.
  /// (Stateful widgets should override.)
  S get firstState => null;

  /// Returns the currently rendered state. This should be treated as read-only.
  S get state => _state;

  /// Returns the state that will be rendered on the next update.
  /// This is typically used to update the state due to an event.
  /// Accessing nextState automatically marks the Widget as dirty.
  S get nextState {
    assert(isMounted);
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

  /// Requests that this Widget be re-rendered during the next frame.
  void invalidate() {
    assert(isMounted);
    _widgetEnv.requestWidgetUpdate(this._view);
  }

  /// Constructs another View to be rendered in place of this Widget.
  /// (This is somewhat similar to "shadow DOM".)
  Tag render();

  /// Determines whether the Widget will be rendered during an update.
  /// (If false, it will be skipped.)
  bool shouldUpdate(Tag nextVersion) => true;

  /// Applies state and property changes and renders the new tree.
  /// Postcondition: the widget is still in a partially updated state
  /// because the shadow isn't updated yet.
  Tag _updateAndRender(Tag nextVersion) {
    assert(isMounted);
    assert(_widgetEnv != null);

    if (_nextState != null) {
      _state = _nextState;
      _nextState = null;
    }
    if (nextVersion != null) {
      _props = new Props(nextVersion.props);
    }
    return render();
  }

  Props get props => _props;
}

/// The internal state of a stateful Widget.
/// (Each stateful Widget will typically have a corresponding subclass of State.)
abstract class State {
  /// Returns a copy of the state, to be rendered on the next refresh.
  State clone();
}

class WidgetDef extends TagDef {
  final WidgetFunc widgetFunc;

  WidgetDef({WidgetFunc widget}) :
    this.widgetFunc = widget {
    assert(widget != null);
  }
}

class WidgetView extends View {
  Widget widget;
  WidgetView(WidgetDef def, this.widget, Ref ref) : super(ref) {
    _def = def;
  }
}

