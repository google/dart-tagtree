part of render;

/// A Transaction renders one animation frame for one Root.
class _Transaction extends _Update {
  final Root root;
  final DomUpdater dom;
  final _HandlerMap handlers;

  // What to do
  final TagNode nextTagTree;
  final HandleFunc nextHandler;
  final List<_Widget> _widgetsToUpdate;

  _Transaction(this.root, this.dom, this.handlers, this.nextTagTree, this.nextHandler,
      Iterable<_Widget> widgetsToUpdate)
      : _widgetsToUpdate = new List.from(widgetsToUpdate);

  _InvalidateWidgetFunc get invalidateWidget => root._invalidateWidget;

  void run() {
    if (nextTagTree != null) {
      root._renderedTree = _replaceTree(root.path, root._renderedTree, nextTagTree);
    }

    // Sort ancestors ahead of children.
    _widgetsToUpdate.sort((a, b) => a.depth - b.depth);

    for (_Widget w in _widgetsToUpdate) {
      updateWidget(w);
    }

    _finish();
  }

  void _finish() {
    for (_View v in _mountedRefs) {
      dom.mountRef(v.path, v.ref);
    }

    for (_Elt form in _mountedForms) {
      dom.mountForm(form.path);
    }

    for (EventSink s in _mountedWidgets) {
      s.add(true);
    }

    for (EventSink s in _updatedWidgets) {
      s.add(true);
    }
  }

  /// Renders a tag tree and returns the new view tree.
  _View _replaceTree(String path, _View current, TagNode next) {
    if (current == null) {
      StringBuffer html = new StringBuffer();
      _View view = mountView(next, html, path, 0);
      dom.mount(html.toString());
      return view;
    } else {
      return updateOrReplace(current, next);
    }
  }

  // What was done

  @override
  void addHandler(Symbol key, String path, val) {
    handlers.setHandler(key, path, _wrapHandler(val));
  }

  @override
  void setHandler(Symbol key, String path, val) {
    handlers.setHandler(key, path, _wrapHandler(val));
  }

  @override
  void removeHandler(Symbol key, String path) {
    handlers.removeHandler(key, path);
  }

  @override
  void releaseElement(String path, ref, {bool willReplace: false}) {
    dom.detachElement(path, ref, willReplace: willReplace);
    handlers.removeHandlersForPath(path);
  }

  EventHandler _wrapHandler(val) {
    if (val is EventHandler) {
      return val;
    } else if (val is Handle) {
      if (nextHandler == null) {
        throw "can't render a Handle without a handler function installed";
      }
      return (TagEvent e) {
        nextHandler(new HandleCall(val, e));
      };
    } else {
      throw "can't convert to event handler: ${val.runtimeType}";
    }
  }
}
