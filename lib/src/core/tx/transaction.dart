part of core;

/// A Transaction renders one animation frame for one Root.
class Transaction extends _Update {
  final Root root;
  final DomUpdater dom;
  final _HandlerMap handlers;

  // What to do
  final Tag nextTop;
  final HandleFunc nextHandler;
  final List<WidgetView> _widgetsToUpdate;

  Transaction(this.root, this.dom, this.handlers, this.nextTop, this.nextHandler,
      Iterable<WidgetView> widgetsToUpdate)
      : _widgetsToUpdate = new List.from(widgetsToUpdate);

  WidgetEnv get widgetEnv => root;

  void run() {
    if (nextTop != null) {
      // Repace the entire tree.
      root._top = _updateRoot(root.path, root._top, nextTop);
    }

    // Sort ancestors ahead of children.
    _widgetsToUpdate.sort((a, b) => a.depth - b.depth);

    for (WidgetView w in _widgetsToUpdate) {
      updateWidget(w);
    }

    _finish();
  }

  void _finish() {
    for (Ref r in _mountedRefs) {
      dom.mountRef(r);
    }

    for (_Elt form in _mountedForms) {
      dom.mountForm(form.path);
    }

    for (var w in _mountedWidgets) {
      w._didMount.add(true);
    }

    for (var w in _updatedWidgets) {
      w._didUpdate.add(true);
    }
  }

  // Returns the new top view.
  _View _updateRoot(String path, _View current, Tag next) {
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
    handlers.setHandler(key, path, wrapHandler(val));
  }

  @override
  void setHandler(Symbol key, String path, val) {
    handlers.setHandler(key, path, wrapHandler(val));
  }

  @override
  void removeHandler(Symbol key, String path) {
    handlers.removeHandler(key, path);
  }

  @override
  void releaseElement(String path, {bool willReplace: false}) {
    dom.detachElement(path, willReplace: willReplace);
    handlers.removeHandlersForPath(path);
  }

  EventHandler wrapHandler(val) {
    if (val is EventHandler) {
      return val;
    } else if (val is Handle) {
      if (nextHandler == null) {
        throw "can't render a Handle without a handler function installed";
      }
      return (HtmlEvent e) {
        nextHandler(new HandleCall(val, e));
      };
    } else {
      throw "can't convert to event handler: ${val.runtimeType}";
    }
  }
}
