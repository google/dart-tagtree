part of viewlet;

class ViewEvent {
  final Symbol handlerKey;
  final String path;
  ViewEvent(this.handlerKey, this.path);
}

class ChangeEvent extends ViewEvent {
  final value;
  ChangeEvent(String path, this.value) : super(#onChange, path);
}

String getTargetPath(Event e) {
  var target = e.target;
  if (target is Element) {
    return target.dataset["path"];
  } else {
    return null;
  }
}

typedef EventHandler(ViewEvent e);

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
  container.onInput.listen((Event e) {
    var target = e.target;
    String value;
    if (target is InputElement) {
      value = target.value;
    }
    if (target is TextAreaElement) {
      value = target.value;
    }
    dispatchEvent(new ChangeEvent(getTargetPath(e), value));
  });

  container.onClick.listen((Event e) {
      dispatchEvent(new ViewEvent(#onClick, getTargetPath(e)));
  });
  container.onSubmit.listen((Event e) {
      dispatchEvent(new ViewEvent(#onSubmit, getTargetPath(e)));
  });
}

bool _inViewletEvent = false;

/// Dispatches a synthetic viewlet event.
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