part of core;

/// A HandlerEvent contains a value to be delivered to a handler in a rendered tag tree.
class HandlerEvent implements Jsonable {
  final HandlerType type;

  /// The path in the rendered tag tree to the element node that should handle this event.
  /// (It's always an element since animated nodes have been expanded.)
  final String elementPath;

  /// The value to be delivered. (It should be serializable for remote handlers.)
  final value;

  HandlerEvent(this.type, this.elementPath, this.value) {
    assert(type != null);
    assert(elementPath != null);
  }

  @override
  String get jsonTag => type.propKey;
}

/// A HandlerFunc receives events from the render library (in the browser).
typedef HandlerFunc(HandlerEvent e);

/// A HandlerId is the unique id of a remote event handler (on the server).
class HandlerId implements Jsonable {
  final int frameId;
  final int id;

  HandlerId(this.frameId, this.id);

  @override
  String get jsonTag => "handler";
}

/// A HandlerCall contains an event to be delivered to a remote event handler.
class HandlerCall implements Jsonable {
  final HandlerId id;
  final HandlerEvent event;

  HandlerCall(this.id, this.event);

  @override
  String get jsonTag => "call";
}
