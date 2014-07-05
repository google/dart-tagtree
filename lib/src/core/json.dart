part of core;

typedef void OnRemoteEventFunc(HandlerEvent event, RemoteHandler handler);

TaggedJsonCodec _makeCodec(TagSet tags, {OnRemoteEventFunc onEvent}) {
  if (onEvent == null) {
    onEvent = (e, _) {
      print("ignored event to remote handler: ${e}");
    };
  }

  var rules = <JsonRule>[];

  for (TagMaker meta in tags.makers) {
    rules.add(new TagRule(meta));
  }

  rules.add(new _RemoteHandlerRule(onEvent));
  for (var type in tags.handlerTypes) {
    rules.add(new _HandlerEventRule(type));
  }
  rules.add(new _HandlerCallRule());
  rules.add(new _RawHtmlRule());

  return new TaggedJsonCodec(rules, [const JsonableFinder()]);
}

class TagRule extends JsonRule<Tag> {
  final TagMaker maker;

  TagRule(TagMaker meta) : this.maker = meta, super(meta.jsonTag) {
    assert(meta.canDecodeJson);
  }

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
  Tag decode(Map<String, dynamic> propsMap) => maker.fromMap(propsMap);
}

class _RemoteHandlerRule extends JsonRule<RemoteHandler> {
  final OnRemoteEventFunc onHandlerCalled;

  _RemoteHandlerRule(this.onHandlerCalled): super("handler");

  @override
  bool appliesTo(instance) => (instance is RemoteHandler);

  @override
  encode(RemoteHandler h) => [h.frameId, h.id];

  @override
  decode(array) {
    if (array is List && array.length >= 2) {
      var handler = new RemoteHandler(array[0], array[1]);
      return (HandlerEvent event) {
        onHandlerCalled(event, handler);
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

class _HandlerCallRule extends JsonRule<RemoteCallback> {
  _HandlerCallRule() : super("call");

  @override
  bool appliesTo(instance) => (instance is RemoteCallback);

  @override
  encode(RemoteCallback call) => [call.handler.frameId, call.handler.id, call.event];

  @override
  RemoteCallback decode(array) {
    if (array is List && array.length >= 3) {
      return new RemoteCallback(new RemoteHandler(array[0], array[1]), array[2]);
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
