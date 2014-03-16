part of core;

/// Something that can be added to a  dirty queue.
abstract class _Redrawable {
  int get depth;
  void _redraw(Transaction tx);
}

/// A transaction that renders one animation frame for one Root.
class Transaction {
  final Root root;
  final NextFrame frame;

  // What to do
  final List<_Redrawable> _dirty;

  // What was done
  final List<Ref> _mountedRefs = <Ref>[];
  final List<Elt> _mountedForms = <Elt>[];
  final List<Widget> _mountedWidgets = <Widget>[];
  final List<Widget> _updatedWidgets = <Widget>[];

  Transaction(this.root, this.frame, Iterable<_Redrawable> dirty)
      : _dirty = new List.from(dirty);

  void run() {
    // Sort ancestors ahead of children.
    _dirty.sort((a, b) => a.depth - b.depth);

    for (_Redrawable r in _dirty) {
      r._redraw(this);
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
  View mountAtRoot(View current, View next) {
    assert(next != null);
    if (current == null) {
      StringBuffer html = new StringBuffer();
      next.mount(this, html, root.path, 0);
      frame.mount(html.toString());
      return next;
    } else if (root._top.canUpdateTo(next)) {
      print("updating current view at ${root.path}");
      current.update(next, this);
      return current;
    } else {
      print("replacing current view ${root.path}");
      String path = current.path;
      // Set the current element first because unmount clears the node cache
      frame.visit(path);
      current.unmount(frame);

      var html = new StringBuffer();
      next.mount(this, html, root.path, 0);
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