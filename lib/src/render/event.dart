part of render;

/// Contains all the handlers for one Root.
class _HandlerMap {
  // A multimap from (handler key, path) to an event handler.
  final _handlers = <Symbol, Map<String, EventHandler>> {};

  EventHandler getHandler(Symbol key, String path) {
    _handlers.putIfAbsent(key, () => {});
    return _handlers[key][path];
  }

  void setHandler(Symbol key, String path, EventHandler handler) {
    _handlers.putIfAbsent(key, () => {});
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
void _dispatch(TagEvent e, _HandlerMap handlers) {
  if (_inViewEvent) {
    // React does this too; see EVENT_SUPPRESSION
    print("ignored ${e.propKey} received while processing another event");
    return;
  }
  _inViewEvent = true;
  try {
    if (e.nodePath != null) {
      EventHandler h = handlers.getHandler(e.propKey, e.nodePath);
      if (h != null) {
        debugLog("\n### ${e.propKey}");
        h(e);
      } else {
        debugLog("\n (${e.propKey})");
      }
    } else {
      debugLog("\n (${e.propKey})");
    }
  } finally {
    _inViewEvent = false;
  }
}