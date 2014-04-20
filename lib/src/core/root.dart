part of core;

typedef void RenderFunc(NextFrame frame);

typedef void HandleFunc(HandleCall call);

/// A Root contains a view tree that's rendered to the DOM.
abstract class Root implements WidgetEnv {
  final int id;
  final _handlers = new _HandlerMap();
  _View _top;

  bool _frameRequested = false;
  Tag _nextTop;
  HandleFunc _nextHandler;
  final Set<WidgetView> _widgetsToUpdate = new Set();

  Root(this.id);

  /// Subclass hook called after DOM elements are mounted.
  void afterFirstMount();

  /// Subclass hook to schedule the next frame.
  void onRequestAnimationFrame(RenderFunc callback);

  String get path => "/${id}";

  /// Schedules the view tree to be replaced just before the next rendered frame.
  /// (If called more than once within a single frame, only the last call will
  /// have any effect.)
  void mount(Tag nextTop, {HandleFunc handler}) {
    _nextTop = nextTop;
    _nextHandler = handler;
    _requestAnimationFrame();
  }

  /// Schedules a widget to be updated just before rendering the next frame.
  /// (That is, marks the Widget as "dirty".)
  @override
  void requestWidgetUpdate(WidgetView view) {
    assert(view._mounted);
    _widgetsToUpdate.add(view);
    _requestAnimationFrame();
  }

  /// Calls any event handlers for this root.
  void dispatchEvent(HtmlEvent e) => _dispatch(e, _handlers);

  void _requestAnimationFrame() {
    if (!_frameRequested) {
      _frameRequested = true;
      onRequestAnimationFrame(_renderFrame);
    }
  }

  void _renderFrame(NextFrame frame) {
    Transaction tx = new Transaction(this, frame, _handlers, _nextTop, _nextHandler, _widgetsToUpdate);

    _frameRequested = false;
    _nextTop = null;
    _nextHandler = null;
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
