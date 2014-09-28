part of render;

/// A Transaction renders one animation frame for one Root.
class _Transaction extends _Update {
  final RenderRoot root;
  final DomUpdater dom;
  final _HandlerMap handlers;

  // What to do
  final Tag nextTagTree;
  final List<_Node> _nodesToUpdate;

  // What was done
  final List<Function> _renderCallbacks = [];

  _Transaction(this.root, this.dom, this.handlers, this.nextTagTree,
      Iterable<_Node> nodesToUpdate)
      : _nodesToUpdate = new List.from(nodesToUpdate);

  void run() {
    if (nextTagTree != null) {
      assert(root._renderedTree == null || root._renderedTree.isMounted);
      root._renderedTree = _replaceTree(root.path, root._renderedTree, nextTagTree);
      assert(root._renderedTree.isMounted);
    }

    // Sort ancestors ahead of children.
    _nodesToUpdate.sort((a, b) => a.depth - b.depth);

    for (_Node n in _nodesToUpdate) {
      if (n.isMounted) {
        // Re-render using the same Tag.
       if (n is _AnimatedNode) {
          updateShadow(n, n.renderedTag, n.renderedTheme, n.renderedTheme);
        } else if (n is _LayoutNode) {
          updateResizeNode(n, n.innerTag, n.renderedTheme, n.renderedTheme);
        } else {
          throw "unable to update node: ${n.runtimeType}";
        }
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

    for (Function callback in _renderCallbacks) {
      callback();
    }

    root._removeLayouts(_unmountedLayouts);
    root._addLayouts(_mountedLayouts);
    root._requestLayout(_mountedLayouts);
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
  void addRenderCallback(Function callback) {
    if (callback != null) {
      _renderCallbacks.add(callback);
    }
  }

  @override
  void addHandler(String typeName, String path, val) {
    handlers.setHandler(typeName, path, val);
  }

  @override
  void setHandler(String typeName, String path, val) {
    handlers.setHandler(typeName, path, val);
  }

  @override
  void removeHandler(String typeName, String path) {
    handlers.removeHandler(typeName, path);
  }

  @override
  void releaseElement(String path, ref, {bool willReplace: false}) {
    dom.detachElement(path, ref, willReplace: willReplace);
    handlers.removeHandlersForPath(path);
  }
}
