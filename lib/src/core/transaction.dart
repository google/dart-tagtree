part of core;

class Transaction {
  final Root root;
  final NextFrame frame;

  Transaction(this.root, this.frame);

  // Returns the new top view.
  View mountAtRoot(View current, View next) {
    assert(next != null);
    if (current == null) {
      StringBuffer html = new StringBuffer();
      next.mount(html, root, root.path, 0);
      frame.mount(html.toString());
      root._finishMount(next, frame);
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
      next.mount(html, root, root.path, 0);
      frame.replaceElement(html.toString());
      root._finishMount(next, frame);
      return next;
    }
  }

  void mountShadow(Widget owner, View newShadow) {
    // Set the current element first because unmount clears the node cache
    String path = owner.path;
    frame.visit(path);
    owner._shadow.unmount(frame);

    var html = new StringBuffer();
    owner._shadow.mount(html, root, path, owner.depth + 1);
    frame.replaceElement(html.toString());
    root._finishMount(newShadow, frame);
  }

  void mountNewChild(_Inner parent, View child, int childIndex) {
    var html = new StringBuffer();
    child.mount(html, root, "${parent.path}/${childIndex}", parent.depth + 1);
    frame
      ..visit(parent.path)
      ..addChildElement(html.toString());
    root._finishMount(child, frame);
  }

  void mountReplacementChild(_Inner parent, View child, int childIndex) {
    StringBuffer html = new StringBuffer();
    child.mount(html, root, "${parent.path}/${childIndex}", parent.depth + 1);
    frame
        ..visit(parent.path)
        ..replaceChildElement(childIndex, html.toString());
    root._finishMount(child, frame);
  }
}