part of render;

/// A Transaction renders one animation frame for one Root.
class _Transaction extends _Update {
  final RenderRoot root;
  final DomUpdater dom;
  final _HandlerMap handlers;

  // What to do
  final View nextTagTree;
  final Theme nextTheme;
  final List<_WidgetNode> _widgetsToUpdate;

  _Transaction(this.root, this.dom, this.handlers, this.nextTagTree, this.nextTheme,
      Iterable<_WidgetNode> widgetsToUpdate)
      : _widgetsToUpdate = new List.from(widgetsToUpdate);

  _InvalidateWidgetFunc get invalidateWidget => root._invalidateWidget;

  void run() {
    assert(nextTheme != null);
    if (nextTagTree != null) {
      root._renderedTree = _replaceTree(root.path, root._renderedTree, nextTagTree);
    }

    // Sort ancestors ahead of children.
    _widgetsToUpdate.sort((a, b) => a.depth - b.depth);

    for (_WidgetNode v in _widgetsToUpdate) {
      updateWidget(v, root._renderedTheme, nextTheme);
    }

    _finish();
  }

  void _finish() {
    for (_Node v in _mountedRefs) {
      dom.mountRef(v.path, v.view.ref);
    }

    for (_ElementNode form in _mountedForms) {
      dom.mountForm(form.path);
    }

    for (EventSink s in _mountedWidgets) {
      s.add(true);
    }

    for (EventSink s in _renderedWidgets) {
      s.add(true);
    }

    root._renderedTheme = nextTheme;
  }

  /// Renders a tag tree and returns the new view tree.
  _Node _replaceTree(String path, _Node current, View next) {
    if (current == null) {
      StringBuffer html = new StringBuffer();
      _Node view = mountView(next, nextTheme, html, path, 0);
      dom.mount(html.toString());
      return view;
    } else {
      return updateOrReplace(current, next, root._renderedTheme, nextTheme);
    }
  }

  Viewer createViewer(View view, Theme theme) {
    assert(view.checked());
    if (view is _TextView) {
      return null;
    } else {
      return theme.createViewer(view);
    }
  }

  _Node makeNode(String path, int depth, View view, Theme theme) {
    if (view is _TextView) {
      return new _TextNode(path, depth, view);
    }
    Viewer viewer = createViewer(view, theme);
    if (viewer is ElementType) {
      return new _ElementNode(path, depth, view);
    } else if (viewer is Template) {
      return new _TemplateNode(path, depth, view, viewer);
    } else if (viewer is Widget) {
      return new _WidgetNode(path, depth, view, viewer);
    }
    throw "unknown viewer type: ${viewer.runtimeType}";
  }

  // What was done

  @override
  void addHandler(HandlerType type, String path, val) {
    handlers.setHandler(type, path, val);
  }

  @override
  void setHandler(HandlerType type, String path, val) {
    handlers.setHandler(type, path, val);
  }

  @override
  void removeHandler(HandlerType type, String path) {
    handlers.removeHandler(type, path);
  }

  @override
  void releaseElement(String path, ref, {bool willReplace: false}) {
    dom.detachElement(path, ref, willReplace: willReplace);
    handlers.removeHandlersForPath(path);
  }
}
