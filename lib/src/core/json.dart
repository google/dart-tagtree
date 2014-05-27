part of core;

/// Creates a codec for tag trees and handler calls.
TaggedJsonCodec makeCodec(TagSet tags) {
  var rules = <JsonRule>[];

  for (Tag tag in tags.values) {
    if (tag.type != null) {
      rules.add(new TagNodeRule(tag));
    }
  }

  rules.add(new _HandlerRule());
  for (var type in tags.handlerTypes) {
    rules.add(new _HandlerEventRule(type));
  }
  rules.add(new _HandlerCallRule());

  return new TaggedJsonCodec(rules, [const JsonableFinder(), const NodeTagFinder()]);
}

class NodeTagFinder implements TagFinder<TagNode> {
  const NodeTagFinder();

  @override
  bool appliesToType(instance) => instance is TagNode;

  @override
  String getTag(TagNode instance) => instance.tag.type == null ? null : instance.tag.type.name;
}

class TagNodeRule extends JsonRule<TagNode> {
  final Tag tag;

  TagNodeRule(Tag tag) :
    this.tag = tag,
    super(tag.type.name) {
  }

  @override
  bool appliesTo(TagNode instance) => instance is TagNode && instance.tag == tag;

  @override
  encode(TagNode instance) => instance.propsWithStringKeys;

  @override
  TagNode decode(Map<String, dynamic> state) {
    var props = tag.type.convertFromStringKeys(state);
    return new TagNode(tag, props);
  }
}

class _HandlerRule extends JsonRule<Handler> {
  _HandlerRule(): super("handler");

  @override
  bool appliesTo(Jsonable instance) => (instance is Handler);

  @override
  encode(Handler h) => [h.frameId, h.id];

  @override
  Jsonable decode(array) {
    if (array is List && array.length >= 2) {
      return new Handler(array[0], array[1]);
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
  encode(HandlerCall call) => [call.handler.frameId, call.handler.id, call.event];

  @override
  HandlerCall decode(array) {
    if (array is List && array.length >= 3) {
      return new HandlerCall(new Handler(array[0], array[1]), array[2]);
    } else {
      throw "can't decode HandleCall: ${array.runtimeType}";
    }
  }
}

