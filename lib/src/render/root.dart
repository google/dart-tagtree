part of render;

/// A RenderRoot is a place on an HTML page where a tag tree may be rendered.
abstract class RenderRoot {
  final int id;
  final _handlers = new _HandlerMap();
  _Node _renderedTree;
  Theme _renderedTheme;

  bool _frameRequested = false;
  View _nextTagTree;
  Theme _nextTheme;
  final Set<_ExpandedNode> _nodesToUpdate = new Set();

  RenderRoot(this.id);

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
  void mount(View nextTagTree, [Theme nextTheme]) {
    assert(nextTagTree != null);
    if (nextTheme == null) {
      nextTheme = new Theme(const {});
    }
    _nextTagTree = nextTagTree;
    _nextTheme = nextTheme;
    _requestAnimationFrame();
  }

  /// Calls any event handlers that were present in the most recently
  /// rendered tag tree.
  void dispatchEvent(HandlerEvent e) => _dispatch(e, _handlers);

  /// Schedules a node to be rendered during the next frame.
  /// (That is, marks it as "dirty".)
  void _invalidate(_ExpandedNode node) {
    assert(node.mounted);
    _nodesToUpdate.add(node);
    _requestAnimationFrame();
  }

  void _requestAnimationFrame() {
    if (!_frameRequested) {
      _frameRequested = true;
      requestAnimationFrame(_render);
    }
  }

  void _render(DomUpdater dom) {
    if (_nextTheme == null) {
      _nextTheme = _renderedTheme;
    }
    _Transaction tx =
        new _Transaction(this, dom, _handlers, _nextTagTree, _nextTheme, _nodesToUpdate);

    _frameRequested = false;
    _nextTagTree = null;
    _nextTheme = null;
    _nodesToUpdate.clear();

    bool wasEmpty = _renderedTree == null;
    tx.run();
    if (wasEmpty) {
      installEventListeners();
    }

    // No widgets should be invalidated while rendering.
    assert(_nodesToUpdate.isEmpty);
  }
}
