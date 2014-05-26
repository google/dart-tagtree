part of core;

class NodeTagFinder implements TagFinder<TagNode> {
  const NodeTagFinder();

  @override
  bool appliesToType(instance) => instance is TagNode;

  @override
  String getTag(TagNode instance) => instance.tag.type == null ? null : instance.tag.type.name;
}

class EventTagFinder implements TagFinder<TagEvent> {
  final TagSet tags;
  const EventTagFinder(this.tags);

  @override
  bool appliesToType(instance) => instance is TagEvent;

  @override
  String getTag(TagEvent instance) => tags.getEventName(instance.propKey);
}

/// Creates a codec that can encode any HTML tags or events supported by a TagMaker.
TaggedJsonCodec makeCodec(TagSet tags) {
  var rules = <JsonRule>[];

  for (Tag tag in tags.values) {
    if (tag.type != null) {
      rules.add(new TagNodeRule(tag));
    }
  }

  rules.add(new _HandleRule());
  for (Symbol type in tags.eventTypes) {
    rules.add(new _EventRule(type, tags.getEventName(type)));
  }
  rules.add(new _HandleCallRule());

  return new TaggedJsonCodec(rules,
      [const JsonableFinder(), const NodeTagFinder(), new EventTagFinder(tags)]);
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
  encode(TagNode instance) => instance.tag.type.convertToStringKeys(instance.propMap);

  @override
  TagNode decode(Map<String, dynamic> state) {
    var props = tag.type.convertFromStringKeys(state);
    return new TagNode(tag, props);
  }
}

class _HandleRule extends JsonRule<Handle> {
  _HandleRule(): super("handle");

  @override
  bool appliesTo(Jsonable instance) => (instance is Handle);

  @override
  encode(Handle h) => [h.frameId, h.id];

  @override
  Jsonable decode(array) {
    if (array is List && array.length >= 2) {
      return new Handle(array[0], array[1]);
    } else {
      throw "can't decode Handle: ${array.runtimeType}";
    }
  }
}

class _EventRule extends JsonRule<TagEvent> {
  final Symbol _type;

  _EventRule(Symbol type, String tagName) : super(tagName), _type = type;

  @override
  bool appliesTo(instance) => (instance is TagEvent);

  @override
  encode(TagEvent e) => [e.nodePath, e.value];

  @override
  TagEvent decode(array) {
    if (array is List && array.length == 2) {
      return new TagEvent(array[0], _type, array[1]);
    } else {
      throw "can't decode TagEvent: ${array.runtimeType}";
    }
  }
}

class _HandleCallRule extends JsonRule<HandleCall> {
  _HandleCallRule() : super("call");

  @override
  bool appliesTo(Jsonable instance) => (instance is HandleCall);

  @override
  encode(HandleCall call) => [call.handle.frameId, call.handle.id, call.event];

  @override
  HandleCall decode(array) {
    if (array is List && array.length >= 3) {
      return new HandleCall(new Handle(array[0], array[1]), array[2]);
    } else {
      throw "can't decode HandleCall: ${array.runtimeType}";
    }
  }
}

