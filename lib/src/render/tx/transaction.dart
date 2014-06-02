part of render;

/// A Transaction renders one animation frame for one Root.
class _Transaction extends _Update {
  final Root root;
  final DomUpdater dom;
  final _HandlerMap handlers;

  // What to do
  final View nextTagTree;
  final List<_WidgetNode> _widgetsToUpdate;

  _Transaction(this.root, this.dom, this.handlers, this.nextTagTree,
      Iterable<_WidgetNode> widgetsToUpdate)
      : _widgetsToUpdate = new List.from(widgetsToUpdate);

  _MakeNodeFunc get makeNode => root._makeNode;

  _InvalidateWidgetFunc get invalidateWidget => root._invalidateWidget;

  void run() {
    if (nextTagTree != null) {
      root._renderedTree = _replaceTree(root.path, root._renderedTree, nextTagTree);
    }

    // Sort ancestors ahead of children.
    _widgetsToUpdate.sort((a, b) => a.depth - b.depth);

    for (_WidgetNode v in _widgetsToUpdate) {
      updateWidget(v);
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
  }

  /// Renders a tag tree and returns the new view tree.
  _Node _replaceTree(String path, _Node current, View next) {
    if (current == null) {
      StringBuffer html = new StringBuffer();
      _Node view = mountView(next, html, path, 0);
      dom.mount(html.toString());
      return view;
    } else {
      return updateOrReplace(current, next);
    }
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
