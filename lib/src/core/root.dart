part of core;

/// Callbacks to the ViewTree's environment.
abstract class TreeEnv {
  /// Requests that the given tree be re-rendered.
  void requestFrame(Root root);
}

/// Something that can be added to a ViewTree's dirty queue.
abstract class _Redrawable {
  int get depth;
  void _redraw(NextFrame frame);
}

/// A Root contains state that's global to a mounted View and its descendants.
class Root implements _Redrawable {
  final int id;
  final TreeEnv env;
  View _top, _nextTop;

  Root(this.id, this.env);

  /// Schedules the view tree to be replaced during the next rendered frame.
  /// (If this is called too quickly, frames will be dropped; only
  /// the View from the last call to replaceRoot will actually be mounted.)
  void mount(View nextTop) {
    _nextTop = nextTop;
    _invalidate(this);
  }

  String get path => "/${id}";

  int get depth => 0;

  void _redraw(NextFrame frame) {
    assert(_nextTop != null);
    View next = _nextTop;
    _nextTop = null;
    if (_top == null) {
      StringBuffer html = new StringBuffer();
      next.mount(html, this, "/${id}", 0);
      _top = next;
      frame.mount(html.toString());
      _finishMount(next, frame);

    } else if (_top.canUpdateTo(next)) {
      print("updating tree ${id} in place");
      _top.update(next, this, frame);
    } else {
      print("replacing tree ${id}");
      String path = _top._path;
      // Set the current element first because unmount clears the node cache
      frame.visit(path);
      _top.unmount(frame);

      StringBuffer html = new StringBuffer();
      next.mount(html, this, "/${id}", 0);
      _top = next;
      frame.replaceElement(html.toString());
      _finishMount(_top, frame);
    }
  }

  List<StreamSink> _needDidMount = <StreamSink>[];

  /// Finishes mounting a subtree after the DOM is created.
  void _finishMount(View subtree, NextFrame frame) {
    subtree.traverse((View v) {
      if (v is Elt) {
        frame.attachElement(this, v._ref, v.path, v.tagName);
      } else if (v is Widget) {
        v._root = this;
      }
    });
    for (var s in _needDidMount) {
      s.add(true);
    }
    _needDidMount.clear();
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
  List<StreamSink> _needDidUpdate = <StreamSink>[];

  /// Re-renders the dirty widgets in this tree.
  void render(NextFrame frame) {
    assert(_needDidUpdate.isEmpty);
    List<_Redrawable> batch = new List.from(_dirty);
    _dirty.clear();

    // Sort ancestors ahead of children.
    batch.sort((a, b) => a.depth - b.depth);
    for (_Redrawable r in batch) {
      r._redraw(frame);
    }

    for (var s in _needDidUpdate) {
      s.add(true);
    }
    _needDidUpdate.clear();

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
