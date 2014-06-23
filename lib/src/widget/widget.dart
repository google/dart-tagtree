part of widget;

/// A function to be called when the Widget will unmount.
typedef TearDown();

/// A Widget implements a view that can change after being rendered.
///
/// A Widget contains internal state. S is the type of the state object.
/// It can be any type, but you must override the [cloneState] method if
/// it's not a bool, num, or String.
abstract class Widget<V extends View,S> extends StateMachineMixin<S> implements Animation<V,S> {
  V view;

  final _willUnmount = new StreamController.broadcast();

  Refresh _refresh;
  bool configured = false;

  @override
  View expand(V input, prev, Refresh refresh) {
    this.view = input;
    this._refresh = refresh;
    configure(input);
    if (state == null) {
      initStateMachine(prev);
    } else {
      commitState();
    }
    return render();
  }

  @override
  bool canPlay(View nextView, Animation nextAnim) => this.runtimeType == nextAnim.runtimeType;

  @override
  bool shouldExpand(View prev, View next) => true;

  /// A subclass hook that's called whenever the view changes.
  /// Called automatically before [getFirstState] and whenever the widget is rendered.
  void configure(V view) {}

  /// Asks for the widget to be rendered again.
  /// Called automatically after the widget's state changes.
  /// (That is, whenever [nextState] is accessed.)
  @override
  void invalidate() => _refresh(null);

  /// Returns the shadow view for this Widget.
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
    _refresh = null;
  }
}

