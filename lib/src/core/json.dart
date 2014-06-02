part of core;

typedef void OnEventFunc(HandlerCall call);

/// Creates a codec for sending a receiving Views and HandlerCalls.
/// Each decoded Handler will be replaced with a [HandlerFunc] that calls
/// onEvent.
TaggedJsonCodec makeCodec(TagSet tags, {OnEventFunc onEvent}) {
  if (onEvent == null) {
    onEvent = (HandlerCall e) {
      print("ignored event to remote handler: ${e}");
    };
  }

  var rules = <JsonRule>[];

  for (String tag in tags.tags) {
      rules.add(new ViewRule(tag, tags.getMaker(tag)));
  }

  rules.add(new _HandlerIdRule(onEvent));
  for (var type in tags.handlerTypes) {
    rules.add(new _HandlerEventRule(type));
  }
  rules.add(new _HandlerCallRule());

  return new TaggedJsonCodec(rules, [const JsonableFinder()]);
}

class ViewRule extends JsonRule<View> {
  final ViewMakerFunc maker;

  ViewRule(String tag, this.maker) : super(tag);

  @override
  bool appliesTo(View instance) => instance is View && instance.tag == tagName;

  @override
  encode(View view) {
    assert(view.checked()); // don't send malformed Views over the network.
    var map = view.props.propsMap;
    assert(map != null);
    return map;
  }

  @override
  View decode(Map<String, dynamic> propsMap) => maker(propsMap);
}

class _HandlerIdRule extends JsonRule<HandlerId> {
  final OnEventFunc onHandlerCalled;

  _HandlerIdRule(this.onHandlerCalled): super("handler");

  @override
  bool appliesTo(instance) => (instance is HandlerId);

  @override
  encode(HandlerId h) => [h.frameId, h.id];

  @override
  decode(array) {
    if (array is List && array.length >= 2) {
      var id = new HandlerId(array[0], array[1]);
      return (HandlerEvent event) {
        onHandlerCalled(new HandlerCall(id, event));
      };
    } else {
      throw "can't decode Handler: ${array.runtimeType}";
    }
  }
}

class _HandlerEventRule extends JsonRule<HandlerEvent> {
  final HandlerType _type;

  _HandlerEventRule(HandlerType type) : _type = type, super(type.name);

  @override
  bool appliesTo(instance) => (instance is HandlerEvent);

  @override
  encode(HandlerEvent e) => [e.elementPath, e.value];

  @override
  HandlerEvent decode(array) {
    if (array is List && array.length == 2) {
      return new HandlerEvent(_type, array[0], array[1]);
    } else {
      throw "can't decode TagEvent: ${array.runtimeType}";
    }
  }
}

class _HandlerCallRule extends JsonRule<HandlerCall> {
  _HandlerCallRule() : super("call");

  @override
  bool appliesTo(Jsonable instance) => (instance is HandlerCall);

  @override
  encode(HandlerCall call) => [call.id.frameId, call.id.id, call.event];

  @override
  HandlerCall decode(array) {
    if (array is List && array.length >= 3) {
      return new HandlerCall(new HandlerId(array[0], array[1]), array[2]);
    } else {
      throw "can't decode HandleCall: ${array.runtimeType}";
    }
  }
}

