part of render;

/// A function that expands a template node to its replacement.
typedef TaggedNode TemplateFunc(TaggedNode node);

/// A function that returns true when a template needs to be re-rendered.
typedef bool ShouldRenderFunc(TaggedNode before, TaggedNode after);

typedef Widget CreateWidgetFunc();

/// A Root is a place on an HTML page where a tag tree may be rendered.
abstract class Root {
  final int id;
  final _renderers = <String, Renderer>{
    "_TextNode": new _TextNodeRenderer()
  };
  final _handlers = new _HandlerMap();
  _View _renderedTree;

  bool _frameRequested = false;
  TaggedNode _nextTagTree;
  final Set<_WidgetView> _widgetsToUpdate = new Set();

  Root(this.id);

  addTemplate(String name, TemplateFunc renderer, {ShouldRenderFunc shouldRender}) =>
      _renderers[name] = new _TemplateRenderer(renderer, shouldRender);

  addWidget(String name, CreateWidgetFunc renderer) =>
      _renderers[name] = new _WidgetRenderer(renderer);

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

abstract class Renderer {
  _View _makeView(TaggedNode node, String path, int depth);
}

class _TemplateRenderer implements Renderer {
  final TemplateFunc render;
  final ShouldRenderFunc _shouldRender;
  _TemplateRenderer(this.render, this._shouldRender);

  bool shouldRender(TaggedNode before, TaggedNode after) {
    bool out = _shouldRender == null ? true : _shouldRender(before, after);
    return out;
  }

  @override
  _View _makeView(TaggedNode node, String path, int depth) {
    return new _TemplateView(path, depth, this, node);
  }
}

class _WidgetRenderer implements Renderer {
  final CreateWidgetFunc createWidget;
  _WidgetRenderer(this.createWidget);

  @override
  _View _makeView(TaggedNode node, String path, int depth) {
    return new _WidgetView(path, depth, this, node);
  }
}

class _TextNode extends TaggedNode {
  get tag => "_TextNode";
  final String value;
  const _TextNode(this.value);
}

class _TextNodeRenderer implements Renderer {

  @override
  _View _makeView(_TextNode node, String path, int depth) {
    return new _TextView(path, depth, node);
  }
}