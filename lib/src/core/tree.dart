part of core;

/// Callbacks to the ViewTree's environment.
abstract class TreeEnv {
  /// Requests that the given tree be re-rendered.
  void requestFrame(ViewTree tree);
}

/// A ViewTree contains state that's global to a mounted View and its descendants.
class ViewTree {
  final int id;
  final TreeEnv env;

  /// Renders the first frame of the tree. Postcondition: it is ready to receive events.
  ViewTree.mount(this.id, this.env, View root, NextFrame frame) {
    frame.currentElement = null; // root
    _mountSubtree(root, frame, "/${id}", 0);
  }

  /// Replaces frame.currentElement by mounting a View subtree.
  void _mountSubtree(View top, NextFrame frame, String path, int depth) {
    StringBuffer treeHtml = new StringBuffer();
    top.mount(treeHtml, path, depth);
    frame.replaceElement(treeHtml.toString());
    top.traverse((View v) {
      if (v is Elt) {
        frame.attachElement(this, v.path, v.tagName);
      } else if (v is Widget) {
        v._tree = this;
      }
      if (v.didMount != null) {
        v.didMount();
      }
    });
  }

  bool _inViewletEvent = false;

  /// Calls any event handlers in this tree.
  /// On return, there may be some dirty widgets to be re-rendered.
  /// Note: widgets may also change state outside any event handler;
  /// for example, due to a timer.
  /// TODO: bubbling. For now, just exact match.
  void dispatchEvent(ViewEvent e) {
    if (_inViewletEvent) {
      // React does this too; see EVENT_SUPPRESSION
      print("ignored ${e.type} received while processing another event");
      return;
    }
    _inViewletEvent = true;
    try {
      print("\n### ${e.type}");
      if (e.targetPath != null) {
        EventHandler h = _allHandlers[e.type][e.targetPath];
        if (h != null) {
          print("dispatched");
          h(e);
        }
      }
    } finally {
      _inViewletEvent = false;
    }
  }

  Set<Widget> _dirty = new Set();

  /// Re-renders the dirty widgets in this tree.
  void render(NextFrame frame) {
    List<Widget> batch = new List.from(_dirty);
    _dirty.clear();

    // Sort ancestors ahead of children.
    batch.sort((a, b) => a._depth - b._depth);
    for (Widget w in batch) {
      w.update(null, this, frame);
    }

    // No widgets should be invalidated while rendering.
    assert(_dirty.isEmpty);
  }

  void _invalidate(Widget w) {
    if (_dirty.isEmpty) {
      env.requestFrame(this);
    }
    _dirty.add(w);
  }
}