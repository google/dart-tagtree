part of render;

/// A function that expands a template node to its replacement.
typedef TaggedNode TemplateFunc(TaggedNode node);

/// A function that returns true when a template needs to be re-rendered.
typedef bool ShouldRenderFunc(TaggedNode before, TaggedNode after);

bool _alwaysRender(before, after) => true;

typedef Widget CreateWidgetFunc();

typedef _View _MakeViewFunc(String path, int depth, TaggedNode node);

/// A Root is a place on an HTML page where a tag tree may be rendered.
abstract class Root {
  final int id;
  final _viewMakers = <String, _MakeViewFunc>{
    "_TextNode": (path, depth, node) => new _TextView(path, depth, node)
  };
  final _handlers = new _HandlerMap();
  _View _renderedTree;

  bool _frameRequested = false;
  TaggedNode _nextTagTree;
  final Set<_WidgetView> _widgetsToUpdate = new Set();

  Root(this.id) {
    _viewMakers["_TextNode"] = (path, depth, node) => new _TextView(path, depth, node);
  }

  addElements(TagSet tags) {
    for (ElementType type in tags.elementTypes) {
      addElement(type);
    }
  }

  addElement(ElementType type) {
      _viewMakers[type.tag] = (path, depth, node) =>
          new _EltView(path, depth, node, type);
  }

  addTemplate(String name, TemplateFunc render, {ShouldRenderFunc shouldRender: _alwaysRender}) {
      _viewMakers[name] = (path, depth, node) =>
          new _TemplateView(path, depth, node, render, shouldRender);
  }

  addWidget(String name, CreateWidgetFunc createWidget) {
      _viewMakers[name] = (path, depth, node) =>
          new _WidgetView(path, depth, node, createWidget);
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
  void mount(TaggedNode nextTagTree) {
    _nextTagTree = nextTagTree;
    _requestAnimationFrame();
  }

  /// Calls any event handlers that were present in the most recently
  /// rendered tag tree.
  void dispatchEvent(HandlerEvent e) => _dispatch(e, _handlers);

  _View _makeView(String path, int depth, TaggedNode node) {
    _MakeViewFunc make = _viewMakers[node.tag];
    if (make == null) {
      throw "no implementation found for ${node.tag}";
    }
    return make(path, depth, node);
  }

  /// Schedules a widget to be updated just before rendering the next frame.
  /// (That is, marks the Widget as "dirty".)
  void _invalidateWidget(_WidgetView view) {
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

class _TextNode extends TaggedNode {
  get tag => "_TextNode";
  final String value;
  const _TextNode(this.value);
}
