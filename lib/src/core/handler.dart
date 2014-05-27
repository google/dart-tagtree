part of core;

/// A HandlerEvent contains a value to be delivered to a handler in a rendered tag tree.
class HandlerEvent implements Jsonable {
  final HandlerType type;

  /// The path in the rendered tag tree to the node that should handle this event.
  /// (It's always an ElementTag since templates and widgets have been expanded.)
  final String elementPath;

  /// The value to be delivered. (It should be serializable for remote handlers.)
  final value;

  HandlerEvent(this.type, this.elementPath, this.value) {
    assert(type != null);
    assert(elementPath != null);
  }

  @override
  String get jsonTag => type.name;
}

/// A HandlerFunc receives events locally (in the browser).
typedef HandlerFunc(HandlerEvent e);

/// A Handler is the unique id of a remote event handler (on the server).
class Handler implements Jsonable {
  final int frameId;
  final int id;

  Handler(this.frameId, this.id);

  @override
  String get jsonTag => "handler";
}

/// A HandlerCall contains an event being delivered to a remote event handler.
class HandlerCall implements Jsonable {
  final Handler handler;
  final HandlerEvent event;

  HandlerCall(this.handler, this.event);

  @override
  String get jsonTag => "call";
}
