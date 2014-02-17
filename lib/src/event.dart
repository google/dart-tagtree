part of core;

class ViewEvent {
  final Symbol handlerKey;
  final String path;
  ViewEvent(this.handlerKey, this.path);
}

class ChangeEvent extends ViewEvent {
  final value;
  ChangeEvent(String path, this.value) : super(#onChange, path);
}

typedef EventHandler(ViewEvent e);

Map<Symbol, Map<String, EventHandler>> allHandlers = {
  #onChange: {},
  #onClick: {},
  #onSubmit: {}
};

bool _inViewletEvent = false;

/// Dispatches a synthetic view event.
/// TODO: bubbling. For now, just exact match.
void dispatchEvent(ViewEvent e) {
  if (_inViewletEvent) {
    // React does this too; see EVENT_SUPPRESSION
    print("ignored ${e.handlerKey} received while processing another event");
    return;
  }
  _inViewletEvent = true;
  try {
    print("\n### ${e.handlerKey}");
    if (e.path != null) {
      EventHandler h = allHandlers[e.handlerKey][e.path];
      if (h != null) {
        print("dispatched");
        h(e);
      }
    }
  } finally {
    _inViewletEvent = false;
  }
}

Set<View> _dirtyViews = new Set();

void invalidate(View view) {
  if (_dirtyViews.isEmpty) {
    context.requestAnimationFrame(renderFrame);
  }
  _dirtyViews.add(view);
}

void renderFrame(t) {
  List<View> batch = new List.from(_dirtyViews);
  _dirtyViews.clear();

  // Sort ancestors ahead of children.
  batch.sort((a, b) => a._depth - b._depth);
  NextFrame frame = context.nextFrame();
  for (View v in batch) {
    v.update(null, frame);
  }

  // No views should be invalidated while rendering.
  assert(_dirtyViews.isEmpty);
}