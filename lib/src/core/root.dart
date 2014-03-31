part of core;

typedef void RenderFunction(NextFrame frame);

/// Callbacks to the Root's environment.
abstract class RootEnv {
  void requestAnimationFrame(RenderFunction callback);
}

/// A Root contains a view tree that's rendered to the DOM.
class Root implements WidgetEnv {
  final int id;
  final RootEnv env;
  final _handlers = new HandlerMap();
  View _top;

  bool _frameRequested = false;
  Tag _nextTop;
  final Set<Widget> _widgetsToUpdate = new Set();

  Root(this.id, this.env);

  String get path => "/${id}";

  /// Schedules the view tree to be replaced just before the next rendered frame.
  /// (If called more than once within a single frame, only the last call will
  /// have any effect.)
  void mount(Tag nextTop) {
    _nextTop = nextTop;
    _requestAnimationFrame();
  }

  /// Hook called
  void afterFirstMount() {}

  /// Schedules a widget to be updated just before rendering the next frame.
  /// (That is, marks the Widget as "dirty".)
  @override
  void requestWidgetUpdate(Widget w) {
    assert(w._mounted);
    _widgetsToUpdate.add(w);
    _requestAnimationFrame();
  }

  /// Calls any event handlers for this root.
  void dispatchEvent(ViewEvent e) => dispatch(e, _handlers);

  void _requestAnimationFrame() {
    if (!_frameRequested) {
      _frameRequested = true;
      env.requestAnimationFrame(_renderFrame);
    }
  }

  void _renderFrame(NextFrame frame) {
    Transaction tx = new Transaction(this, frame, _handlers, _nextTop, _widgetsToUpdate);

    _frameRequested = false;
    _nextTop = null;
    _widgetsToUpdate.clear();

    bool wasEmpty = _top == null;
    tx.run();
    if (wasEmpty) {
      afterFirstMount();
    }

    // No widgets should be invalidated while rendering.
    assert(_widgetsToUpdate.isEmpty);
  }
}
