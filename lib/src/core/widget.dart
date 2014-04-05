part of core;

typedef Widget CreateWidgetFunc();

WidgetDef defineWidget({Function props, CreateWidgetFunc widget})
  => new WidgetDef(props, widget);

class WidgetDef extends TagDef {
  final Function _checkPropsFunc;
  final CreateWidgetFunc _createWidgetFunc;

  WidgetDef(this._checkPropsFunc, this._createWidgetFunc) {
    assert(_checkPropsFunc != null);
    assert(_createWidgetFunc != null);
  }

  void checkProps(Map<Symbol, dynamic> props) {
    var err = Function.apply(_checkPropsFunc, [], props);
    if (err != true) {
      throw "invalid props: ${err}";
    }
  }

  createWidget() => _createWidgetFunc();
}

abstract class WidgetEnv {
  void requestWidgetUpdate(WidgetView  view);
}

/// A Widget is the implementation of a tag that has state.
/// S is the state's type, which can be any type, but must be
/// cloneable using the cloneState() function.
abstract class Widget<S> {
  WidgetView _view;
  S _state, _nextState;
  WidgetEnv _widgetEnv;
  final _didMount = new StreamController.broadcast();
  final _didUpdate = new StreamController.broadcast();
  final _willUnmount = new StreamController.broadcast();

  /// Subclasses must override this method to return the widget's first state.
  S createFirstState();

  void setProps(Map<Symbol, dynamic> p) {
    _suppressWarning(x) => x;
    var w = _suppressWarning(this);
    Function.apply(w.onPropsChange, [], p);
  }

  void _init(S s, WidgetEnv env) {
    _state = s;
    _widgetEnv = env;
  }

  bool get isMounted => _view != null && _view._mounted;


  /// Returns the currently rendered state. This should be treated as read-only.
  S get state => _state;

  /// Returns the state that will be rendered on the next update.
  /// This is typically used to update the state due to an event.
  /// Accessing nextState automatically marks the Widget as dirty.
  S get nextState {
    assert(isMounted);
    if (_nextState == null) {
      _nextState = cloneState(_state);
      assert(_nextState != null);
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

  /// Returns a new copy of the state, given the previous version.
  /// A default implementation is provided for bool, num, and String.
  S cloneState(S prev) {
    assert(prev is bool || prev is num || prev is String);
    return prev;
  }

  Stream get didMount => _didMount.stream;
  Stream get didUpdate => _didUpdate.stream;
  Stream get willUnmount => _willUnmount.stream;

  /// Requests that this Widget be re-rendered during the next frame.
  void invalidate() {
    assert(isMounted);
    _widgetEnv.requestWidgetUpdate(this._view);
  }

  /// Constructs a tag tree to be rendered in place of this Widget.
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
      setProps(nextVersion.props);
    }
    return render();
  }
}

class WidgetView extends _View {
  final Widget widget;
  _View _shadow;

  WidgetView.raw(WidgetDef def, String path, int depth, this.widget, Ref ref) :
    super(def, path, depth, ref);

  factory WidgetView(Tag tag, String path, int depth, WidgetEnv env) {
    WidgetDef def = tag.def;
    def.checkProps(tag.props);
    Widget w = def.createWidget();
    w.setProps(tag.props);
    var s = w.createFirstState();
    w._init(s, env);
    WidgetView v = new WidgetView.raw(def, path, depth, w, tag.props[#ref]);
    w._view = v;
    return v;
  }
}

