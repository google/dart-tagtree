part of core;

typedef void RenderFunction(NextFrame frame);

/// Callbacks to the Root's environment.
abstract class RootEnv {
  void requestAnimationFrame(RenderFunction callback);
}

/// A Root contains a view tree that's rendered to the DOM.
class Root {
  final int id;
  final RootEnv env;
  final _dispatcher = new EventDispatcher();
  View _top;

  bool _frameRequested = false;
  View _nextTop;
  final Set<Widget> _widgetsToUpdate = new Set();

  Root(this.id, this.env);

  String get path => "/${id}";

  /// Schedules the view tree to be replaced just before the next rendered frame.
  /// (If called more than once within a single frame, only the last call will
  /// have any effect.)
  void requestMount(View nextTop) {
    _nextTop = nextTop;
    _requestAnimationFrame();
  }

  /// Schedules a widget to be updated just before rendering the next frame.
  /// (That is, marks the Widget as "dirty".)
  void requestWidgetUpdate(Widget w) {
    _widgetsToUpdate.add(w);
    _requestAnimationFrame();
  }

  /// Calls any event handlers for this root.
  void dispatchEvent(ViewEvent e) => _dispatcher.dispatch(e);

  void _requestAnimationFrame() {
    if (!_frameRequested) {
      _frameRequested = true;
      env.requestAnimationFrame(_renderFrame);
    }
  }

  void _renderFrame(NextFrame frame) {
    Transaction tx = new Transaction(this, frame, _dispatcher, _nextTop, _widgetsToUpdate);

    _frameRequested = false;
    _nextTop = null;
    _widgetsToUpdate.clear();

    tx.run();

    // No widgets should be invalidated while rendering.
    assert(_widgetsToUpdate.isEmpty);
  }
}
