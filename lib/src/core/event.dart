part of core;

/// An event to be delivered to a handler in a tag tree.
class TagEvent {

  /// The path to the node that should handle this event.
  final String nodePath;

  /// The key of the property that should handle this event.
  final Symbol propKey;

  /// The value of the event.
  final String value;

  TagEvent(this.nodePath, this.propKey, this.value) {
    assert(nodePath != null);
    assert(propKey != null);
  }
}

typedef EventHandler(TagEvent e);

/// A unique id that identifies a remote event handler.
class Handle implements Jsonable {
  final int frameId;
  final int id;

  Handle(this.frameId, this.id);

  @override
  String get jsonTag => "handle";
}

/// A call to a remote handler.
class HandleCall implements Jsonable {
  final Handle handle;
  final TagEvent event;

  HandleCall(this.handle, this.event);

  @override
  String get jsonTag => "call";
}
