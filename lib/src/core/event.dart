part of core;

typedef HandlerFunc(HandlerEvent e);

/// An event to be delivered to a handler in a tag tree.
class HandlerEvent implements Jsonable {
  final HandlerType type;

  /// The path in the rendered tree to the element that should handle this event.
  /// (It's always an element since templates and widgets have been expanded.)
  final String elementPath;

  /// The value of the event. (Should be serializable for remote handlers.)
  final value;

  HandlerEvent(this.type, this.elementPath, this.value) {
    assert(type != null);
    assert(elementPath != null);
  }

  @override
  String get jsonTag => type.name;
}

const onClick = const HandlerType(#onClick, "onClick");
const onMouseDown = const HandlerType(#onMouseDown, "onMouseDown");
const onMouseOver = const HandlerType(#onMouseOver, "onMouseOver");
const onMouseUp = const HandlerType(#onMouseUp, "onMouseUp");
const onMouseOut = const HandlerType(#onMouseOut, "onMouseOut");

const onChange = const HandlerType(#onChange, "onChange");
const onSubmit = const HandlerType(#onSubmit, "onSubmit");

/// A unique id that identifies a remote event handler.
class Handler implements Jsonable {
  final int frameId;
  final int id;

  Handler(this.frameId, this.id);

  @override
  String get jsonTag => "handler";
}

/// A call to a remote handler.
class HandlerCall implements Jsonable {
  final Handler handle;
  final HandlerEvent event;

  HandlerCall(this.handle, this.event);

  @override
  String get jsonTag => "call";
}
