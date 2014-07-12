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

  JsonType get eventType {
    if (_eventType[this] == null) {

      toJson(HandlerEvent e) => [e.elementPath, e.value];

      HandlerEvent fromJson(array) {
        if (array is List && array.length == 2) {
          return new HandlerEvent(this, array[0], array[1]);
        } else {
          throw "can't decode TagEvent: ${array.runtimeType}";
        }
      }

      _eventType[this] = new JsonType(propKey, toJson, fromJson);
    }
    return _eventType[this];
  }

  static var _eventType = new Expando<JsonType>();
}

/// A value to be delivered to an event handler.
class HandlerEvent extends Jsonable {
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
  get jsonType => type.eventType;
}

/// A function that's called when an event happens.
typedef HandlerFunc(HandlerEvent e);

/// A HandlerFunc that can be converted to JSON.
class RemoteHandler extends Jsonable {
  final int frameId;
  final int id;
  HandlerFunc delegate; // not encoded

  RemoteHandler(this.frameId, this.id);

  // implement HandlerFunc
  call(HandlerEvent e) {
    if (delegate == null) {
      throw "delegate not set on RemoteHandler ${id}";
    }
    return delegate(e);
  }

  @override
  get jsonType => $jsonType;

  static const $jsonType = const _RemoteHandlerType();
}

class _RemoteHandlerType implements JsonType {
  const _RemoteHandlerType();

  @override
  String get tagName => "handler";

  @override
  bool appliesTo(instance) => instance is RemoteHandler;

  @override
  encode(RemoteHandler h) => [h.frameId, h.id];

  @override
  decode(array, OnRemoteHandlerEvent context) {
    if (array is List && array.length >= 2) {
      var handler = new RemoteHandler(array[0], array[1]);
      return (HandlerEvent event) {
        context(event, handler);
      };
    } else {
      throw "can't decode Handler: ${array.runtimeType}";
    }
  }
}

/// A RemoteCallback contains an event to be delivered to a remote handler.
class RemoteCallback extends Jsonable {
  final RemoteHandler handler;
  final HandlerEvent event;

  RemoteCallback(this.handler, this.event);

  @override
  get jsonType => $jsonType;

  static const $jsonType = const JsonType("call", toJson, fromJson);

  static toJson(RemoteCallback call) => [call.handler.frameId, call.handler.id, call.event];

  static fromJson(array) {
    if (array is List && array.length >= 3) {
      return new RemoteCallback(new RemoteHandler(array[0], array[1]), array[2]);
    } else {
      throw "can't decode HandleCall: ${array.runtimeType}";
    }
  }
}
