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
      next.mount(this, html, root.path, 0);
      frame.mount(html.toString());
      _finishMount(next, frame);
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
      _finishMount(next, frame);
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
    _finishMount(newShadow, frame);
  }

  void mountNewChild(_Inner parent, View child, int childIndex) {
    var html = new StringBuffer();
    child.mount(this, html, "${parent.path}/${childIndex}", parent.depth + 1);
    frame
      ..visit(parent.path)
      ..addChildElement(html.toString());
    _finishMount(child, frame);
  }

  void mountReplacementChild(_Inner parent, View child, int childIndex) {
    StringBuffer html = new StringBuffer();
    child.mount(this, html, "${parent.path}/${childIndex}", parent.depth + 1);
    frame
        ..visit(parent.path)
        ..replaceChildElement(childIndex, html.toString());
    _finishMount(child, frame);
  }

  final List<Ref> _mountedRefs = <Ref>[];
  final List<Elt> _mountedForms = <Elt>[];
  final List<StreamSink> _didMountStreams = <StreamSink>[];

  /// Finishes mounting a subtree after the DOM is created.
  void _finishMount(View subtree, NextFrame frame) {
    for (Ref r in _mountedRefs) {
      frame.onRefMounted(r);
    }
    _mountedRefs.clear();

    for (Elt form in _mountedForms) {
      frame.onFormMounted(root, form.path);
    }
    _mountedForms.clear();

    for (var s in _didMountStreams) {
      s.add(true);
    }
    _didMountStreams.clear();
  }
}