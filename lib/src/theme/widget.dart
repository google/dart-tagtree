part of theme;

/// A Widget implements a tag that can change after being rendered.
///
/// A Widget contains internal state. S is the type of the state object.
/// It can be any type, but you must override the [cloneState] method if
/// it's not a bool, num, or String.
///
/// Each widget has an associated [View] that was rendered to create
/// the widget. The widget must copy its props from this node whenever it
/// changes, by implementing [setView].
///
/// A Widget may access the DOM by rendering an element tag with its "ref"
/// property set. The DOM will be available during callbacks
/// for [didMount], [didRender], and [willUnmount] events.
abstract class Widget<V extends View,S> extends StateMixin<S> {
  V view;

  final _didMount = new StreamController.broadcast();
  final _didRender = new StreamController.broadcast();
  final _willUnmount = new StreamController.broadcast();
  var _invalidate; // non-null when mounted

  /// Initializes the widget.
  /// Called automatically when the associated node is first rendered.
  WidgetController mount(V view, invalidate()) {
    setView(view);
    initState(); // depends on props
    _invalidate = invalidate;
    return new WidgetController(this);
  }

  /// Copies the assocated view into the widget.
  /// Called automatically before [createFirstState]
  /// and whenever the associated widget tag is rendered.
  void setView(V view) {
    this.view = view;
  }

  /// Asks for the widget to be rendered again.
  /// Called automatically after the widget's state changes.
  /// (That is, whenever [nextState] is accessed.)
  @override
  void invalidate() => _invalidate();

  /// If shouldRender returns false, rendering will be skipped.
  /// Subclasses may override this method to improve performance.
  /// Called automatically in the animation frame after [setView] or [invalidate].
  bool shouldRender(View oldView, S oldState) => true;

  /// Constructs the tag tree to be rendered in place of this Widget.
  /// Called automatically for first animation frame containing
  /// the widget, and in any animation frame where [shouldRender] returned true.
  View render();

  /// Returns true when the widget is visible.
  /// That is, isMounted changes to true when mount() is automatically
  /// called while rendering the first animation frame displaying the widget.
  /// It changes to false while rendering the first animation frame that
  /// doesn't include the widget.
  bool get isMounted => _invalidate != null;

  /// A stream that receives one event at the end of the animation frame when
  /// the widget first appears. When the event is received, the widget's DOM can
  /// be accessed using a ref.
  Stream get didMount => _didMount.stream;

  /// A stream that receives an event at the end of the animation frame when the
  /// widget was re-rendered. The widget's DOM has been updated.
  Stream get didRender => _didRender.stream;

  /// A stream that receives an event during the animation frame when the widget
  /// is being unmounted. The widget's DOM hasn't been removed yet.
  Stream get willUnmount => _willUnmount.stream;
}

/// The API that the render library uses to control the widget.
class WidgetController {
  final Widget widget;

  WidgetController(this.widget);

  StreamController get didMount => widget._didMount;
  StreamController get didRender => widget._didRender;
  StreamController get willUnmount => widget._willUnmount;

  void unmount() {
    widget._invalidate = null;
  }
}
