part of render;

/// A function that expands a template node to its replacement.
typedef View TemplateFunc(View node);

/// A function that returns true when a template needs to be re-rendered.
typedef bool ShouldRenderFunc(View before, View after);

bool _alwaysRender(before, after) => true;

typedef Widget CreateWidgetFunc();

typedef _Node _MakeNodeFunc(String path, int depth, View node);

/// A Root is a place on an HTML page where a tag tree may be rendered.
abstract class Root {
  final int id;
  final _nodeMakers = <String, _MakeNodeFunc>{};
  final _handlers = new _HandlerMap();
  _Node _renderedTree;

  bool _frameRequested = false;
  View _nextTagTree;
  final Set<_WidgetNode> _widgetsToUpdate = new Set();

  Root(this.id) {
    _nodeMakers["__TextView"] = (path, depth, node) => new _TextNode(path, depth, node);
  }

  addElements(TagSet tags) {
    for (ElementType type in tags.elementTypes) {
      addElement(type);
    }
  }

  addElement(ElementType type) {
      _nodeMakers[type.tag] = (path, depth, node) =>
          new _ElementNode(path, depth, node, type);
  }

  addTemplate(String name, TemplateFunc render, {ShouldRenderFunc shouldRender: _alwaysRender}) {
      _nodeMakers[name] = (path, depth, node) =>
          new _TemplateNode(path, depth, node, render, shouldRender);
  }

  addWidget(String name, CreateWidgetFunc createWidget) {
      _nodeMakers[name] = (path, depth, node) =>
          new _WidgetNode(path, depth, node, createWidget);
  }

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
  void mount(View nextTagTree) {
    _nextTagTree = nextTagTree;
    _requestAnimationFrame();
  }

  /// Calls any event handlers that were present in the most recently
  /// rendered tag tree.
  void dispatchEvent(HandlerEvent e) => _dispatch(e, _handlers);

  _Node _makeNode(String path, int depth, View node) {
    assert(node.checked());
    _MakeNodeFunc make = _nodeMakers[node.tag];
    if (make == null) {
      throw "no implementation found for ${node.tag}";
    }
    return make(path, depth, node);
  }

  /// Schedules a widget to be updated just before rendering the next frame.
  /// (That is, marks the Widget as "dirty".)
  void _invalidateWidget(_WidgetNode view) {
    assert(view.mounted);
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
    _Transaction tx = new _Transaction(this, dom, _handlers, _nextTagTree, _widgetsToUpdate);

    _frameRequested = false;
    _nextTagTree = null;
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

class _TextView extends View {
  get tag => "__TextView";
  final String value;
  const _TextView(this.value);
}
