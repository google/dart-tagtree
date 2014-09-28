part of render;

/// A RenderRoot is a place on an HTML page where a tag tree may be rendered.
abstract class RenderRoot {
  final int id;
  final _handlers = new _HandlerMap();
  _Node _renderedTree;
  final Set<_LayoutNode> _allLayouts = new Set();

  bool _frameRequested = false;
  Tag _nextTagTree;
  final Set<_Node> _nodesToUpdate = new Set();

  RenderRoot(this.id);

  /// A subclass hook called after DOM elements are mounted and we are ready
  /// to start listening for events.
  void installEventListeners();

  /// A subclass hook that's called when the DOM needs to be rendered.
  void requestAnimationFrame(RenderFunc callback);

  /// The unique id for this Root.
  String get path => "/${id}";

  /// Sets the tag tree to be rendered on the next animation frame.
  /// (If called more than once between two frames, only the last call will
  /// have any effect.)
  void mount(Tag nextTagTree) {
    assert(nextTagTree != null);
    _nextTagTree = nextTagTree;
    _requestAnimationFrame();
  }

  /// Calls any event handlers that were present in the most recently
  /// rendered tag tree.
  void dispatchEvent(HandlerEvent e) => _dispatch(e, _handlers);

  void updateLayouts() {
    _requestLayout(_allLayouts);
  }

  /// Schedules a node to be rendered during the next frame.
  /// (That is, marks it as "dirty".)
  void _invalidate(_AnimatedNode node) {
    assert(node.isMounted);
    _nodesToUpdate.add(node);
    _requestAnimationFrame();
  }

  void _addLayouts(List<_LayoutNode> nodes) {
    _allLayouts.addAll(nodes);
  }

  void _removeLayouts(List<_LayoutNode> nodes) {
    _allLayouts.removeAll(nodes);
  }

  void _requestLayout(Iterable<_LayoutNode> nodes) {
    if (nodes.isNotEmpty) {
      _nodesToUpdate.addAll(nodes);
      _requestAnimationFrame();
    }
  }

  void _requestAnimationFrame() {
    if (!_frameRequested) {
      _frameRequested = true;
      requestAnimationFrame(_render);
    }
  }

  void _render(DomUpdater dom) {
    _Transaction tx =
        new _Transaction(this, dom, _handlers, _nextTagTree, _nodesToUpdate);

    _frameRequested = false;
    _nextTagTree = null;
    _nodesToUpdate.clear();

    bool wasEmpty = _renderedTree == null;
    tx.run();
    if (wasEmpty) {
      installEventListeners();
    }
  }
}
