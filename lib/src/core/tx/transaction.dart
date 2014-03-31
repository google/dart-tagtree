part of core;

/// A Transaction renders one animation frame for one Root.
class Transaction extends _Update {
  final Root root;
  final NextFrame frame;
  final HandlerMap handlers;

  // What to do
  final Tag nextTop;
  final List<WidgetView> _widgetsToUpdate;

  Transaction(this.root, this.frame, this.handlers, this.nextTop, Iterable<WidgetView> widgetsToUpdate)
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
      frame.onRefMounted(r);
    }

    for (Elt form in _mountedForms) {
      frame.onFormMounted(root, form.path);
    }

    for (var w in _mountedWidgets) {
      w._didMount.add(true);
    }

    for (var w in _updatedWidgets) {
      w._didUpdate.add(true);
    }
  }

  // Returns the new top view.
  View _updateRoot(String path, View current, Tag next) {
    if (current == null) {
      StringBuffer html = new StringBuffer();
      View view = mountView(next, html, path, 0);
      frame.mount(html.toString());
      return view;
    } else {
      return updateOrReplace(current, next);
    }
  }

  // What was done

  @override
  void addHandler(Symbol key, String path, EventHandler val) {
    handlers.setHandler(key, path, val);
  }

  @override
  void setHandler(Symbol key, String path, EventHandler val) {
    handlers.setHandler(key, path, val);
  }

  @override
  void removeHandler(Symbol key, String path) {
    handlers.removeHandler(key, path);
  }

  @override
  void releaseElement(String path, {bool willReplace: false}) {
    frame.detachElement(path, willReplace: willReplace);
    handlers.removeHandlersForPath(path);
  }
}
