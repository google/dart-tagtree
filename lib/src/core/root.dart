part of core;

/// Callbacks to the ViewTree's environment.
abstract class TreeEnv {
  /// Requests that the given tree be re-rendered.
  void requestFrame(Root root);
}

/// A Root contains a view tree that's rendered to the DOM.
class Root {
  final int id;
  final TreeEnv env;
  View _top;

  bool _frameRequested = false;
  View _nextTop;
  final Set<Widget> _widgetsToUpdate = new Set();

  Root(this.id, this.env);

  String get path => "/${id}";

  /// Schedules the view tree to be replaced before the next rendered frame.
  /// (If called more than once within a single frame, only the last call will
  /// have any effect.)
  void requestMount(View nextTop) {
    _nextTop = nextTop;
    _requestFrame();
  }

  /// Schedules a widget to be updated before the next rendered frame.
  void requestWidgetUpdate(Widget w) {
    _widgetsToUpdate.add(w);
    _requestFrame();
  }

  void _requestFrame() {
    if (!_frameRequested) {
      _frameRequested = true;
      env.requestFrame(this);
    }
  }

  /// Performs all scheduled updates and renders an animation frame.
  ///
  /// (Called by the TreeEnv when it's time to render a frame.)
  void renderFrame(NextFrame frame) {
    Transaction tx = new Transaction(this, frame, _nextTop, _widgetsToUpdate);

    _frameRequested = false;
    _nextTop = null;
    _widgetsToUpdate.clear();

    tx.run();

    // No widgets should be invalidated while rendering.
    assert(_widgetsToUpdate.isEmpty);
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
}
