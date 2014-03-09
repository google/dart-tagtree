part of core;

/// Callbacks to the ViewTree's environment.
abstract class TreeEnv {
  /// Requests that the given tree be re-rendered.
  void requestFrame(ViewTree tree);
}

/// Something that can be added to a ViewTree's dirty queue.
abstract class _Redrawable {
  int get depth;
  void _redraw(ViewTree tree, NextFrame frame);
}

/// A ViewTree contains state that's global to a mounted View and its descendants.
class ViewTree implements _Redrawable {
  final int id;
  final TreeEnv env;
  View _root, _nextRoot;

  /// Renders the first frame of the tree. Postcondition: it is ready to receive events.
  ViewTree.mount(this.id, this.env, View root, NextFrame frame) {
    StringBuffer html = new StringBuffer();
    root.mount(html, "/${id}", 0);
    frame.mount(html.toString());
    _finishMount(root, frame);
    _root = root;
  }

  /// Schedules the root to be replaced on the next frame.
  /// (If this is called too quickly, frames will be dropped; only
  /// the View from the last call to replaceRoot will actually be mounted.)
  void replaceRoot(View nextRoot) {
    assert(_root != null);
    _nextRoot = nextRoot;
    _invalidate(this);
  }

  String get path => "/${id}";

  int get depth => 0;

  void _redraw(ViewTree tree, NextFrame frame) {
    assert(_root != null && _nextRoot != null);
    if (_root.canUpdateTo(_nextRoot)) {
      print("updating tree ${id} in place");
      _root.update(_nextRoot, this, frame);
      _nextRoot = null;
    } else {
      print("replacing tree ${id}");
      String path = _root._path;
      // Set the current element first because unmount clears the node cache
      frame.visit(path);
      _root.unmount(frame);
      _root = _nextRoot;
      _nextRoot = null;

      StringBuffer html = new StringBuffer();
      _root.mount(html, "/${id}", 0);
      frame.replaceElement(html.toString());
      _finishMount(_root, frame);
    }
  }

  /// Finishes mounting a subtree after the DOM is created.
  void _finishMount(View subtreeRoot, NextFrame frame) {
    subtreeRoot.traverse((View v) {
      if (v is Elt) {
        frame.attachElement(this, v._ref, v.path, v.tagName);
      } else if (v is Widget) {
        v._tree = this;
      }
      v.didMount();
    });
  }

  bool _inViewEvent = false;

  /// Calls any event handlers in this tree.
  /// On return, there may be some dirty widgets to be re-rendered.
  /// Note: widgets may also change state outside any event handler;
  /// for example, due to a timer.
  /// TODO: bubbling. For now, just exact match.
  void dispatchEvent(ViewEvent e) {
    if (_inViewEvent) {
      // React does this too; see EVENT_SUPPRESSION
      print("ignored ${e.type} received while processing another event");
      return;
    }
    _inViewEvent = true;
    try {
      print("\n### ${e.type}");
      if (e.targetPath != null) {
        EventHandler h = _allHandlers[e.type][e.targetPath];
        if (h != null) {
          h(e);
        }
      }
    } finally {
      _inViewEvent = false;
    }
  }

  Set<_Redrawable> _dirty = new Set();
  Set<Widget> _updated = new Set();

  /// Re-renders the dirty widgets in this tree.
  void render(NextFrame frame) {
    assert(_updated.isEmpty);
    List<_Redrawable> batch = new List.from(_dirty);
    _dirty.clear();

    // Sort ancestors ahead of children.
    batch.sort((a, b) => a.depth - b.depth);
    for (_Redrawable r in batch) {
      r._redraw(this, frame);
    }

    for (Widget w in _updated) {
      w.didUpdate();
    }
    _updated.clear();

    // No widgets should be invalidated while rendering.
    assert(_dirty.isEmpty);
  }

  void _invalidate(_Redrawable r) {
    if (_dirty.isEmpty) {
      env.requestFrame(this);
    }
    _dirty.add(r);
  }
}
