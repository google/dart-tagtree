part of core;

/// A synthetic, browser-independent event.
class ViewEvent implements Jsonable {

  @override
  String get jsonTag => _htmlHandlerNames[type];

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

final Map<Symbol, String> _htmlHandlerNames = {
  #onChange: "onChange",
  #onClick: "onClick",
  #onMouseDown: "onMouseDown",
  #onMouseOver: "onMouseOver",
  #onMouseUp: "onMouseUp",
  #onMouseOut: "onMouseOut",
  #onSubmit: "onSubmit"
};

/// Dispatches all events for one Root.
class HandlerMap {
  // A multimap from (handler key, path) to an event handler.
  final _handlers = <Symbol, Map<String, EventHandler>> {};

  HandlerMap() {
    for (Symbol key in _htmlHandlerNames.keys) {
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

const bool debug = false;

void debugLog(String msg) {
  if (debug) {
    print(msg);
  }
}

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
    if (e.targetPath != null) {
      EventHandler h = handlers.getHandler(e.type, e.targetPath);
      if (h != null) {
        debugLog("\n### ${e.type}");
        h(e);
      } else {
        debugLog("\n (${e.type})");
      }
    } else {
      debugLog("\n (${e.type})");
    }
  } finally {
    _inViewEvent = false;
  }
}

/// A unique id that identifies a remote event handler.
class Handle implements Jsonable {
  final int frameId;
  final int id;

  Handle(this.frameId, this.id);

  @override
  String get jsonTag => "handle";
}

class HandleCall implements Jsonable {
  final Handle handle;
  final ViewEvent event;

  HandleCall(this.handle, this.event);

  @override
  String get jsonTag => "call";
}

class _HandleRule extends JsonRule<Handle> {
  _HandleRule(): super("handle");

  @override
  bool appliesTo(Jsonable instance) => (instance is Handle);

  @override
  encode(Handle h) => [h.frameId, h.id];

  @override
  Jsonable decode(array) {
    if (array is List && array.length >= 2) {
      return new Handle(array[0], array[1]);
    } else {
      throw "can't decode Handle: ${array.runtimeType}";
    }
  }
}

class _EventRule extends JsonRule<ViewEvent> {
  final Symbol _type;

  _EventRule(Symbol type) : super(_htmlHandlerNames[type]), _type = type;

  @override
  bool appliesTo(Jsonable instance) => (instance is ViewEvent);

  @override
  encode(ViewEvent e) => e.targetPath;

  @override
  ViewEvent decode(s) {
    if (s is String) {
      return new ViewEvent(_type, s);
    } else {
      throw "can't decode ViewEvent: ${s.runtimeType}";
    }
  }
}

class _ChangeEventRule extends JsonRule<ChangeEvent> {
  _ChangeEventRule() : super("onChange");

  @override
  bool appliesTo(Jsonable instance) => (instance is ChangeEvent);

  @override
  encode(ChangeEvent e) => {
    "target": e.targetPath,
    "value": e.value,
  };

  @override
  ViewEvent decode(map) => new ChangeEvent(map["target"], map["value"]);
}

class _HandleCallRule extends JsonRule<HandleCall> {
  _HandleCallRule() : super("call");

  @override
  bool appliesTo(Jsonable instance) => (instance is HandleCall);

  @override
  encode(HandleCall call) => [call.handle.frameId, call.handle.id, call.event];

  @override
  HandleCall decode(array) {
    if (array is List && array.length >= 3) {
      return new HandleCall(new Handle(array[0], array[1]), array[2]);
    } else {
      throw "can't decode HandleCall: ${array.runtimeType}";
    }
  }
}
