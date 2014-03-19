part of core;

/// A synthetic, browser-independent event.
class ViewEvent {

  /// A symbol indicating what kind of event this is; #onChange, #onSubmit, and so on.
  /// (This is the same key used as the Element prop when creating the Element.)
  final Symbol type;

  final String targetPath;

  ViewEvent(this.type, this.targetPath) {
    assert(type != null);
    assert(targetPath != null);
  }
}

/// Indicates that the user changed the value in a form control.
/// (This event happens after every keystroke.)
class ChangeEvent extends ViewEvent {

  /// The new value in the <input> or <textarea> element.
  final value;

  ChangeEvent(String path, this.value): super(#onChange, path);
}

typedef EventHandler(ViewEvent e);

final Set<Symbol> allHandlerKeys = new Set.from([#onChange, #onClick, #onSubmit]);

/// Dispatches all events for one Root.
class HandlerMap {
  // A multimap from (handler key, path) to an event handler.
  final _handlers = <Symbol, Map<String, EventHandler>> {};

  HandlerMap() {
    for (Symbol key in allHandlerKeys) {
      _handlers[key] = {};
    }
  }

  EventHandler getHandler(Symbol key, String path) => _handlers[key][path];

  void setHandler(Symbol key, String path, EventHandler handler) {
    _handlers[key][path] = handler;
  }

  void removeHandler(Symbol key, String path) {
    _handlers[key].remove(path);
  }

  void removeHandlersForPath(String path) {
    for (Symbol key in _handlers.keys) {
      Map m = _handlers[key];
      m.remove(path);
    }
  }
}

bool _inViewEvent = false;

/// Calls any event handlers in this tree.
/// On return, there may be some dirty widgets to be re-rendered.
/// Note: widgets may also change state outside any event handler;
/// for example, due to a timer.
/// TODO: bubbling. For now, just exact match.
void dispatch(ViewEvent e, HandlerMap handlers) {
  if (_inViewEvent) {
    // React does this too; see EVENT_SUPPRESSION
    print("ignored ${e.type} received while processing another event");
    return;
  }
  _inViewEvent = true;
  try {
    print("\n### ${e.type}");
    if (e.targetPath != null) {
      EventHandler h = handlers.getHandler(e.type, e.targetPath);
      if (h != null) {
        h(e);
      }
    }
  } finally {
    _inViewEvent = false;
  }
}
