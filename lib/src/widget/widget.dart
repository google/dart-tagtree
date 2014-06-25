part of widget;

/// A function to be called when the Widget will unmount.
typedef TearDown();

/// A Widget implements a view that can change after being rendered.
///
/// A Widget contains internal state. S is the type of the state object.
/// It can be any type, but you must override the [cloneState] method if
/// it's not a bool, num, or String.
abstract class Widget<V extends View,S> extends StateMachineMixin<S> implements Animation<V,S> {

  V get view => _place.view;

  final _willUnmount = new StreamController.broadcast();

  Place _place;
  bool configured = false;

  @override
  View renderFrame(Place p) {
    this._place = p;
    configure(p.view);
    if (state == null) {
      initStateMachine(p.state);
    } else {
      commitState();
    }
    return render();
  }

  @override
  bool playWhile(Place p) => this.runtimeType == p.nextAnimation.runtimeType;

  @override
  bool needsRender(View prev, View next) => true;

  /// A subclass hook that's called whenever the view changes.
  /// Called automatically before [firstState] and whenever the widget is rendered.
  void configure(V view) {}

  /// Asks for the widget to be rendered again.
  /// Called automatically after the widget's state changes.
  /// (That is, whenever [nextState] is accessed.)
  @override
  void invalidate() => _place.nextFrame((s) => s);

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
    _place = null;
  }
}

