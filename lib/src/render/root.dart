part of render;

typedef void HandleFunc(HandleCall call);

/// A Root is a place on an HTML page where a tag tree may be rendered.
abstract class Root {
  final int id;
  final _handlers = new _HandlerMap();
  _View _renderedTree;

  bool _frameRequested = false;
  Tag _nextTagTree;
  HandleFunc _nextHandler;
  final Set<_Widget> _widgetsToUpdate = new Set();

  Root(this.id);

  /// A subclass hook called after DOM elements are mounted and we are ready
  /// to start listenering for events.
  void installEventListeners();

  /// A subclass hook that's called when the DOM needs to be rendered.
  void requestAnimationFrame(RenderFunc callback);

  /// The unique id for this Root.
  String get path => "/${id}";

  /// Sets the tag tree to be rendered on the next animation frame.
  /// (If called more than once between two frames, only the last call will
  /// have any effect.)
  void mount(Tag nextTagTree, {HandleFunc handler}) {
    _nextTagTree = nextTagTree;
    _nextHandler = handler;
    _requestAnimationFrame();
  }

  /// Calls any event handlers that were present in the most recently
  /// rendered tag tree.
  void dispatchEvent(HtmlEvent e) => _dispatch(e, _handlers);

  /// Schedules a widget to be updated just before rendering the next frame.
  /// (That is, marks the Widget as "dirty".)
  void _invalidateWidget(_Widget view) {
    assert(view._mounted);
    _widgetsToUpdate.add(view);
    _requestAnimationFrame();
  }

  void _requestAnimationFrame() {
    if (!_frameRequested) {
      _frameRequested = true;
      requestAnimationFrame(_render);
    }
  }

  void _render(DomUpdater dom) {
    _Transaction tx = new _Transaction(this, dom, _handlers, _nextTagTree, _nextHandler,
        _widgetsToUpdate);

    _frameRequested = false;
    _nextTagTree = null;
    _nextHandler = null;
    _widgetsToUpdate.clear();

    bool wasEmpty = _renderedTree == null;
    tx.run();
    if (wasEmpty) {
      installEventListeners();
    }

    // No widgets should be invalidated while rendering.
    assert(_widgetsToUpdate.isEmpty);
  }
}
