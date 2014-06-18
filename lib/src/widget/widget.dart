part of widget;

/// A Widget implements a tag that can change after being rendered.
///
/// A Widget contains internal state. S is the type of the state object.
/// It can be any type, but you must override the [cloneState] method if
/// it's not a bool, num, or String.
///
/// Each widget has an associated [View] that was rendered to create
/// the widget. The widget must copy its props from this node whenever it
/// changes, by implementing [configure].
///
/// A Widget may access the DOM by rendering an element tag with its "ref"
/// property set. The DOM will be available during callbacks
/// for [didRender] and [willUnmount] events.
abstract class Widget<V extends View,S> extends StateMixin<S> implements Expander {
  V props;

  final _willUnmount = new StreamController.broadcast();
  var _invalidate; // non-null when mounted

  /// Initializes the widget.
  /// Called automatically when the associated node is first rendered.
  void mount(V input, invalidate()) {
    this.props = input;
    configure(input);
    initState(); // depends on props being set.
    _invalidate = invalidate;
  }

  @override
  View expand(V input) {
    this.props = input;
    configure(input);
    commitState();
    return render();
  }

  @override
  bool canReuse(Expander next) => next.runtimeType == this.runtimeType;

  @override
  bool shouldExpand(View prev, View next) => true;

  /// A subclass hook that's called whenever the view changes.
  /// Called automatically before [createFirstState]
  /// and whenever the widget is rendered.
  void configure(V view) {}

  /// Asks for the widget to be rendered again.
  /// Called automatically after the widget's state changes.
  /// (That is, whenever [nextState] is accessed.)
  @override
  void invalidate() => _invalidate();

  /// Constructs the tag tree to be rendered in place of this Widget.
  /// Called automatically for first animation frame containing
  /// the widget, and in any animation frame where [shouldRender] returned true.
  View render();

  /// If not null, the widget will be called back after the DOM is rendered.
  @override
  OnRendered get onRendered => null;

  /// Returns true when the widget is visible.
  /// That is, isMounted changes to true when mount() is automatically
  /// called while rendering the first animation frame displaying the widget.
  /// It changes to false while rendering the first animation frame that
  /// doesn't include the widget.
  bool get isMounted => _invalidate != null;

  /// A stream that receives an event during the animation frame when the widget
  /// is being unmounted. The widget's DOM hasn't been removed yet.
  Stream get willUnmount => _willUnmount.stream;

  void unmount() {
    if (_willUnmount.hasListener) {
      _willUnmount.add(true);
    }
    _invalidate = null;
  }
}

