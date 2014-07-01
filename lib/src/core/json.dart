part of core;

typedef void OnEventFunc(HandlerCall call);

TaggedJsonCodec _makeCodec(TagSet tags, {OnEventFunc onEvent}) {
  if (onEvent == null) {
    onEvent = (HandlerCall e) {
      print("ignored event to remote handler: ${e}");
    };
  }

  var rules = <JsonRule>[];

  for (String tag in tags.jsonTags) {
      rules.add(new TagRule(tag, tags.getDecoder(tag)));
  }

  rules.add(new _HandlerIdRule(onEvent));
  for (var type in tags.handlerTypes) {
    rules.add(new _HandlerEventRule(type));
  }
  rules.add(new _HandlerCallRule());
  rules.add(new _RawHtmlRule());

  return new TaggedJsonCodec(rules, [const JsonableFinder()]);
}

class TagRule extends JsonRule<Tag> {
  final TagDecodeFunc maker;

  TagRule(String tag, this.maker) : super(tag);

  @override
  bool appliesTo(Tag instance) => instance is Tag && instance.jsonTag == tagName;

  @override
  encode(Tag tag) {
    assert(tag.checked()); // don't send malformed Tags over the network.
    var map = tag.props._map;
    assert(map != null);
    return map;
  }

  @override
  Tag decode(Map<String, dynamic> propsMap) => maker(propsMap);
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

  _HandlerEventRule(HandlerType type) : _type = type, super(type.propKey);

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
  bool appliesTo(instance) => (instance is HandlerCall);

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

class _RawHtmlRule extends JsonRule<RawHtml> {
  _RawHtmlRule() : super("rawHtml");

  @override
  bool appliesTo(instance) => (instance is RawHtml);

  @override
  encode(RawHtml rh) => rh.html;

  @override
  RawHtml decode(val) {
    if (val is String) {
      return new RawHtml(val);
    } else {
      throw "can't decode RawHtml: ${val.runtimeType}";
    }
  }
}
