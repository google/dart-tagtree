part of core;

typedef Widget CreateWidgetFunc();

/// Defines a new tag that has state.
TagDef defineWidget(CreateWidgetFunc f) => new _WidgetDef(f);

/// A Widget is the implementation of a tag that has state.
/// S is the state's type, which can be any type, but must be
/// cloneable using the cloneState() function.
abstract class Widget<S> extends StateMixin<S> {
  final _didMount = new StreamController.broadcast();
  final _didUpdate = new StreamController.broadcast();
  final _willUnmount = new StreamController.broadcast();

  _Widget _view; // non-null when mounted

  void _init(Map<Symbol, dynamic> props) {
    setProps(props);
    initState();
  }

  /// The framework calls this method whenever props change.
  /// The default implementation calls onPropsChange() with the passed-in
  /// properties as named parameters.
  void setProps(Map<Symbol, dynamic> newProps) {
    _suppressWarning(x) => x;
    var w = _suppressWarning(this);
    Function.apply(w.onPropsChange, [], newProps);
  }

  /// Returns true between the time when the widget's first animation frame
  /// was rendered up to (and not including) the first animation frame when
  /// it was removed.
  bool get isMounted => _view != null && _view._mounted;

  /// A stream that receives an event at the end of the animation frame when
  /// the widget was mounted. The widget's DOM is valid and can be accessed
  /// and BrowserRefs (if any) can be used to access it.
  Stream get didMount => _didMount.stream;

  /// A stream that receives an event at the end of the animation frame when the
  /// widget was updated. The widget's DOM has been updated.
  Stream get didUpdate => _didUpdate.stream;

  /// A stream that receives an event during the animation frame when the widget
  /// is being unmounted. The widget's DOM hasn't been removed yet.
  Stream get willUnmount => _willUnmount.stream;

  @override
  void invalidate() {
    assert (_view != null && _view._mounted);
    _view.invalidate(_view);
  }

  /// Constructs the tag tree to be rendered in place of this Widget.
  /// The framework calls this function during the next animation frame after invalidate()
  /// was called.
  Tag render();

  /// Determines whether the Widget will be rendered during an update.
  /// (If false, it will be skipped.)
  bool shouldUpdate(Tag nextVersion) => true;
}

class _WidgetDef extends TagDef {
  final CreateWidgetFunc _createWidget;
  const _WidgetDef(this._createWidget);
}

