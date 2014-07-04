part of render;

/// A Transaction renders one animation frame for one Root.
class _Transaction extends _Update {
  final RenderRoot root;
  final DomUpdater dom;
  final _HandlerMap handlers;

  // What to do
  final Tag nextTagTree;
  final List<_AnimatedNode> _nodesToUpdate;

  // What was done
  final List<OnRendered> _renderCallbacks = [];

  _Transaction(this.root, this.dom, this.handlers, this.nextTagTree,
      Iterable<_AnimatedNode> nodesToUpdate)
      : _nodesToUpdate = new List.from(nodesToUpdate);

  void run() {
    if (nextTagTree != null) {
      root._renderedTree = _replaceTree(root.path, root._renderedTree, nextTagTree);
    }

    // Sort ancestors ahead of children.
    _nodesToUpdate.sort((a, b) => a.depth - b.depth);

    for (_AnimatedNode n in _nodesToUpdate) {
      if (n.isMounted) {
        // Re-render using the same Tag.
        updateOrReplace(n, n.renderedTag, n.renderedTheme, n.renderedTheme);
      }
    }

    _finish();
  }

  void _finish() {
    for (_ElementNode n in _renderedRefs) {
      dom.attachRef(n.path, n.tag.ref);
    }

    for (_ElementNode form in _mountedForms) {
      dom.mountForm(form.path);
    }

    for (OnRendered callback in _renderCallbacks) {
      callback();
    }
  }

  /// Renders a tag tree and returns the new node tree.
  _Node _replaceTree(String path, _Node current, Tag next) {
    if (current == null) {
      StringBuffer html = new StringBuffer();
      _Node node = mountTag(next, Theme.EMPTY, html, path, 0);
      dom.mount(html.toString());
      return node;
    } else {
      return updateOrReplace(current, next, Theme.EMPTY, Theme.EMPTY);
    }
  }

  @override
  _InvalidateFunc get invalidate => root._invalidate;

  // What was done

  @override
  void addRenderCallback(OnRendered r) {
    if (r != null) {
      _renderCallbacks.add(r);
    }
  }

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
