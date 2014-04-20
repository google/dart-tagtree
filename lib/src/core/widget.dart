part of core;

typedef Widget CreateWidgetFunc();

WidgetDef defineWidget(CreateWidgetFunc f) => new WidgetDef(f);

class WidgetDef extends TagDef {
  final CreateWidgetFunc _createWidgetFunc;

  const WidgetDef(this._createWidgetFunc);

  createWidget() => _createWidgetFunc();
}

/// A Widget is the implementation of a tag that has state.
/// S is the state's type, which can be any type, but must be
/// cloneable using the cloneState() function.
abstract class Widget<S> extends StateMixin<S> {
  final _didMount = new StreamController.broadcast();
  final _didUpdate = new StreamController.broadcast();
  final _willUnmount = new StreamController.broadcast();

  _WidgetView _view; // non-null when mounted

  void _init(Map<Symbol, dynamic> props) {
    setProps(props);
    initState();
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

  @override
  void invalidate() =>_view.invalidate();

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

    updateState();
    if (nextVersion != null) {
      setProps(nextVersion.props);
    }
    return render();
  }
}

typedef _InvalidateWidgetFunc(_WidgetView v);

class _WidgetView extends _View {
  final Widget widget;
  final _InvalidateWidgetFunc _invalidate;
  _View _shadow;

  _WidgetView.raw(WidgetDef def, String path, int depth, Ref ref, this.widget, this._invalidate) :
    super(def, path, depth, ref);

  factory _WidgetView(Tag tag, String path, int depth, _InvalidateWidgetFunc invalidate) {
    WidgetDef def = tag.def;
    Widget w = def.createWidget();
    w._init(tag.props);
    _WidgetView v = new _WidgetView.raw(def, path, depth, tag.props[#ref], w, invalidate);
    w._view = v;
    return v;
  }

  void invalidate() {
    assert(_mounted);
    _invalidate(this);
  }
}
