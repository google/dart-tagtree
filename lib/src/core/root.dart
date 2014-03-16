part of core;

/// Callbacks to the ViewTree's environment.
abstract class TreeEnv {
  /// Requests that the given tree be re-rendered.
  void requestFrame(Root root);
}

/// Something that can be added to a ViewTree's dirty queue.
abstract class _Redrawable {
  int get depth;
  void _redraw(Transaction tx);
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

  void _redraw(Transaction tx) {
    assert(_nextTop != null);
    View next = _nextTop;
    _nextTop = null;
    _top = tx.mountAtRoot(_top, next);
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
      frame.onFormMounted(this, form.path);
    }
    _mountedForms.clear();

    for (var s in _didMountStreams) {
      s.add(true);
    }
    _didMountStreams.clear();
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

  final Set<_Redrawable> _dirty = new Set();
  final List<StreamSink> _didUpdateStreams = <StreamSink>[];

  /// Re-renders the dirty widgets in this tree.
  void render(NextFrame frame) {
    assert(_didUpdateStreams.isEmpty);
    List<_Redrawable> batch = new List.from(_dirty);
    _dirty.clear();
    Transaction tx = new Transaction(this, frame);

    // Sort ancestors ahead of children.
    batch.sort((a, b) => a.depth - b.depth);
    for (_Redrawable r in batch) {
      r._redraw(tx);
    }

    for (var s in _didUpdateStreams) {
      s.add(true);
    }
    _didUpdateStreams.clear();

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
