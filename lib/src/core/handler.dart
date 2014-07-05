part of core;

/// The type of an event handler.
/// Also, the type of a [Tag] property whose value is an event handler.
/// Also, the type of an event.
class HandlerType extends PropType {
  const HandlerType(Symbol sym, String name) : super(sym, name);

  @override
  bool checkValue(dynamic value) {
    assert(value is HandlerFunc);
    return true;
  }
}

/// A value to be delivered to an event handler.
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

/// A function that's called when an event happens.
typedef HandlerFunc(HandlerEvent e);

/// A HandlerFunc that can be converted to JSON.
class RemoteHandler implements Jsonable {
  final int frameId;
  final int id;
  HandlerFunc delegate; // not encoded

  RemoteHandler(this.frameId, this.id);

  @override
  String get jsonTag => "handler";

  // implement HandlerFunc
  call(HandlerEvent e) {
    if (delegate == null) {
      throw "delegate not set on RemoteHandler ${id}";
    }
    return delegate(e);
  }
}

/// A RemoteCallback contains an event to be delivered to a remote handler.
class RemoteCallback implements Jsonable {
  final RemoteHandler handler;
  final HandlerEvent event;

  RemoteCallback(this.handler, this.event);

  @override
  String get jsonTag => "call";
}
