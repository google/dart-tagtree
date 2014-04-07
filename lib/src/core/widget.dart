part of core;

typedef Widget CreateWidgetFunc();

WidgetDef defineWidget({CreateWidgetFunc widget})
  => new WidgetDef(widget);

class WidgetDef extends TagDef {
  final CreateWidgetFunc _createWidgetFunc;

  WidgetDef(this._createWidgetFunc) {
    assert(_createWidgetFunc != null);
  }

  createWidget() => _createWidgetFunc();
}

abstract class WidgetEnv {
  void requestWidgetUpdate(WidgetView  view);
}

/// A Widget is the implementation of a tag that has state.
/// S is the state's type, which can be any type, but must be
/// cloneable using the cloneState() function.
abstract class Widget<S> extends StateMixin<S> {
  WidgetView _view;
  WidgetEnv _widgetEnv;
  final _didMount = new StreamController.broadcast();
  final _didUpdate = new StreamController.broadcast();
  final _willUnmount = new StreamController.broadcast();

  void _init(Map<Symbol, dynamic> props, WidgetEnv env) {
    setProps(props);
    initState();
    _widgetEnv = env;
  }

  void setProps(Map<Symbol, dynamic> p) {
    _suppressWarning(x) => x;
    var w = _suppressWarning(this);
    Function.apply(w.onPropsChange, [], p);
  }

  bool get isMounted => _view != null && _view._mounted;

  Stream get didMount => _didMount.stream;
  Stream get didUpdate => _didUpdate.stream;
  Stream get willUnmount => _willUnmount.stream;

  /// Requests that this Widget be re-rendered during the next frame.
  @override
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

    updateState();
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
    Widget w = def.createWidget();
    w._init(tag.props, env);
    WidgetView v = new WidgetView.raw(def, path, depth, w, tag.props[#ref]);
    w._view = v;
    return v;
  }
}

