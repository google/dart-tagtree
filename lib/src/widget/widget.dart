part of widget;

/// A function to be called when the Widget will unmount.
typedef TearDown();

/// A Widget implements a view that can change after being rendered.
///
/// A Widget contains internal state. S is the type of the state object.
/// It can be any type, but you must override the [cloneState] method if
/// it's not a bool, num, or String.
abstract class Widget<V extends View,S> extends StateMachineMixin<V,S> implements Expander {
  V view;

  final _willUnmount = new StreamController.broadcast();

  RenderNeeded _renderNeeded;
  bool configured = false;

  @override
  void mount(renderNeeded) {
    this._renderNeeded = renderNeeded;
  }

  @override
  View expand(V input) {
    this.view = input;
    configure(input);
    if (state == null) {
      initStateMachine(input);
    } else {
      commitState();
    }
    return render();
  }

  @override
  Expander nextExpander(View next, Expander defaultVal) =>
      defaultVal.runtimeType == this.runtimeType ? this : defaultVal;

  @override
  bool canReuseDom(Expander prev) => prev == this;

  @override
  bool shouldExpand(View prev, View next) => true;

  /// A subclass hook that's called whenever the view changes.
  /// Called automatically before [getFirstState] and whenever the widget is rendered.
  void configure(V view) {}

  /// Asks for the widget to be rendered again.
  /// Called automatically after the widget's state changes.
  /// (That is, whenever [nextState] is accessed.)
  @override
  void invalidate() => _renderNeeded();

  /// Constructs the tag tree to be rendered in place of this Widget.
  /// Called automatically for first animation frame containing
  /// the widget, and in any animation frame where [shouldExpand] returned true.
  View render();

  /// If not null, the widget will be called back after the DOM is rendered.
  @override
  OnRendered get onRendered => null;

  /// Adds a callback that will be called before unmounting.
  void addTearDown(TearDown callback) {
    _willUnmount.stream.listen((_) => callback());
  }

  @override
  void willUnmount() {
    if (_willUnmount.hasListener) {
      _willUnmount.add(true);
    }
    _renderNeeded = null;
  }
}

