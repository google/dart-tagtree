part of viewlet;

/// A synthetic event.
abstract class Ev {
  get nativeEvent;
  get target;
  void preventDefault();
}

class DomEvent implements Ev {
  final Event nativeEvent;

  DomEvent(this.nativeEvent);

  EventTarget get target => nativeEvent.target;

  void preventDefault() {
    nativeEvent.preventDefault();
  }
}

typedef EventHandler(Ev e);

Map<Symbol, Map<String, EventHandler>> allHandlers = {
  #onChange: {},
  #onClick: {},
  #onSubmit: {}
};

/// Listens for native events and transforms them into Viewlet events.
void listenForEvents(Element container) {
  // Form events are tricky. We want an onChange event to fire every time
  // the value in a text box changes. The native 'input' event does this,
  // not 'change' which only fires after focus is lost.
  // In React, see ChangeEventPlugin.
  // TODO: support IE9.
  container.onInput.listen((Event e) => dispatchEvent(new DomEvent(e), #onChange));

  container.onClick.listen((Event e) => dispatchEvent(new DomEvent(e), #onClick));
  container.onSubmit.listen((Event e) => dispatchEvent(new DomEvent(e), #onSubmit));
}

bool _inViewletEvent = false;

/// Dispatches a synthetic viewlet event.
/// TODO: bubbling. For now, just exact match.
void dispatchEvent(Ev e, Symbol handlerKey) {
  if (_inViewletEvent) {
    // React does this too; see EVENT_SUPPRESSION
    print("ignored ${handlerKey} received while processing another event");
    return;
  }
  _inViewletEvent = true;
  try {
    print("\n### ${handlerKey}");
    var target = e.target;
    if (target is Element) {
      String id = target.dataset["path"];
      EventHandler h = allHandlers[handlerKey][id];
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
    window.animationFrame.then(renderFrame);
  }
  _dirtyViews.add(view);
}

void renderFrame(t) {
  List<View> batch = new List.from(_dirtyViews);
  _dirtyViews.clear();

  // Sort ancestors ahead of children.
  batch.sort((a, b) => a._depth - b._depth);
  NextFrame frame = new NextFrame();
  for (View v in batch) {
    v.update(null, frame);
  }

  // No views should be invalidated while rendering.
  assert(_dirtyViews.isEmpty);
}