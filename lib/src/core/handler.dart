part of core;

/// The type of an event handler.
/// Also, the type of a [Tag] property whose value is an event handler.
/// Also, the type of an event.
class HandlerType extends PropType {
  const HandlerType(Symbol sym, String name) : super(sym, name);

  @override
  bool checkValue(dynamic value) {
    assert(value == null || value is Function || value is RemoteFunction);
    return true;
  }
}

class MousePosition extends Jsonable {
  final num x;
  final num y;
  MousePosition(this.x, this.y);

  @override
  checked() {
    assert(x != null && y != null);
    return true;
  }

  @override
  get jsonType => $jsonType;

  static const $jsonType = const JsonType("mousePosition", toJson, fromJson);

  static toJson(MousePosition pos) => [pos.x, pos.y];

  static fromJson(array) {
    assert(array.length == 2);
    return new MousePosition(array[0], array[1]);
  }
}

/// A value to be delivered to an event handler.
class HandlerEvent extends Jsonable {
  final String typeName;

  /// The path in the rendered tag tree to the element node that should handle this event.
  /// (It's always an element since animated nodes have been expanded.)
  final String elementPath;

  /// The value to be delivered. (It should be serializable for remote handlers.)
  final value;

  HandlerEvent(HandlerType type, String elementPath, value) :
    this._raw(type.propKey, elementPath, value);

  HandlerEvent._raw(this.typeName, this.elementPath, this.value) {
    assert(typeName != null);
    assert(elementPath != null);
  }

  @override
  get jsonType => $jsonType;

  static const $jsonType = const JsonType("event", toJson, fromJson);

  static toJson(HandlerEvent event) => [event.typeName, event.elementPath, event.value];

  static fromJson(array) {
    assert(array.length == 3);
    return new HandlerEvent._raw(array[0], array[1], array[2]);
  }
}
