part of viewlet;

typedef EventHandler(e);

Map<Symbol, Map<String, EventHandler>> allHandlers = {
  #onChange: {},
  #onClick: {},
  #onSubmit: {}
};

bool _inEvent = false;

void dispatchEvent(Event e, Symbol handlerKey) {
  if (_inEvent) {
    // React does this too; see EVENT_SUPPRESSION
    print("ignored ${handlerKey} received while processing another event");
    return;
  }
  _inEvent = true;
  try {
    print("\n### ${handlerKey}");
    var target = e.target;
    if (target is Element) {
      // TODO: bubbling. For now, just exact match.
      String id = target.dataset["path"];
      EventHandler h = allHandlers[handlerKey][id];
      if (h != null) {
        print("dispatched");
        h(e);
        applyUpdates();
      }
    }
  } finally {
    _inEvent = false;
  }
}

Set<View> _dirtyViews = new Set();

void applyUpdates() {
  List<View> batch = new List.from(_dirtyViews);
  _dirtyViews.clear();

  // Sort ancestors ahead of children.
  batch.sort((a, b) => a._depth - b._depth);
  for (View v in batch) {
    v.update(null);
  }

  // No new updates should be requested while refreshing.
  assert(_dirtyViews.isEmpty);
}