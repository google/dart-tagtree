part of render;

/// Contains all the handlers for one Root.
class _HandlerMap {
  // A multimap from (handler key, path) to the handler to call.
  final _handlers = <Symbol, Map<String, HandlerFunc>> {};

  HandlerFunc getHandler(HandlerType type, String path) {
    _handlers.putIfAbsent(type.namedParam, () => {});
    return _handlers[type.namedParam][path];
  }

  void setHandler(HandlerType type, String path, HandlerFunc handler) {
    _handlers.putIfAbsent(type.namedParam, () => {});
    _handlers[type.namedParam][path] = handler;
  }

  void removeHandler(HandlerType type, String path) {
    _handlers[type.namedParam].remove(path);
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
/// On return, there may be some dirty nodes to be re-rendered.
/// Note: nodes may also change state outside any event handler;
/// for example, due to a timer.
/// TODO: bubbling. For now, just exact match.
void _dispatch(HandlerEvent e, _HandlerMap handlers) {
  if (_inViewEvent) {
    // React does this too; see EVENT_SUPPRESSION
    print("ignored ${e.type.propKey} received while processing another event");
    return;
  }
  _inViewEvent = true;
  try {
    if (e.elementPath != null) {
      HandlerFunc h = handlers.getHandler(e.type, e.elementPath);
      if (h != null) {
        debugLog("\n### ${e.type.propKey}");
        h(e);
      } else {
        debugLog("\n (${e.type.propKey})");
      }
    } else {
      debugLog("\n (${e.type.propKey})");
    }
  } finally {
    _inViewEvent = false;
  }
}