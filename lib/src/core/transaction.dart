part of core;

/// A transaction that renders one animation frame for one Root.
class Transaction {
  final Root root;
  final NextFrame frame;

  // What to do
  final View nextTop;
  final List<Widget> _widgetsToUpdate;

  // What was done
  final List<Ref> _mountedRefs = <Ref>[];
  final List<Elt> _mountedForms = <Elt>[];
  final List<Widget> _mountedWidgets = <Widget>[];
  final List<Widget> _updatedWidgets = <Widget>[];

  Transaction(this.root, this.frame, this.nextTop, Iterable<Widget> widgetsToUpdate)
      : _widgetsToUpdate = new List.from(widgetsToUpdate);

  void run() {
    if (nextTop != null) {
      // Repace the entire tree.
      root._top = _mountAtRoot(root.path, root._top, nextTop);
    }

    // Sort ancestors ahead of children.
    _widgetsToUpdate.sort((a, b) => a.depth - b.depth);

    for (Widget w in _widgetsToUpdate) {
      w.update(null, this);
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
  View _mountAtRoot(String path, View current, View next) {
    if (current == null) {
      StringBuffer html = new StringBuffer();
      next.mount(this, html, path, 0);
      frame.mount(html.toString());
      return next;
    } else if (current.canUpdateTo(next)) {
      print("updating current view at ${path}");
      current.update(next, this);
      return current;
    } else {
      print("replacing current view ${path}");
      // Set the current element first because unmount clears the node cache
      frame.visit(path);
      current.unmount(frame);

      var html = new StringBuffer();
      next.mount(this, html, path, 0);
      frame.replaceElement(html.toString());
      return next;
    }
  }

  void mountShadow(Widget owner, View newShadow) {
    // Set the current element first because unmount clears the node cache
    String path = owner.path;
    frame.visit(path);
    owner._shadow.unmount(frame);

    var html = new StringBuffer();
    owner._shadow.mount(this, html, path, owner.depth + 1);
    frame.replaceElement(html.toString());
  }

  void mountNewChild(_Inner parent, View child, int childIndex) {
    var html = new StringBuffer();
    child.mount(this, html, "${parent.path}/${childIndex}", parent.depth + 1);
    frame
      ..visit(parent.path)
      ..addChildElement(html.toString());
  }

  void mountReplacementChild(_Inner parent, View child, int childIndex) {
    StringBuffer html = new StringBuffer();
    child.mount(this, html, "${parent.path}/${childIndex}", parent.depth + 1);
    frame
        ..visit(parent.path)
        ..replaceChildElement(childIndex, html.toString());
  }
}