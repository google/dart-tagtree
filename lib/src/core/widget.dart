part of core;

typedef Widget CreateWidgetFunc();

/// Defines a new tag that has state.
WidgetDef defineWidget(CreateWidgetFunc f) => new WidgetDef(f);

class WidgetDef extends TagDef {
  final CreateWidgetFunc createWidget;
  const WidgetDef(this.createWidget);
}

typedef InvalidateFunc();

/// A Widget is the implementation of a tag that has state.
/// S is the state's type, which can be any type, but must be
/// cloneable using the cloneState() function.
abstract class Widget<S> extends StateMixin<S> {
  final _didMount = new StreamController.broadcast();
  final _didUpdate = new StreamController.broadcast();
  final _willUnmount = new StreamController.broadcast();

  InvalidateFunc _invalidate; // non-null when mounted

  /// Called by the render library.
  WidgetController mount(Map<Symbol, dynamic> props, InvalidateFunc invalidate) {
    var c = new WidgetController(this);
    c.setProps(props);
    initState();
    _invalidate = invalidate;
    return c;
  }

  /// Returns true between the time when the widget's first animation frame
  /// was rendered up to (and not including) the first animation frame when
  /// it was removed.
  bool get isMounted => _invalidate != null;

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
  void invalidate() => _invalidate();

  /// Constructs the tag tree to be rendered in place of this Widget.
  /// The render library calls this function during the next animation frame after invalidate()
  /// was called.
  Tag render();

  /// Determines whether the Widget will be rendered during an update.
  /// (If false, it will be skipped.)
  bool shouldUpdate(Tag nextVersion) => true;
}

/// The API that the render library uses to control the widget.
class WidgetController {
  final Widget widget;

  WidgetController(this.widget);

  StreamController get didMount => widget._didMount;
  StreamController get didUpdate => widget._didUpdate;
  StreamController get willUnmount => widget._willUnmount;

  /// Calls the widget's onPropsChange() with the passed-in props as named parameters.
  void setProps(Map<Symbol, dynamic> newProps) =>
    Function.apply(_suppressWarning(widget).onPropsChange, [], newProps);

  void unmount() {
    widget._invalidate = null;
  }

  static _suppressWarning(x) => x;
}
